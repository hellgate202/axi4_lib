module axi4_stream_delay #(
  parameter int TDATA_WIDTH = 32,
  parameter int TID_WIDTH   = 1,
  parameter int TDEST_WIDTH = 1,
  parameter int TUSER_WIDTH = 1
)(
  input                 clk_i,
  input                 rst_i,
  axi4_stream_if.slave  pkt_i,
  axi4_stream_if.master pkt_o
);

localparam int TDATA_WIDTH_B = TDATA_WIDTH / 8;

assign pkt_i.tready = pkt_o.tready || !pkt_o.tvalid;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      pkt_o.tvalid <= 1'b0;
      pkt_o.tlast  <= 1'b0;
      pkt_o.tdata  <= TDATA_WIDTH'( 0 );
      pkt_o.tstrb  <= TDATA_WIDTH_B'( 0 );
      pkt_o.tkeep  <= TDATA_WIDTH_B'( 0 );
      pkt_o.tid    <= TID_WIDTH'( 0 );
      pkt_o.tdest  <= TDEST_WIDTH'( 0 );
      pkt_o.tuser  <= TUSER_WIDTH'( 0 );
    end
  else
    if( pkt_i.tready )
      begin
        pkt_o.tvalid <= pkt_i.tvalid;
        pkt_o.tlast  <= pkt_i.tlast;
        pkt_o.tdata  <= pkt_i.tdata;
        pkt_o.tstrb  <= pkt_i.tstrb;
        pkt_o.tkeep  <= pkt_i.tkeep;
        pkt_o.tid    <= pkt_i.tid;
        pkt_o.tdest  <= pkt_i.tdest;
        pkt_o.tuser  <= pkt_i.tuser;
      end

endmodule
