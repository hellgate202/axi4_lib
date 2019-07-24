module axi4_stream_pkt_split #(
  parameter int DATA_WIDTH     = 32,
  parameter int ID_WIDTH       = 1,
  parameter int DEST_WIDTH     = 1,
  parameter int USER_WIDTH     = 1,
  parameter int MAX_PKT_SIZE_B = 2048,
  parameter int PKT_SIZE_WIDTH = $clog2( MAX_PKT_SIZE_B )
)(
  input                      clk_i,
  input                      rst_i,
  input [PKT_SIZE_WIDTH : 0] max_pkt_size_i,
  axi4_stream_if             pkt_i,
  axi4_stream_if             pkt_o
);

localparam int DATA_WIDTH_B   = DATA_WIDTH / 8;
localparam int BYTE_CNT_WIDTH = $clog2( DATA_WIDTH_B );

logic [1 : 0][DATA_WIDTH - 1 : 0]   data_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] tstrb_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] tkeep_buf;
logic                               buf_valid;
logic [ID_WIDTH - 1 : 0]            tid_buf;
logic [DEST_WIDTH - 1 : 0]          tdest_buf;
logic [USER_WIDTH - 1 : 0]          tuser_buf;
logic [1 : 0][DATA_WIDTH - 1 : 0]   shifted_data_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] shifted_tstrb_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] shifted_tkeep_buf;
logic [BYTE_CNT_WIDTH : 0]          buf_shift;
logic [PKT_SIZE_WIDTH - 1 : 0]      rx_pkt_byte_cnt, rx_pkt_byte_cnt_comb;
logic [PKT_SIZE_WIDTH - 1 : 0]      tx_pkt_avail_bytes, tx_pkt_avail_bytes_comb;
logic [BYTE_CNT_WIDTH : 0]          unsent_bytes, unsent_bytes_comb;
logic [PKT_SIZE_WIDTH - 1 : 0]      int_bytes_left;
logic                               backpressure;
logic [BYTE_CNT_WIDTH : 0]          usual_bytes_tlast;
logic [BYTE_CNT_WIDTH : 0]          int_bytes_tlast;
logic                               tlast_during_int;
logic [BYTE_CNT_WIDTH : 0]          rx_valid_bytes;
logic [BYTE_CNT_WIDTH : 0]          tx_valid_bytes;
logic                               last_transfer;
logic                               tlast_lock;
logic                               tfirst;
logic [DATA_WIDTH_B - 1 : 0]        tstrb_masked_usual;
logic [DATA_WIDTH_B - 1 : 0]        tstrb_masked_int;
logic [DATA_WIDTH_B - 1 : 0]        tkeep_masked_usual;
logic [DATA_WIDTH_B - 1 : 0]        tkeep_masked_int;

enum logic [2 : 0] { IDLE_S,
                     ACC_S,
                     INC_UNSENT_S,
                     DEC_UNSENT_S,
                     PKT_I_TLAST_S } state, next_state;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    state <= IDLE_S;
  else
    state <= next_state;

