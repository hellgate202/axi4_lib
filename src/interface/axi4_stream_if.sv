interface axi4_stream_if #(
  parameter int TDATA_WIDTH = 32,
  parameter int TID_WIDTH   = 1,
  parameter int TDEST_WIDTH = 1,
  parameter int TUSER_WIDTH = 1
)(
  input aclk,
  input aresetn
);

logic                           tvalid;
logic                           tready;
logic [TDATA_WIDTH - 1 : 0]     tdata;
logic [TDATA_WIDTH / 8 - 1 : 0] tstrb;
logic [TDATA_WIDTH / 8 - 1 : 0] tkeep;
logic                           tlast;
logic [TID_WIDTH - 1 : 0]       tid;
logic [TDEST_WIDTH - 1 : 0]     tdest;
logic [TUSER_WIDTH - 1 : 0]     tuser;

modport master(
  output tvalid,
  input  tready,
  output tdata ,
  output tstrb,
  output tkeep,
  output tlast,
  output tid,
  output tdest,
  output tuser
);

modport slave(
  input  tvalid,
  output tready,
  input  tdata,
  input  tstrb,
  input  tkeep,
  input  tlast,
  input  tid,
  input  tdest,
  input  tuser
);

endinterface
