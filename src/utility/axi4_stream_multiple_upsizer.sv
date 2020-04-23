module axi4_stream_multiple_upsizer #(
  parameter int SLAVE_TDATA_WIDTH  = 32,
  parameter int MASTER_TDATA_WIDTH = 64
)(
  input                 clk_i,
  input                 rst_i,
  axi4_stream_if.slave  pkt_i,
  axi4_stream_if.master pkt_o
);

localparam int SLAVE_TDATA_WIDTH_B  = SLAVE_TDATA_WIDTH / 8;
localparam int MASTER_TDATA_WIDTH_B = MASTER_TDATA_WIDTH / 8;
localparam int RATIO                = MASTER_TDATA_WIDTH / SLAVE_TDATA_WIDTH;
localparam int INS_CNT_WIDTH        = $clog2( RATIO );

logic                         rx_handshake;
logic                         tx_handshake;
logic [INS_CNT_WIDTH - 1 : 0] ins_pos;
logic                         tfirst;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    tfirst <= 1'b1;
  else
    if( rx_handshake )
      if( pkt_i.tlast )
        tfirst <= 1'b1;
      else
        tfirst <= 1'b0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    ins_pos <= INS_CNT_WIDTH'( 0 );
  else
    if( rx_handshake )
      if( pkt_i.tlast || ins_pos == INS_CNT_WIDTH( RATIO - 1 ) )
        ins_pos <= INS_CNT_WIDTH'( 0 );
      else
        ins_pos <= ins_pos + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    pkt_o.tvalid <= 1'b0;
  else
    if( pkt_i.tvalid && ( ins_pos == INS_CNT_WIDTH'( RATIO - 1 ) || pkt_i.tlast ) )
      pkt_o.tvalid <= 1'b1;
    else
      if( pkt_i.tready )
        pkt_o.tvalid <= 1'b0;

assign pkt_i.tready = !pkt_o.tvalid || pkt_o.tready;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      pkt_o.tdata <= MASTER_TDATA_WIDTH'( 0 );
      pkt_o.tkeep <= MASTER_TDATA_WIDTH_B'( 0 );
      pkt_o.tstrb <= MASTER_TDATA_WIDTH_B'( 0 );
    end
  else
    if( rx_handshake )
      if( ins_pos == INS_CNT_WIDTH'( RATIO - 1 )  )
        begin
          pkt_o.tdata[SLAVE_TDATA_WIDTH - 1 : 0]     <= pkt_i.tdata;
          pkt_o.tkeep[SLAVE_TDATA_WIDTH_B - 1 : 0] <= pkt_i.tkeep;
          pkt_o.tstrb[SLAVE_TDATA_WIDTH_B - 1 : 0] <= pkt_i.tstrb;
        end
      else
        begin
          pkt_o.tdata[( ins_pos + 1 ) * SLAVE_TDATA_WIDTH - 1 -: SLAVE_TDATA_WIDTH]     <= pkt_i.tdata;
          pkt_o.tkeep[( ins_pos + 1 ) * SLAVE_TDATA_WIDTH_B - 1 -: SLAVE_TDATA_WIDTH_B] <= pkt_i.tkeep;
          pkt_o.tstrb[( ins_pos + 1 ) * SLAVE_TDATA_WIDTH_B - 1 -: SLAVE_TDATA_WIDTH_B] <= pkt_i.tstrb;
        end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      pkt_o.tdest <= 1'b0;
      pkt_o.tid   <= 1'b0;
      pkt_o.tlast <= 1'b0;
    end
  else
    if( rx_handshake )
      begin
        pkt_o.tdest <= pkt_i.tdest;
        pkt_o.tid   <= pkt_i.tid;
        pkt_o.tlast <= pkt_i.tlast;
      end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    pkt_o.tuser <= 1'b0;
  else
    if( rx_handshake && tfirst )
      pkt_o.tuser <= pkt_i.tuser;
    else
      if( tx_handshake )
        pkt_o.tuser <= 1'b0;

endmodule