always_comb
  begin
    next_state = state;
    case( state )
      IDLE_S:
        begin
          if( pkt_i.tvalid && pkt_o.tready )
            if( pkt_i.tlast )
              next_state = PKT_I_TLAST_S;
            else
              if( max_pkt_size_i <= DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
                next_state = INC_UNSENT_S;
              else
                next_state = ACC_S;
        end
      ACC_S:
        begin
          if( pkt_i.tvalid && pkt_o.tready )
            if( pkt_i.tlast )
              next_state = PKT_I_TLAST_S;
            else
              if( ( rx_pkt_byte_cnt + unsent_bytes ) >= max_pkt_size_i )
                next_state = DEC_UNSENT_S;
              else
                if( ( rx_pkt_byte_cnt + DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] ) >= max_pkt_size_i )
                  next_state = INC_UNSENT_S;
        end
      INC_UNSENT_S:
        begin
          if( pkt_i.tvalid && pkt_o.tready )
            if( unsent_bytes > max_pkt_size_i[BYTE_CNT_WIDTH : 0] )
              next_state = DEC_UNSENT_S;
            else
              if( pkt_i.tlast )
                next_state = PKT_I_TLAST_S;
              else
                if( max_pkt_size_i > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
                  next_state = ACC_S;
        end
      DEC_UNSENT_S:
        begin
          if( pkt_i.tvalid && pkt_o.tready )
            if( max_pkt_size_i > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
              next_state = ACC_S;
            else
              if( unsent_bytes <= max_pkt_size_i[BYTE_CNT_WIDTH : 0] )
                if( pkt_i.tlast )
                  next_state = PKT_I_TLAST_S;
                else
                  next_state = INC_UNSENT_S;
        end
      PKT_I_TLAST_S:
        begin
          if( last_transfer && pkt_o.tready )
            next_state = IDLE_S;
        end
    endcase
  end

assign usual_bytes_tlast = max_pkt_size_i[BYTE_CNT_WIDTH - 1 : 0] ?
                           {1'b0, max_pkt_size_i[BYTE_CNT_WIDTH - 1 : 0]} :
                           DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
assign int_bytes_tlast   = int_bytes_left[BYTE_CNT_WIDTH - 1 : 0] ?
                           {1'b0, int_bytes_left[BYTE_CNT_WIDTH - 1 : 0]} :
                           DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];

always_comb
  begin
    rx_valid_bytes = '0;
    for( int i = 0; i < DATA_WIDTH_B; i++ )
      if( pkt_i.tstrb[i] || pkt_i.tkeep[i] )
        rx_valid_bytes = rx_valid_bytes + 1'b1;
  end

always_comb
  begin
    tx_valid_bytes = '0;
    for( int i = 0; i < DATA_WIDTH_B; i++ )
      if( pkt_o.tstrb[i] || pkt_o.tkeep[i] )
        tx_valid_bytes = tx_valid_bytes + 1'b1;
  end

assign tlast_during_int = tx_pkt_avail_bytes <= DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
assign last_transfer    = int_bytes_left <= tx_pkt_avail_bytes && 
                          int_bytes_left <= DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    unsent_bytes <= '0;
  else
    unsent_bytes <= unsent_bytes_comb;

always_comb
  begin
    unsent_bytes_comb = unsent_bytes;
    if( pkt_o.tready )
      if( state == ACC_S && ( rx_pkt_byte_cnt + unsent_bytes ) >= max_pkt_size_i &&
          pkt_i.tvalid && !pkt_i.tlast )
        unsent_bytes_comb = unsent_bytes - DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
      else
        if( state == DEC_UNSENT_S )
          if( unsent_bytes > max_pkt_size_i[BYTE_CNT_WIDTH : 0] &&
              max_pkt_size_i <= DATA_WIDTH_B[BYTE_CNT_WIDTH] )
            unsent_bytes_comb = unsent_bytes - max_pkt_size_i[BYTE_CNT_WIDTH : 0];
          else
            unsent_bytes_comb = unsent_bytes + DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] - usual_bytes_tlast;
        else
          if( state == INC_UNSENT_S && pkt_i.tvalid )
            if( unsent_bytes > max_pkt_size_i[BYTE_CNT_WIDTH : 0] )
              if( max_pkt_size_i > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
                unsent_bytes_comb = unsent_bytes - DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
              else
                unsent_bytes_comb = unsent_bytes - max_pkt_size_i[BYTE_CNT_WIDTH : 0];
            else
              unsent_bytes_comb = unsent_bytes + DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] - usual_bytes_tlast;
          else
            if( state == PKT_I_TLAST_S )
              if( tx_pkt_avail_bytes > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
                if( int_bytes_left > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
                  unsent_bytes_comb = unsent_bytes - DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
                else
                  unsent_bytes_comb = '0;
              else
                if( tx_pkt_avail_bytes < int_bytes_left )
                  unsent_bytes_comb = unsent_bytes - tx_pkt_avail_bytes[BYTE_CNT_WIDTH : 0];
                else
                  unsent_bytes_comb = '0;
  end

assign buf_shift         = DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] - unsent_bytes;
assign shifted_data_buf  = data_buf >>  ( buf_shift * 8 );
assign shifted_tstrb_buf = tstrb_buf >> buf_shift;
assign shifted_tkeep_buf = tkeep_buf >> buf_shift;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      data_buf  <= '0;
      tkeep_buf <= '0;
      tstrb_buf <= '0;
      tid_buf   <= '0;
      tdest_buf <= '0;
      tuser_buf <= '0;
    end
  else
    if( pkt_i.tready && pkt_i.tvalid )
      begin
        data_buf[1]  <= pkt_i.tdata;
        data_buf[0]  <= data_buf[1];
        tkeep_buf[1] <= pkt_i.tkeep;
        tkeep_buf[0] <= tkeep_buf[1];
        tstrb_buf[1] <= pkt_i.tstrb;
        tstrb_buf[0] <= tstrb_buf[1];
        tid_buf      <= pkt_i.tid;
        tdest_buf    <= pkt_i.tdest;
        tuser_buf    <= pkt_i.tuser;
      end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    buf_valid <= '0;
  else
    if( pkt_i.tready )
      buf_valid <= pkt_i.tvalid;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    tlast_lock <= 'd1;
  else
    if( pkt_i.tvalid && pkt_i.tready ) 
      if( pkt_i.tlast )
        tlast_lock <= 1'b1;
      else
        tlast_lock <= 1'b0;

assign tfirst = tlast_lock && pkt_i.tvalid;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    int_bytes_left <= '0;
  else
    if( pkt_i.tvalid && pkt_o.tready && pkt_i.tlast )
      if( state == ACC_S || state == IDLE_S )
        int_bytes_left <= unsent_bytes + rx_valid_bytes;
      else
        int_bytes_left <= unsent_bytes + DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] - usual_bytes_tlast + rx_valid_bytes;
    else
      if( tx_pkt_avail_bytes > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
        if( int_bytes_left > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
          int_bytes_left <= int_bytes_left - DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
        else
          int_bytes_left <= '0;
      else
        if( tx_pkt_avail_bytes < int_bytes_left )
          int_bytes_left <= int_bytes_left - tx_pkt_avail_bytes;
        else
          int_bytes_left <= '0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    rx_pkt_byte_cnt <= '0;
  else
    rx_pkt_byte_cnt <= rx_pkt_byte_cnt_comb;

always_comb
  begin
    rx_pkt_byte_cnt_comb = rx_pkt_byte_cnt;
    if( pkt_i.tvalid && pkt_i.tready )
      if( tfirst || state == INC_UNSENT_S || state == DEC_UNSENT_S )
        if( pkt_i.tlast )
          rx_pkt_byte_cnt_comb = rx_valid_bytes;
        else
          rx_pkt_byte_cnt_comb = DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
      else
        if( pkt_i.tlast )
          rx_pkt_byte_cnt_comb = rx_pkt_byte_cnt + rx_valid_bytes;
        else
          rx_pkt_byte_cnt_comb = rx_pkt_byte_cnt + DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
  end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    tx_pkt_avail_bytes <= '0;
  else
    tx_pkt_avail_bytes <= tx_pkt_avail_bytes_comb;

always_comb
  begin
    tx_pkt_avail_bytes_comb = tx_pkt_avail_bytes;
    if( state == IDLE_S )
      tx_pkt_avail_bytes_comb = max_pkt_size_i;
    else
      if( pkt_o.tvalid && pkt_o.tready )
        if( pkt_o.tlast )
          tx_pkt_avail_bytes_comb = max_pkt_size_i;
        else
          tx_pkt_avail_bytes_comb = tx_pkt_avail_bytes - tx_valid_bytes;
  end

always_comb
  begin
    tstrb_masked_usual = '0;
    for( int i = 0; i < DATA_WIDTH_B; i++ )
      if( i < usual_bytes_tlast )
        tstrb_masked_usual[i] = shifted_tstrb_buf[0][i];
      else
        tstrb_masked_usual[i] = 1'b0;
  end

always_comb
  begin
    tstrb_masked_int = '0;
    for( int i = 0; i < DATA_WIDTH_B; i++ )
      if( i < int_bytes_tlast )
        tstrb_masked_int[i] = shifted_tstrb_buf[0][i];
      else
        tstrb_masked_int[i] = 1'b0;
  end

always_comb
  begin
    tkeep_masked_usual = '0;
    for( int i = 0; i < DATA_WIDTH_B; i++ )
      if( i < usual_bytes_tlast )
        tkeep_masked_usual[i] = shifted_tkeep_buf[0][i];
      else
        tkeep_masked_usual[i] = 1'b0;
  end

always_comb
  begin
    tkeep_masked_int = '0;
    for( int i = 0; i < DATA_WIDTH_B; i++ )
      if( i < int_bytes_tlast )
        tkeep_masked_int[i] = shifted_tstrb_buf[0][i];
      else
        tkeep_masked_int[i] = 1'b0;
  end

assign backpressure = state == ACC_S && ( rx_pkt_byte_cnt + unsent_bytes ) >= max_pkt_size_i && !pkt_i.tlast && pkt_i.tvalid ||
                      state == INC_UNSENT_S && unsent_bytes > max_pkt_size_i[BYTE_CNT_WIDTH : 0] && pkt_i.tvalid ||
                      state == DEC_UNSENT_S && unsent_bytes > max_pkt_size_i[BYTE_CNT_WIDTH : 0] && max_pkt_size_i <= DATA_WIDTH_B[PKT_SIZE_WIDTH - 1 : 0] ||
                      state == PKT_I_TLAST_S;

assign pkt_i.tready = backpressure ? 1'b0 : pkt_o.tready;
assign pkt_o.tdata  = shifted_data_buf[0];
assign pkt_o.tvalid = ( state == ACC_S || state == INC_UNSENT_S ) && buf_valid ||
                      state == DEC_UNSENT_S || state == PKT_I_TLAST_S;
assign pkt_o.tlast  = state == DEC_UNSENT_S || state == INC_UNSENT_S ||
                      state == PKT_I_TLAST_S && ( tlast_during_int || last_transfer );
assign pkt_o.tkeep  = state == PKT_I_TLAST_S && last_transfer ? tkeep_masked_int :
                      state == DEC_UNSENT_S || state == INC_UNSENT_S || state == PKT_I_TLAST_S && tlast_during_int ? tkeep_masked_usual : shifted_tkeep_buf[0];
assign pkt_o.tstrb  = state == PKT_I_TLAST_S && last_transfer ? tstrb_masked_int :
                      state == DEC_UNSENT_S || state == INC_UNSENT_S || state == PKT_I_TLAST_S && tlast_during_int ? tstrb_masked_usual : shifted_tstrb_buf[0];
assign pkt_o.tid    = tid_buf;
assign pkt_o.tdest  = tdest_buf;
assign pkt_o.tuser  = tuser_buf;

endmodule
