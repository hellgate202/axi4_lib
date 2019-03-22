`timescale 1 ps / 1 ps

class AXI4LiteMaster #(
  parameter int DATA_WIDTH     = 32,
  parameter int ADDR_WIDTH     = 16,

  parameter int VERBOSE        = 0,
  parameter int WATCHDOG_EN    = 1,
  parameter int WATCHDOG_LIMIT = 100
);

localparam int DATA_WIDTH_B   = DATA_WIDTH / 8;
localparam int ADDR_WORD_BITS = $clog2( DATA_WIDTH_B );

virtual axi4_lite_if #(
  .DATA_WIDTH ( DATA_WIDTH ),
  .ADDR_WIDTH ( ADDR_WIDTH )
) axi4_lite_if_v;

function new(
  virtual axi4_lite_if #(
    .DATA_WIDTH ( DATA_WIDTH ),
    .ADDR_WIDTH ( ADDR_WIDTH )
  ) axi4_lite_if_v
);

  this.axi4_lite_if_v = axi4_lite_if_v;
  init_interface();

endfunction

function automatic void init_interface();

  axi4_lite_if_v.awvalid = 1'b0;
  axi4_lite_if_v.awaddr  = '0;
  axi4_lite_if_v.awprot  = 3'b0;
  axi4_lite_if_v.wvalid  = 1'b0;
  axi4_lite_if_v.wdata   = '0;
  axi4_lite_if_v.wstrb   = '0;
  axi4_lite_if_v.bready  = 1'b1;
  axi4_lite_if_v.arvalid = 1'b0;
  axi4_lite_if_v.araddr  = '0;
  axi4_lite_if_v.arprot  = 3'b0;
  axi4_lite_if_v.rready  = 1'b1;

endfunction

task automatic wr_data(
  input bit [ADDR_WIDTH - 1 : 0] addr,
  input bit [DATA_WIDTH - 1 : 0] data
);

  addr[ADDR_WORD_BITS - 1 : 0]  = '0;
  axi4_lite_if_v.awvalid       <= 1'b1;
  if( WATCHDOG_EN )
    watchdog( axi4_lite_if_v.awready, "AWREADY" );
  axi4_lite_if_v.awaddr        <= addr;
  axi4_lite_if_v.wvalid        <= 1'b1;
  if( WATCHDOG_EN )
    watchdog( axi4_lite_if_v.wready, "WREADY" );
  axi4_lite_if_v.wdata         <= data;
  axi4_lite_if_v.wstrb         <= '1;
  @( posedge axi4_lite_if_v.aclk );
  fork
    begin : aw_channel
      while( ~axi4_lite_if_v.awready )
        @( posedge axi4_lite_if_v.aclk );
      axi4_lite_if_v.awaddr  <= '0;
      axi4_lite_if_v.awvalid <= 1'b0;
    end
    begin : w_channel
      while( ~axi4_lite_if_v.wready )
        @( posedge axi4_lite_if_v.aclk );
      axi4_lite_if_v.wdata  <= '0;
      axi4_lite_if_v.wstrb  <= '0;
      axi4_lite_if_v.wvalid <= 1'b0;
    end
  join
  if( VERBOSE > 2 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4-Lite Master: %0h was written to %0h", data, addr );
    end

endtask

task automatic rd_data(
  input  bit [ADDR_WIDTH-1:0] addr,
  output bit [DATA_WIDTH-1:0] data
);

  addr[ADDR_WORD_BITS - 1 : 0]   = '0;
  axi4_lite_if_v.arvalid        <= 1'b1;
  axi4_lite_if_v.araddr         <= addr;
  @( posedge axi4_lite_if_v.aclk );
  while( ~axi4_lite_if_v.arready )
    @( posedge axi4_lite_if_v.aclk );
  axi4_lite_if_v.arvalid <= 1'b0;
  axi4_lite_if_v.araddr  <= '0;
  while( ~axi4_lite_if_v.rvalid )
    @( posedge axi4_lite_if_v.aclk );
  data = axi4_lite_if_v.rdata;
  if( VERBOSE > 2 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4-Lite Master: %0h was read from %0h", data, addr );
    end

endtask

task automatic watchdog(
  ref logic     signal,
  input string  msg = "",
  input bit     value = 1'b1
);
  
  int watchdog_cnt;

  fork
    forever
      begin
        if( watchdog_cnt == WATCHDOG_LIMIT )
          begin
            $display( "%0d", $time() );
            $display( "Error! Watchdog timeout!" );
            if( msg != "" )
              $display( msg );
            $stop();
          end
        if( signal == value )
          break;
        @( posedge axi4_lite_if_v.aclk );
        watchdog_cnt++;
      end
  join_none

endtask

endclass
