interface axi4_stream_if #(
  parameter int DATA_WIDTH = 32,
  parameter int ID_WIDTH   = 8,
  parameter int DEST_WIDTH = 4,
  parameter int USER_WIDTH = 4
)(
  input aclk,
  input aresetn
);

logic                          tvalid;
logic                          tready;
logic [DATA_WIDTH - 1 : 0]     tdata;
logic [DATA_WIDTH / 8 - 1 : 0] tstrb;
logic [DATA_WIDTH / 8 - 1 : 0] tkeep;
logic                          tlast;
logic [ID_WIDTH - 1 : 0]       tid;
logic [DEST_WIDTH - 1 : 0]     tdest;
logic [USER_WIDTH - 1 : 0]     tuser;

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
