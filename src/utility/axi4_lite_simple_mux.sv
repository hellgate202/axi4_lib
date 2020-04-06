module axi4_lite_simple_mux #(
  parameter int DATA_WIDTH     = 32,
  parameter int ADDR_WIDTH     = 32,
  parameter int MASTERS_AMOUNT = 2,
  parameter int DIR_WIDTH      = $clog2( MASTERS_AMOUNT )
)(
  input                     clk_i,
  input                     rst_i,
  input [DIR_WIDTH - 1 : 0] dir_i,
  axi4_lite_if.slave        axi4_lite_i [MASTERS_AMOUNT - 1 : 0],
  axi4_lite_if.master       axi4_lite_o
);

localparam int DATA_WIDTH_B = DATA_WIDTH / 8;

logic [DIR_WIDTH - 1 : 0]                            dir;
logic                                                read_in_progress;
logic                                                write_in_progress;
logic                                                slave_req;
logic [MASTERS_AMOUNT - 1 : 0]                       master_awvalid;
logic [MASTERS_AMOUNT - 1 : 0]                       master_awready;
logic [MASTERS_AMOUNT - 1 : 0][ADDR_WIDTH - 1 : 0]   master_awaddr;
logic [MASTERS_AMOUNT - 1 : 0][2 : 0]                master_awprot;
logic [MASTERS_AMOUNT - 1 : 0]                       master_wvalid;
logic [MASTERS_AMOUNT - 1 : 0]                       master_wready;
logic [MASTERS_AMOUNT - 1 : 0][DATA_WIDTH - 1 : 0]   master_wdata;
logic [MASTERS_AMOUNT - 1 : 0][DATA_WIDTH_B - 1 : 0] master_wstrb;
logic [MASTERS_AMOUNT - 1 : 0]                       master_bvalid;
logic [MASTERS_AMOUNT - 1 : 0]                       master_bready;
logic [MASTERS_AMOUNT - 1 : 0][1 : 0]                master_bresp;
logic [MASTERS_AMOUNT - 1 : 0]                       master_arvalid;
logic [MASTERS_AMOUNT - 1 : 0]                       master_arready;
logic [MASTERS_AMOUNT - 1 : 0][ADDR_WIDTH - 1 : 0]   master_araddr;
logic [MASTERS_AMOUNT - 1 : 0][2 : 0]                master_arprot;
logic [MASTERS_AMOUNT - 1 : 0]                       master_rvalid;
logic [MASTERS_AMOUNT - 1 : 0]                       master_rready;
logic [MASTERS_AMOUNT - 1 : 0][DATA_WIDTH - 1 : 0]   master_rdata;
logic [MASTERS_AMOUNT - 1 : 0][1 : 0]                master_rresp;
logic                                                dir_change_allow;

genvar g;

generate
  for( g = 0; g < MASTERS_AMOUNT; g++ )
    begin : interface_unpacking
      assign master_awvalid[g]      = axi4_lite_i[g].awvalid;
      assign axi4_lite_i[g].awready = master_awready[g];
      assign master_awaddr[g]       = axi4_lite_i[g].awaddr;
      assign master_awprot[g]       = axi4_lite_i[g].awprot;
      assign master_wvalid[g]       = axi4_lite_i[g].wvalid;
      assign axi4_lite_i[g].wready  = master_wready[g];
      assign master_wdata[g]        = axi4_lite_i[g].wdata;
      assign master_wstrb[g]        = axi4_lite_i[g].wstrb;
      assign axi4_lite_i[g].bvalid  = master_bvalid[g];
      assign master_bready[g]       = axi4_lite_i[g].bready;
      assign axi4_lite_i[g].bresp   = master_bresp[g];
      assign master_arvalid[g]      = axi4_lite_i[g].arvalid;
      assign axi4_lite_i[g].arready = master_arready[g];
      assign master_araddr[g]       = axi4_lite_i[g].araddr;
      assign master_arprot[g]       = axi4_lite_i[g].arprot;
      assign axi4_lite_i[g].rvalid  = master_rvalid[g];
      assign master_rready[g]       = axi4_lite_i[g].rready;
      assign axi4_lite_i[g].rdata   = master_rdata[g];
      assign axi4_lite_i[g].rresp   = master_rresp[g];
    end
endgenerate

assign slave_req = axi4_lite_o.awvalid || axi4_lite_o.arvalid;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    read_in_progress <= 1'b0;
  else
    if( axi4_lite_o.arvalid && axi4_lite_o.arready )
      read_in_progress <= 1'b1;
    else
      if( axi4_lite_o.rvalid && axi4_lite_o.rready )
        read_in_progress <= 1'b0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    write_in_progress <= 1'b0;
  else
    if( axi4_lite_o.awvalid && axi4_lite_o.awready &&
        !( axi4_lite_o.wvalid && axi4_lite_o.wready ) )
      write_in_progress <= 1'b1;
    else
      if( axi4_lite_o.bvalid && axi4_lite_o.bready )
        write_in_progress <= 1'b0;

assign dir_change_allow = !write_in_progress && !read_in_progress && !slave_req;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    dir <= DIR_WIDTH'( 0 );
  else
    if( dir_change_allow )
      dir <= dir_i;

always_comb
  for( int i = 0; i < MASTERS_AMOUNT; i++ )
    if( dir == DIR_WIDTH'( i ) )
      begin
        master_awready[i] = axi4_lite_o.awready;
        master_wready[i]  = axi4_lite_o.wready;
        master_bvalid[i]  = axi4_lite_o.bvalid;
        master_bresp[i]   = axi4_lite_o.bresp;
        master_arready[i] = axi4_lite_o.arready;
        master_rvalid[i]  = axi4_lite_o.rvalid;
        master_rdata[i]   = axi4_lite_o.rdata;
        master_rresp[i]   = axi4_lite_o.rresp;
      end
    else
      begin
        master_awready[i] = 1'b0; 
        master_wready[i]  = 1'b0; 
        master_bvalid[i]  = 1'b0; 
        master_bresp[i]   = 2'd0; 
        master_arready[i] = 1'b0; 
        master_rvalid[i]  = 1'b0; 
        master_rdata[i]   = DATA_WIDTH'( 0 ); 
        master_rresp[i]   = 2'd0; 
      end

always_comb
  begin
    axi4_lite_o.awvalid = master_awvalid[dir];
    axi4_lite_o.awaddr  = master_awaddr[dir];
    axi4_lite_o.awprot  = master_awprot[dir];
    axi4_lite_o.wvalid  = master_wvalid[dir];
    axi4_lite_o.wdata   = master_wdata[dir];
    axi4_lite_o.wstrb   = master_wstrb[dir];
    axi4_lite_o.bready  = master_bready[dir];
    axi4_lite_o.arvalid = master_arvalid[dir];
    axi4_lite_o.araddr  = master_araddr[dir];
    axi4_lite_o.arprot  = master_arprot[dir];
    axi4_lite_o.rready  = master_rready[dir];
  end

endmodule
