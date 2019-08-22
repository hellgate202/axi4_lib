module axi4_stream_pkt_frag #(
  parameter int DATA_WIDTH      = 32,
  parameter int ID_WIDTH        = 1,
  parameter int DEST_WIDTH      = 1,
  parameter int USER_WIDTH      = 1,
  parameter int MAX_FRAG_SIZE_B = 256,
  parameter int FRAG_SIZE_W     = $clog2( MAX_FRAG_SIZE_B )
)(
  input                   clk_i,
  input                   rst_i,
  input [FRAG_SIZE_W : 0] frag_size_i,
  axi4_stream_if.slave    pkt_i,
  axi4_stream_if.master   pkt_o
);

localparam int DATA_WIDTH_B   = DATA_WIDTH / 8;
localparam int DATA_WIDTH_B_W = $clog2( DATA_WIDTH_B );

logic                               pkt_i_tfirst;
logic [1 : 0][DATA_WIDTH - 1 : 0]   tdata_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] tstrb_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] tkeep_buf;
logic [1 : 0][DATA_WIDTH - 1 : 0]   shifted_tdata_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] shifted_tstrb_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] shifted_tkeep_buf;
logic                               move_data;
logic [FRAG_SIZE_W : 0]             frag_size_lock;
logic [FRAG_SIZE_W : 0]             frag_bytes_left;
logic [DATA_WIDTH_B_W : 0]          rx_bytes;
logic [DATA_WIDTH_B_W : 0]          tx_bytes;
logic [DATA_WIDTH_B_W : 0]          bytes_in_buf, bytes_in_buf_comb;
logic [DATA_WIDTH_B_W : 0]          shift;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    pkt_i_tfirst <= 'd1;
  else
    if( pkt_i.tvalid && pkt_i.tready ) 
      if( pkt_i.tlast )
        pkt_i_tfirst <= 1'b1;
      else
        pkt_i_tfirst <= 1'b0;

assign move_data = pkt_i.tvalid && pkt_i.tready || backpressure && pkt_o.tready;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      tdata_buf <= '0;
      tkeep_buf <= '0;
      tstrb_buf <= '0;
    end
  else
    if( move_data )
      begin
        tdata_buf[1] <= pkt_i.tdata;
        tdata_buf[0] <= tdata_buf[1];
        tkeep_buf[1] <= pkt_i.tkeep;
        tkeep_buf[0] <= tkeep_buf[1];
        tstrb_buf[1] <= pkt_i.tstrb;
        tstrb_buf[0] <= tstrb_buf[1];
      end

assign shifted_tdata_buf = tdata_buf << ( shift * 8 );
assign shifted_tstrb_buf = tstrb_buf << shift;
assign shifted_tkeep_buf = tkeep_buf << shift;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      pkt_o.tid   <= '0;
      pkt_o.tuser <= '0;
      pkt_o.tdest <= '0;
    end
  else
    if( pkt_i.tvalid && pkt_i.tready && pkt_i_tfirst )
      begin
        pkt_o.tid   <= pkt_i.tid;
        pkt_o.tuser <= pkt_i.tuser;
        pkt_o.tdest <= pkt_i.tdest;
      end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    frag_size_lock <= '0;
  else
    if( pkt_i.tvalid && pkt_i.tready && pkt_i_tfirst )
      frag_size_lock <= shift_i;

always_comb
  begin
    rx_bytes = '0;
    if( pkt_i.tvalid )
      if( pkt_i_tfirst || pkt_i.tlast )
        begin
          for( integer lmo = 0; lmo < DATA_WIDTH_B; lmo++ )
            if( pkt_i.tkeep[lmo] )
              rx_bytes = lmo[DATA_WIDTH_B_W : 0] + 1'b1;
        end
      else
        rx_bytes = DATA_WIDTH_B[DATA_WIDTH_B_W : 0];
  end

always_comb
  begin
    tx_bytes = '0;
    if( bytes_in_buf > '0 )
      if( frag_bytes_left > DATA_WIDTH_B[FRAG_SIZE_W : 0] )
        if( bytes_in_buf > DATA_WIDTH_B[DATA_WIDTH_B_W : 0] )
          tx_bytes = DATA_WIDTH_B[DATA_WIDTH_B_W : 0];
        else
          tx_bytes = bytes_in_buf;
      else
        if( frag_bytes_left[DATA_WIDTH_B_W : 0] > bytes_in_buf )
          tx_bytes = bytes_in_buf;
        else
          tx_bytes = frag_bytes_left[DATA_WIDTH_B_W : 0];
  end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    bytes_in_buf <= '0;
  else
    bytes_in_buf <= bytes_in_buf_comb;

always_comb
  begin
    bytes_in_buf_comb = bytes_in_buf;
    if( pkt_i.tready && pkt_o.tready )
      bytes_in_buf_comb = bytes_in_buf + rx_bytes - tx_bytes;
    else
      if( pkt_i.tready )
        bytes_in_buf_comb = bytes_in_buf + rx_bytes;
      else
        if( pkt_o.tready )
          bytes_in_buf_comb = bytes_in_buf - tx_bytes;
  end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    frag_bytes_left <= '0;
  else
    if( frag_bytes_left == tx_bytes || pkt_i.tvalid && pkt_i.tlast && pkt_i.tready )
      frag_bytes_left <= frag_size_lock;
    else
      if( pkt_o.tvalid && pkt_o.tready )
        frag_bytes_left <= frag_bytes_left - tx_bytes;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    shift <= '0;
  else
    if( backpressure && pkt_o.tready )
      shift <= shift - tx_bytes;
    else
      if( frag_bytes_left == tx_bytes && bytes_in_buf_comb > '0 )
        shift <= shift + ( rx_bytes - tx_bytes );

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    backpressure <= '0;
  else
    if( frag_bytes_left == tx_bytes && bytes_in_buf_comb > DATA_WIDTH_B[DATA_WIDTH_B_W : 0]  )
      backpressure <= 1'b1;
    else
      if( bytes_in_buf_comb <= DATA_WIDTH_B[DATA_WIDTH_B_W : 0] )
        backpressure <= 1'b0;

assign pkt_o.tdata  = shifted_tdata_buf[1];
assign pkt_o.tkeep  = shifted_tkeep_buf[1];
assign pkt_o.tstrb  = shifted_tstrb_buf[1];
assign pkt_i.tready = pkt_o.tready && !backpressure;
assign pkt_o.tvalid = bytes_in_buf > '0;
assign pkt_o.tlast  = bytes_in_buf == tx_bytes;

endmodule
