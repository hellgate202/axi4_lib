module axi4_stream_multiple_downsizer #(
  parameter int SLAVE_TDATA_WIDTH  = 64,
  parameter int MASTER_TDATA_WIDTH = 32
)(
  input                 clk_i,
  input                 rst_i,
  axi4_stream_if.slave  pkt_i,
  axi4_stream_if.master pkt_o
);

localparam int SLAVE_TDATA_WIDTH_B  = SLAVE_TDATA_WIDTH / 8;
localparam int MASTER_TDATA_WIDTH_B = MASTER_TDATA_WIDTH / 8;
localparam int RATIO                = SLAVE_TDATA_WIDTH / MASTER_TDATA_WIDTH;
localparam int INS_CNT_WIDTH        = $clog2( RATIO );

logic                                               rx_handshake;
logic                                               tx_handshake;
logic [INS_CNT_WIDTH - 1 : 0]                       ins_pos;
logic [RATIO - 1 : 0][MASTER_TDATA_WIDTH - 1 : 0]   tdata_buf;
logic [RATIO - 1 : 0][MASTER_TDATA_WIDTH_B - 1 : 0] tstrb_buf;
logic [RATIO - 1 : 0][MASTER_TDATA_WIDTH_B - 1 : 0] tkeep_buf;
logic                                               tuser_buf;
logic                                               tdest_buf;
logic                                               tid_buf;
logic                                               tlast_buf;
logic                                               word_lock;
logic [INS_CNT_WIDTH - 1 : 0]                       syms_in_rx_w, syms_in_rx_w_lock;

assign rx_handshake = pkt_i.tvalid && pkt_i.tready;
assign tx_handshake = pkt_o.tvalid && pkt_o.tready;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      tdata_buf <= SLAVE_TDATA_WIDTH'( 0 );
      tstrb_buf <= SLAVE_TDATA_WIDTH_B'( 0 );
      tkeep_buf <= SLAVE_TDATA_WIDTH_B'( 0 );
      tuser_buf <= 1'b0;
      tdest_buf <= 1'b0;
      tid_buf   <= 1'b0;
      tlast_buf <= 1'b0;
    end
  else
    if( rx_handshake )
      begin
        tdata_buf <= pkt_i.tdata;
        tstrb_buf <= pkt_i.tstrb;
        tkeep_buf <= pkt_i.tkeep;
        tuser_buf <= pkt_i.tuser;
        tdest_buf <= pkt_i.tdest;
        tid_buf   <= pkt_i.tid;
        tlast_buf <= pkt_i.tlast;
      end

always_comb
  begin
    syms_in_rx_w = INS_CNT_WIDTH'( 0 );
    for( int i = MASTER_TDATA_WIDTH_B; i < SLAVE_TDATA_WIDTH_B; i = i + MASTER_TDATA_WIDTH_B )
      if( pkt_i.tkeep[i] )
        syms_in_rx_w = syms_in_rx_w + 1'b1;
  end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    syms_in_rx_w_lock <= INS_CNT_WIDTH'( 0 );
  else
    if( rx_handshake )
      syms_in_rx_w_lock <= syms_in_rx_w;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    word_lock <= 1'b0;
  else
    if( rx_handshake )
      word_lock <= 1'b1;
    else
      if( tx_handshake && ins_pos == syms_in_rx_w_lock )
        word_lock <= 1'b0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    ins_pos <= INS_CNT_WIDTH'( 0 );
  else
    if( tx_handshake )
      if( ins_pos == syms_in_rx_w_lock )
        ins_pos <= INS_CNT_WIDTH'( 0 );
      else
        ins_pos <= ins_pos + 1'b1;

assign pkt_i.tready = !word_lock || ( ins_pos == syms_in_rx_w_lock && tx_handshake );
assign pkt_o.tvalid = word_lock;
assign pkt_o.tdata  = tdata_buf[ins_pos];
assign pkt_o.tkeep  = tkeep_buf[ins_pos];
assign pkt_o.tstrb  = tstrb_buf[ins_pos];
assign pkt_o.tlast  = tlast_buf && ins_pos == syms_in_rx_w_lock;
assign pkt_o.tdest  = tdest_buf;
assign pkt_o.tid    = tid_buf;
assign pkt_o.tuser  = tuser_buf && ins_pos == INS_CNT_WIDTH'( 0 );

endmodule
