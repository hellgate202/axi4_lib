`timescale 1 ps / 1 ps

class AXI4LiteSlave #(
  parameter int DATA_WIDTH     = 32,
  parameter int ADDR_WIDTH     = 16,
  parameter int INIT_PATH      = "",

  parameter int VERBOSE        = 0,
  parameter int WATCHDOG_EN    = 1,
  parameter int WATCHDOG_LIMIT = 100 
);

localparam int DATA_WIDTH_B   = DATA_WIDTH / 8;
localparam int ADDR_WORD_BITS = DATA_WIDTH_B == 1 ? 1 : 
                                $clog2( DATA_WIDTH_B );

bit [7 : 0] memory [*];
bit         running;

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

local function automatic void init_interface();

  axi4_lite_if_v.awready = 1'b1;
  axi4_lite_if_v.wready  = 1'b1;
  axi4_lite_if_v.arready = 1'b1;
  axi4_lite_if_v.bvalid  = 1'b0;
  axi4_lite_if_v.bresp   = 2'b0;
  axi4_lite_if_v.rvalid  = 1'b0;
  axi4_lite_if_v.rdata   = '0;
  axi4_lite_if_v.rresp   = 2'b0;
  fork
    run();
  join_none

endfunction

function automatic void init_memory();
  if( INIT_PATH == "" )
    for( int i = 0; i < 2 ** ADDR_WIDTH; i++ )
      memory[i] = '0;
  else
    $readmemh( INIT_PATH, memory );
endfunction

task automatic run();

  if( ~running )
    begin
      running = 1'b1;
      if( VERBOSE > 0 )
        begin
          $display( "%0d", $time() );
          $display( "AXI4-Lite SLave: interface listening is enabled." );
        end
      fork
        forever
          begin
            if( axi4_lite_if_v.awvalid )
              wr_data();
            else
              if( axi4_lite_if_v.arvalid )
                rd_data();
              else
                @( posedge axi4_lite_if_v.aclk );
            if( ~running )
              begin
                if( VERBOSE > 0 )
                  begin
                    $display( "%0d", $time() );
                    $display( "AXI4-Lite Slave: interface listening is disabled." );
                  end
                break;
              end
          end
      join_none
    end
  else
    if( VERBOSE > 0 )
      begin
        $display( "%0d", $time() );
        $display( "AXI4-Lite Slave: interface listening is already enabled!" );
      end
  
endtask

task automatic stop();

  running = 1'b0;

endtask

local task automatic wr_data();

  bit [ADDR_WIDTH - 1 : 0] addr;

  addr                         = axi4_lite_if_v.awaddr;
  addr[ADDR_WORD_BITS - 1 : 0] = '0;
  while( ~axi4_lite_if_v.wvalid )
    @( posedge axi4_lite_if_v.aclk );
  if( VERBOSE > 2 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4-Lite Slave: %0h was written to %0h", axi4_lite_if_v.wdata, axi4_lite_if_v.awaddr );
    end
  for( int i = 0; i < DATA_WIDTH_B; i++ )
    if( axi4_lite_if_v.wstrb[i] )
      memory[addr + i] = axi4_lite_if_v.wdata[i * 8 + 7 -: 8];
  wr_response();
  @( posedge axi4_lite_if_v.aclk );

endtask

local task automatic wr_response();

  fork
    begin
      axi4_lite_if_v.bvalid <= 1'b1;
      do
        @( posedge axi4_lite_if_v.aclk );
      while( ~axi4_lite_if_v.bready );
      axi4_lite_if_v.bvalid <= 1'b0;
    end
  join_none

endtask

local task automatic rd_data();
  
  bit [ADDR_WIDTH-1:0] addr;

  addr                         = axi4_lite_if_v.araddr;
  addr[ADDR_WORD_BITS - 1 : 0] = '0;
  axi4_lite_if_v.rvalid  <= 1'b1;
  for( int i = 0; i < DATA_WIDTH_B; i++ )
    if( memory.exists(addr) )
      axi4_lite_if_v.rdata[i * 8 + 7 -: 8] <= memory[addr + i];
    else
      axi4_lite_if_v.rdata <= 8'b0;
  if( WATCHDOG_EN )
    watchdog( axi4_lite_if_v.rready );
  do
    @( posedge axi4_lite_if_v.aclk );
  while( ~axi4_lite_if_v.rready );
  if( VERBOSE > 2 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4-Lite Slave: %0h was read from %0h", axi4_lite_if_v.rdata, addr );
    end
  axi4_lite_if_v.rvalid <= 1'b0;
  axi4_lite_if_v.rdata  <= '0;
  
endtask

local task automatic watchdog(
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
