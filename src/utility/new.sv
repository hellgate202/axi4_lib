module axi4_stream_pkt_frag #(
  parameter int DATA_WIDTH      = 32,
  parameter int ID_WIDTH        = 1,
  parameter int DEST_WIDTH      = 1,
  parameter int USER_WIDTH      = 1,
  parameter int MAX_FRAG_SIZE_B = 2048,
  parameter int FRAG_SIZE_WIDTH = $clog2( MAX_PKT_SIZE_B )
)(
  input                       clk_i,
  input                       rst_i,
  input [FRAG_SIZE_WIDTH : 0] max_frag_size_i,
  axi4_stream_if              pkt_i,
  axi4_stream_if              pkt_o
);

localparam int DATA_WIDTH_B   = DATA_WIDTH / 8;
localparam int BYTE_CNT_WIDTH = $clog2( DATA_WIDTH_B );

logic                                 tlast_lock;
logic                                 tfirst;
logic [1 : 0][DATA_WIDTH - 1 : 0]     tdata_buf;
logic [1 : 0][DATA_WIDTH - 1 : 0]     shifted_tdata_buf;
logic        [BYTE_CNT_WIDTH : 0]     unsent_bytes;
logic        [FRAG_SIZE_WIDTH : 0]    frag_byte_cnt;
logic        [FRAG_SIZE_WIDTH : 0]    frag_avail_bytes;
logic        [BYTE_CNT_WIDTH : 0]     pkt_val_bytes;
logic        [BYTE_CNT_WIDTH : 0]     frag_val_bytes;
logic        [BYTE_CNT_WIDTH + 1 : 0] buf_lvl;

logic                                 eof_from_unsent;
logic                                 eof_from_pkt;
logic                                 eof_from_eop;

assign eof_from_unsent = buf_lvl >= frag_avail_bytes;
assign eof_from_eop    = pkt_i.tvalid && pkt_i.tready && pkt_i.tlast;
assign eof_from_pkt    = frag_avail_bytes <= DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    tlast_lock <= 'd1;
  else
    if( pkt_i.tvalid && pkt_i.tlast )
      tlast_lock <= 1'b1;
    else
      if( pkt_i.tvalid && !pkt_i.tlast && pkt_i.tready )
        tlast_lock <= 1'b0;

assign tfirst = tlast_lock && pkt_i.tvalid;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    tdata_buf <= '0;
  else
    if( pkt_i.tvalid && pkt_i.tready )
      begin
        tdata_buf[1] <= pkt_i.tdata;
        tdata_buf[0] <= tdata_buf[1];
      end

assign shifted_tdata_buf = tdata_buf << unsent_bytes * 8;

always_comb
  begin
    pkt_val_bytes = '0;
    if( pkt_i.tlast )
      for( int i = 0; i < DATA_WIDTH_B; i++ )
        if( pkt_i.tkeep[i] || pkt_i.tstrb[i] )
          pkt_val_bytes += 1'b1;
    else
      pkt_val_bytes = DATA_WIDTH_B[BYTE_CNT_WIDTH : 0]
  end

always_comb
  begin
    frag_val_bytes = '0;
    if( pkt_o.tlast )
      for( int i = 0; i < DATA_WIDTH_B; i++ )
        if( pkt_o.tkeep[i] || pkt_o.tstrb[i] )
          frag_val_bytes += 1'b1;
    else
      frag_val_bytes = DATA_WIDTH_B[BYTE_CNT_WIDTH : 0]
  end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    frag_avail_bytes <= '0;
  else
    if( pkt_i.tfirst && pkt_i.tready )
      frag_avail_bytes <= max_frag_size_i;
    else
      if( pkt_o.tvalid && pkt_o.tready )
        if( pkt_o.tlast )
          frag_avail_bytes <= '0;
        else
          frag_val_bytes <= frag_val_bytes - DATA_WIDTH_B[BYTE_CNT_WIDTH : 0];

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    buf_lvl <= '0;
  else
    if( ( pkt_i.tvalid && pkt_i.tready ) && !( pkt_o.tvalid && pkt_o.tready ) )
      buf_lvl <= buf_lvl + pkt_val_bytes;
    else
      if( !( pkt_i.tvalid && pkt_i.tready ) && ( pkt_o.tvalid && pkt_o.tready ) )
        buf_lvl <= buf_lvl - frag_val_bytes;
      else
        if( ( pkt_i.tvalid && pkt_i.tready ) && ( pkt_o.tvalid && pkt_o.tready ) )
          buf_lvl <= buf_lvl - frag_val_bytes + pkt_val_bytes;

assign pkt_o.tvalid = buf_lvl >= DATA_WIDTH_B[BYTE_CNT_WIDTH + 1 : 0] || buf_lvl >= frag_avail_bytes;
assign pkt_i.tready = !eof_from_unsent && pkt_o.tready;

assign pkt_o.tdata = shifted_tdata_buf[1];
assign pkt_o.tlast = eof_from_unsent || eof_from_pkt || eof_from_eop;

endmodule
