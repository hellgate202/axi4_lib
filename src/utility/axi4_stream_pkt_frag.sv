module axi4_stream_pkt_frag #(
  parameter int DATA_WIDTH     = 32,
  parameter int ID_WIDTH       = 1,
  parameter int DEST_WIDTH     = 1,
  parameter int USER_WIDTH     = 1,
  parameter int MAX_PKT_SIZE_B = 2048,
  parameter int PKT_SIZE_WIDTH = $clog2( MAX_PKT_SIZE_B )
)(
  input                      clk_i,
  input                      rst_i,
  input [PKT_SIZE_WIDTH : 0] max_frag_size_i,
  axi4_stream_if             pkt_i,
  axi4_stream_if             pkt_o
);

localparam int DATA_WIDTH_B   = DATA_WIDTH / 8;
localparam int BYTE_CNT_WIDTH = $clog2( DATA_WIDTH_B );

// Shifting buffers
logic [1 : 0][DATA_WIDTH - 1 : 0]     data_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0]   tstrb_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0]   tkeep_buf;
logic                                 buf_valid;
logic [1 : 0][DATA_WIDTH - 1 : 0]     shifted_data_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0]   shifted_tstrb_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0]   shifted_tkeep_buf;
logic        [BYTE_CNT_WIDTH : 0]     buf_shift;
// Passthrough buffers
logic        [ID_WIDTH - 1 : 0]       tid_buf;
logic        [DEST_WIDTH - 1 : 0]     tdest_buf;
logic        [USER_WIDTH - 1 : 0]     tuser_buf;
// How many bytes did we received in incoming packet
logic        [PKT_SIZE_WIDTH - 1 : 0] rx_pkt_byte_cnt;
// How many bytes we can send in current fragment
logic        [PKT_SIZE_WIDTH - 1 : 0] frag_avail_bytes;
// How many bytes we didn't send from packet at fragment's end
logic        [BYTE_CNT_WIDTH : 0]     unsent_bytes;
// How mant bytes of incoming packet left to send
logic        [PKT_SIZE_WIDTH - 1 : 0] pkt_bytes_left;
logic                                 backpressure;
// Usual amount of valid bytes the last word of fragment
logic        [BYTE_CNT_WIDTH : 0]     val_bytes_eof;
// Amount of valid bytes in the last word of the last fragment
logic        [BYTE_CNT_WIDTH : 0]     last_frag_val_bytes_eof;
// End of fragment during end of incoming packet
logic                                 eof_during_eop;
// End of the last fragment
logic                                 last_frag_eof;
// Valid bytes in current incoming word
logic        [BYTE_CNT_WIDTH : 0]     rx_valid_bytes;
// Valid bytes in current outcoming word
logic        [BYTE_CNT_WIDTH : 0]     tx_valid_bytes;
// Start of packet logic
logic                                 tlast_lock;
logic                                 tfirst;
// Masked fragmented tlast
logic        [DATA_WIDTH_B - 1 : 0]   tstrb_eof;
logic        [DATA_WIDTH_B - 1 : 0]   tstrb_last_frag_eof;
logic        [DATA_WIDTH_B - 1 : 0]   tkeep_eof;
logic        [DATA_WIDTH_B - 1 : 0]   tkeep_last_frag_eof;

