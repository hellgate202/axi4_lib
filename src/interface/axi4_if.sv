interface axi4_if#(
  parameter int DATA_WIDTH   = 32,
  parameter int ADDR_WIDTH   = 16,
  parameter int ID_WIDTH     = 1,
  parameter int AWUSER_WIDTH = 1,
  parameter int WUSER_WIDTH  = 1,
  parameter int BUSER_WIDTH  = 1,
  parameter int ARUSER_WIDTH = 1,
  parameter int RUSER_WIDTH  = 1
)(
  input aclk,
  input aresetn
);

logic [ID_WIDTH - 1 : 0]       awid;
logic [ADDR_WIDTH - 1 : 0]     awaddr;
logic [7 : 0]                  awlen;
logic [2 : 0]                  awsize;
logic [1 : 0]                  awburst;
logic                          awlock;
logic [3 : 0]                  awcache;
logic [2 : 0]                  awprot;
logic [3 : 0]                  awqos;
logic [3 : 0]                  awregion;
logic [AWUSER_WIDTH - 1 : 0]   awuser;
logic                          awvalid;
logic                          awready;

logic [DATA_WIDTH - 1 : 0]     wdata;
logic [DATA_WIDTH / 8 - 1 : 0] wstrb;
logic                          wlast;
logic [WUSER_WIDTH - 1 : 0]    wuser;
logic                          wvalid;
logic                          wready;

logic [ID_WIDTH - 1 : 0]       bid;
logic [1 : 0]                  bresp;
logic [BUSER_WIDTH - 1 : 0]    buser;
logic                          bvalid;
logic                          bready;

logic [ID_WIDTH - 1 : 0]       arid;
logic [ADDR_WIDTH - 1 : 0]     araddr;
logic [7 : 0]                  arlen;
logic [2 : 0]                  arsize;
logic [1 : 0]                  arburst;
logic                          arlock;
logic [3 : 0]                  arcache;
logic [2 : 0]                  arprot;
logic [3 : 0]                  arqos;
logic [3 : 0]                  arregion;
logic [ARUSER_WIDTH - 1 : 0]   aruser;
logic                          arvalid;
logic                          arready;

logic [ID_WIDTH - 1 : 0]       rid;
logic [DATA_WIDTH - 1 : 0]     rdata;
logic [1 : 0]                  rresp;
logic                          rlast;
logic [RUSER_WIDTH - 1 : 0]    ruser;
logic                          rvalid;
logic                          rready;

modport master(
  output awid,
  output awaddr,
  output awlen,
  output awsize,
  output awburst,
  output awlock,
  output awcache,
  output awprot,
  output awqos,
  output awregion,
  output awuser,
  output awvalid,
  input  awready,
  output wdata,
  output wstrb,
  output wlast,
  output wuser,
  output wvalid,
  input  wready,
  input  bid,
  input  bresp,
  input  buser,
  input  bvalid,
  output bready,
  output arid,
  output araddr,
  output arlen,
  output arsize,
  output arburst,
  output arlock,
  output arcache,
  output arprot,
  output arqos,
  output arregion,
  output aruser,
  output arvalid,
  input  arready,
  input  rid,
  input  rdata,
  input  rresp,
  input  rlast,
  input  ruser,
  input  rvalid,
  output rready
);

modport slave(
  input  awid,
  input  awaddr,
  input  awlen,
  input  awsize,
  input  awburst,
  input  awlock,
  input  awcache,
  input  awprot,
  input  awqos,
  input  awregion,
  input  awuser,
  input  awvalid,
  output awready,
  input  wdata,
  input  wstrb,
  input  wlast,
  input  wuser,
  input  wvalid,
  output wready,
  output bid,
  output bresp,
  output buser,
  output bvalid,
  input  bready,
  input  arid,
  input  araddr,
  input  arlen,
  input  arsize,
  input  arburst,
  input  arlock,
  input  arcache,
  input  arprot,
  input  arqos,
  input  arregion,
  input  aruser,
  input  arvalid,
  output arready,
  output rid,
  output rdata,
  output rresp,
  output rlast,
  output ruser,
  output rvalid,
  input  rready
);
//synthesis translate_off
typedef struct {
  bit [ADDR_WIDTH - 1 : 0] start_addr;
  bit [7 : 0]              wr_data [$];
} wr_tran_t;

typedef struct {
  bit [ADDR_WIDTH - 1 : 0] start_addr;
  int                      words_amount;
} rd_tran_t;
//synthesis translate_on

endinterface
