module axi4_stream_pipeline #(
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

typedef struct packed {
  logic [TDATA_WIDTH - 1 : 0]   tdata;
  logic                         tlast;
  logic [TDATA_WIDTH_B - 1 : 0] tstrb;
  logic [TDATA_WIDTH_B - 1 : 0] tkeep;
  logic [TID_WIDTH - 1 : 0]     tid;
  logic [TDEST_WIDTH - 1 : 0]   tdest;
  logic [TUSER_WIDTH - 1 : 0]   tuser;
} axi4_stream_word_t;

axi4_stream_word_t         data;
logic              [1 : 0] valid_d1;
axi4_stream_word_t [1 : 0] data_d1;
logic                      ready_d1;
logic                      valid_d2;
axi4_stream_word_t         data_d2;
logic                      wr_ptr;
logic                      rd_ptr;

assign data.tdata  = pkt_i.tdata;
assign data.tlast  = pkt_i.tlast;
assign data.tstrb  = pkt_i.tstrb;
assign data.tkeep  = pkt_i.tkeep;
assign data.tid    = pkt_i.tid;
assign data.tdest  = pkt_i.tdest;
assign data.tuser  = pkt_i.tuser;

assign pkt_i.tready = !valid_d1[wr_ptr];

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    rd_ptr <= 1'b0;
  else
    if( ready_d1 && valid_d1[rd_ptr] )
      rd_ptr <= !rd_ptr;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    wr_ptr <= 1'b0;
  else
    if( pkt_i.tready && pkt_i.tvalid )
      wr_ptr <= !wr_ptr;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    valid_d1 <= 2'd0;
  else
    if( rd_ptr != wr_ptr )
      begin
        if( ready_d1 && valid_d1[rd_ptr] )
          valid_d1[rd_ptr] <= 1'b0;
        if( pkt_i.tready )
          valid_d1[wr_ptr] <= valid_i;
      end
    else
      if( valid_d1[wr_ptr] && ready_d1 )
        valid_d1[wr_ptr] <= 1'b0;
      else
        if( pkt_i.tready )
          valid_d1[wr_ptr] <= valid_i;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_d1 <= '0;
  else
    if( pkt_i.tready )
      data_d1[wr_ptr] <= data;

assign ready_d1 = pkt_o.tready || !valid_d2;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    valid_d2 <= 1'b0;
  else
    if( ready_d1 )
      valid_d2 <= valid_d1[rd_ptr];

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_d2 <= '0;
  else
    if( ready_d1 )
      data_d2 <= data_d1[rd_ptr];

assign pkt_o.tvalid = valid_d2;
assign pkt_o.tdata  = data_d2.tdata;
assign pkt_o.tlast  = data_d2.tlast;
assign pkt_o.tkeep  = data_d2.tkeep;
assign pkt_o.tstrb  = data_d2.tstrb;
assign pkt_o.tid    = data_d2.tid;
assign pkt_o.tuser  = data_d2.tuser;
assign pkt_o.tdest  = data_d2.tdest;

endmodule