enum logic [2 : 0] { IDLE_S,
                     PASSTHROUGH_S,
                     FRAG_FROM_INPUT_S,
                     FRAG_FROM_UNSENT_S,
                     EOP_S              } state, next_state;

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
              next_state = EOP_S;
            else
              if( max_frag_size_i <= DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
                next_state = FRAG_FROM_INPUT_S;
              else
                next_state = PASSTHROUGH_S;
        end
      PASSTHROUGH_S:
        begin
          if( pkt_i.tvalid && pkt_o.tready )
            if( pkt_i.tlast )
              next_state = EOP_S;
            else
              if( ( rx_pkt_byte_cnt + unsent_bytes ) >= max_frag_size_i )
                next_state = FRAG_FROM_UNSENT_S;
              else
                if( ( rx_pkt_byte_cnt + DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] ) >= max_frag_size_i )
                  next_state = FRAG_FROM_INPUT_S;
        end
      FRAG_FROM_INPUT_S:
        begin
          if( pkt_i.tvalid && pkt_o.tready )
            if( unsent_bytes > max_frag_size_i[BYTE_CNT_WIDTH : 0] )
              next_state = FRAG_FROM_UNSENT_S;
            else
              if( pkt_i.tlast )
                next_state = EOP_S;
              else
                if( max_frag_size_i > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
                  next_state = PASSTHROUGH_S;
        end
      FRAG_FROM_UNSENT_S:
        begin
          if( pkt_i.tvalid && pkt_o.tready )
            if( max_frag_size_i > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
              next_state = PASSTHROUGH_S;
            else
              if( unsent_bytes <= max_frag_size_i[BYTE_CNT_WIDTH : 0] )
                if( pkt_i.tlast )
                  next_state = EOP_S;
                else
                  next_state = FRAG_FROM_INPUT_S;
        end
      EOP_S:
        begin
          if( last_frag_eof && pkt_o.tready )
            next_state = IDLE_S;
        end
    endcase
  end

assign val_bytes_eof           = max_frag_size_i[BYTE_CNT_WIDTH - 1 : 0] ?
                                 {1'b0, max_frag_size_i[BYTE_CNT_WIDTH - 1 : 0]} :
                                 DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
assign last_frag_val_bytes_eof = pkt_bytes_left[BYTE_CNT_WIDTH - 1 : 0] ?
                                 {1'b0, pkt_bytes_left[BYTE_CNT_WIDTH - 1 : 0]} :
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

assign eof_during_eop = frag_avail_bytes <= DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
assign last_frag_eof  = pkt_bytes_left <= frag_avail_bytes && 
                        pkt_bytes_left <= DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    unsent_bytes <= '0;
  else
    if( pkt_o.tready )
      if( state == PASSTHROUGH_S && ( rx_pkt_byte_cnt + unsent_bytes ) >= max_frag_size_i &&
          pkt_i.tvalid && !pkt_i.tlast )
        unsent_bytes <= unsent_bytes - DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
      else
        if( state == FRAG_FROM_UNSENT_S )
          if( unsent_bytes > max_frag_size_i[BYTE_CNT_WIDTH : 0] &&
              max_frag_size_i <= DATA_WIDTH_B[BYTE_CNT_WIDTH] )
            unsent_bytes <= unsent_bytes - max_frag_size_i[BYTE_CNT_WIDTH : 0];
          else
            unsent_bytes <= unsent_bytes + DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] - val_bytes_eof;
        else
          if( state == FRAG_FROM_INPUT_S && pkt_i.tvalid )
            if( unsent_bytes > max_frag_size_i[BYTE_CNT_WIDTH : 0] )
              if( max_frag_size_i > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
                unsent_bytes <= unsent_bytes - DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
              else
                unsent_bytes <= unsent_bytes - max_frag_size_i[BYTE_CNT_WIDTH : 0];
            else
              unsent_bytes <= unsent_bytes + DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] - val_bytes_eof;
          else
            if( state == EOP_S )
              if( frag_avail_bytes > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
                if( pkt_bytes_left > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
                  unsent_bytes <= unsent_bytes - DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
                else
                  unsent_bytes <= '0;
              else
                if( frag_avail_bytes < pkt_bytes_left )
                  unsent_bytes <= unsent_bytes - frag_avail_bytes[BYTE_CNT_WIDTH : 0];
                else
                  unsent_bytes <= '0;

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
    pkt_bytes_left <= '0;
  else
    if( pkt_i.tvalid && pkt_i.tready && pkt_i.tlast )
      if( state == PASSTHROUGH_S || state == IDLE_S )
        pkt_bytes_left <= unsent_bytes + rx_valid_bytes;
      else
        pkt_bytes_left <= unsent_bytes + DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] - val_bytes_eof + rx_valid_bytes;
    else
      if( pkt_o.tready )
        if( frag_avail_bytes > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
          if( pkt_bytes_left > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
            pkt_bytes_left <= pkt_bytes_left - DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
          else
            pkt_bytes_left <= '0;
        else
          if( frag_avail_bytes < pkt_bytes_left )
            pkt_bytes_left <= pkt_bytes_left - frag_avail_bytes;
          else
            pkt_bytes_left <= '0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    rx_pkt_byte_cnt <= '0;
  else
    if( pkt_i.tvalid && pkt_i.tready )
      if( tfirst || state == FRAG_FROM_INPUT_S || state == FRAG_FROM_UNSENT_S )
        if( pkt_i.tlast )
          rx_pkt_byte_cnt <= rx_valid_bytes;
        else
          rx_pkt_byte_cnt <= DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];
      else
        if( pkt_i.tlast )
          rx_pkt_byte_cnt <= rx_pkt_byte_cnt + rx_valid_bytes;
        else
          rx_pkt_byte_cnt <= rx_pkt_byte_cnt + DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    frag_avail_bytes <= '0;
  else
    if( state == IDLE_S )
      frag_avail_bytes <= max_frag_size_i;
    else
      if( pkt_o.tvalid && pkt_o.tready )
        if( pkt_o.tlast )
          frag_avail_bytes <= max_frag_size_i;
        else
          frag_avail_bytes <= frag_avail_bytes - DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];

always_comb
  begin
    tstrb_eof = '0;
    for( int i = 0; i < DATA_WIDTH_B; i++ )
      if( i < val_bytes_eof )
        tstrb_eof[i] = shifted_tstrb_buf[0][i];
      else
        tstrb_eof[i] = 1'b0;
  end

always_comb
  begin
    tstrb_last_frag_eof = '0;
    for( int i = 0; i < DATA_WIDTH_B; i++ )
      if( i < last_frag_val_bytes_eof )
        tstrb_last_frag_eof[i] = shifted_tstrb_buf[0][i];
      else
        tstrb_last_frag_eof[i] = 1'b0;
  end

always_comb
  begin
    tkeep_eof = '0;
    for( int i = 0; i < DATA_WIDTH_B; i++ )
      if( i < val_bytes_eof )
        tkeep_eof[i] = shifted_tkeep_buf[0][i];
      else
        tkeep_eof[i] = 1'b0;
  end

always_comb
  begin
    tkeep_last_frag_eof = '0;
    for( int i = 0; i < DATA_WIDTH_B; i++ )
      if( i < last_frag_val_bytes_eof )
        tkeep_last_frag_eof[i] = shifted_tstrb_buf[0][i];
      else
        tkeep_last_frag_eof[i] = 1'b0;
  end

assign backpressure = state == PASSTHROUGH_S && ( rx_pkt_byte_cnt + unsent_bytes ) >= max_frag_size_i && !pkt_i.tlast && pkt_i.tvalid ||
                      state == FRAG_FROM_INPUT_S && unsent_bytes > max_frag_size_i[BYTE_CNT_WIDTH : 0] && pkt_i.tvalid ||
                      state == FRAG_FROM_UNSENT_S && unsent_bytes > max_frag_size_i[BYTE_CNT_WIDTH : 0] && max_frag_size_i <= DATA_WIDTH_B[PKT_SIZE_WIDTH - 1 : 0] ||
                      state == EOP_S;

assign pkt_i.tready = backpressure ? 1'b0 : pkt_o.tready;
assign pkt_o.tdata  = shifted_data_buf[0];
assign pkt_o.tvalid = ( state == PASSTHROUGH_S || state == FRAG_FROM_INPUT_S ) && buf_valid ||
                      state == FRAG_FROM_UNSENT_S || state == EOP_S;
assign pkt_o.tlast  = state == FRAG_FROM_UNSENT_S || state == FRAG_FROM_INPUT_S ||
                      state == EOP_S && ( eof_during_eop || last_frag_eof );
assign pkt_o.tkeep  = state == EOP_S && last_frag_eof ? tkeep_last_frag_eof :
                      state == FRAG_FROM_UNSENT_S || state == FRAG_FROM_INPUT_S || state == EOP_S && eof_during_eop ? tkeep_eof : shifted_tkeep_buf[0];
assign pkt_o.tstrb  = state == EOP_S && last_frag_eof ? tstrb_last_frag_eof :
                      state == FRAG_FROM_UNSENT_S || state == FRAG_FROM_INPUT_S || state == EOP_S && eof_during_eop ? tstrb_eof : shifted_tstrb_buf[0];
assign pkt_o.tid    = tid_buf;
assign pkt_o.tdest  = tdest_buf;
assign pkt_o.tuser  = tuser_buf;

endmodule
