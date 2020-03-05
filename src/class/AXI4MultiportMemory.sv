`timescale 1 ps / 1 ps

class AXI4MultiportMemory #(
  parameter int PORTS_AMOUNT   = 2,

  parameter int INIT_PATH      = "",
  parameter int DATA_WIDTH     = 32,
  parameter int ADDR_WIDTH     = 16,
  parameter int ID_WIDTH       = 4,
  parameter int AWUSER_WIDTH   = 1,
  parameter int WUSER_WIDTH    = 1,
  parameter int BUSER_WIDTH    = 1,
  parameter int ARUSER_WIDTH   = 1,
  parameter int RUSER_WIDTH    = 1,

  parameter int RANDOM_WREADY  = 0,
  parameter int RANDOM_RVALID  = 0,
  parameter int VERBOSE        = 0,
  parameter int WATCHDOG_EN    = 1,
  parameter int WATCHDOG_LIMIT = 100
);

localparam DATA_WIDTH_B   = DATA_WIDTH / 8;
localparam ADDR_WORD_BITS = $clog2( DATA_WIDTH_B );

bit [7 : 0]                memory [*];
bit [PORTS_AMOUNT - 1 : 0] running;

semaphore wr_semaphore = new(1);

virtual axi4_if #(
  .DATA_WIDTH   ( DATA_WIDTH   ),
  .ADDR_WIDTH   ( ADDR_WIDTH   ),
  .ID_WIDTH     ( ID_WIDTH     ),
  .AWUSER_WIDTH ( AWUSER_WIDTH ),
  .WUSER_WIDTH  ( WUSER_WIDTH  ),
  .BUSER_WIDTH  ( BUSER_WIDTH  ),
  .ARUSER_WIDTH ( ARUSER_WIDTH ),
  .RUSER_WIDTH  ( RUSER_WIDTH  )
) axi4_if_v [PORTS_AMOUNT - 1 : 0];

function new(
  virtual axi4_if #(
    .DATA_WIDTH   ( DATA_WIDTH   ),
    .ADDR_WIDTH   ( ADDR_WIDTH   ),
    .ID_WIDTH     ( ID_WIDTH     ),
    .AWUSER_WIDTH ( AWUSER_WIDTH ),
    .WUSER_WIDTH  ( WUSER_WIDTH  ),
    .BUSER_WIDTH  ( BUSER_WIDTH  ),
    .ARUSER_WIDTH ( ARUSER_WIDTH ),
    .RUSER_WIDTH  ( RUSER_WIDTH  )
  ) axi4_if_v [PORTS_AMOUNT - 1 : 0]
);

  this.axi4_if_v   = axi4_if_v;
  init_interfaces();

endfunction

local function automatic void init_interfaces();

  for( int i = 0; i < PORTS_AMOUNT; i++ )
    begin
      automatic int j;
      j = i;
      axi4_if_v[i].awready = 1'b1;
      axi4_if_v[i].wready  = 1'b0;
      axi4_if_v[i].bid     = '0;
      axi4_if_v[i].bresp   = 2'b00;
      axi4_if_v[i].buser   = '0;
      axi4_if_v[i].bvalid  = 1'b0;
      axi4_if_v[i].arready = 1'b1;
      axi4_if_v[i].rid     = '0;
      axi4_if_v[i].rdata   = '0;
      axi4_if_v[i].rresp   = 2'b0;
      axi4_if_v[i].rlast   = 1'b0;
      axi4_if_v[i].ruser   = '0;
      axi4_if_v[i].rvalid  = 1'b0;
      fork
        run( j );
      join_none
    end

endfunction

function automatic void init_memory();
  if( INIT_PATH == "" )
    for( int i = 0; i < 2 ** ADDR_WIDTH; i++ )
      memory[i] = '0;
  else
    $readmemh( INIT_PATH, memory );
endfunction

local task automatic run( int if_num );

  if( ~running )
    begin
      running[if_num] = 1'b1;
      if( VERBOSE > 0 )
        begin
          $display( "%0d", $time() );
          $display( "AXI4 Slave: interface %0d listening is enabled.", if_num );
        end
      if( RANDOM_WREADY )
        axi4_if_v[if_num].wready = 1'b0;
      else
        axi4_if_v[if_num].wready = 1'b1;
      fork
        forever
          begin
            fork
              begin : wr_check
                if( axi4_if_v[if_num].awvalid )
                  wr_data( if_num );
                else
                  @( posedge axi4_if_v[if_num].aclk );
              end
              begin : rd_check
                if( axi4_if_v[if_num].arvalid )
                  rd_data( if_num );
                else
                  @( posedge axi4_if_v[if_num].aclk );
              end
            join
          end
      join_none
    end
  else
    if( VERBOSE > 0 )
      begin
        $display( "%0d", $time() );
        $display( "AXI4 Slave: interface %0d listening is already enabled!", if_num );
      end

endtask

local task automatic wr_data( int if_num );

  bit                      wready;
  bit                      eot;
  bit [ADDR_WIDTH - 1 : 0] cur_addr = axi4_if_v[if_num].awaddr;
  bit [7:0]                awlen    = axi4_if_v[if_num].awlen;

  if( VERBOSE > 1 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4 %0d Slave: write transaction detected", if_num );
    end
  do
    begin
      if( WATCHDOG_EN )
        watchdog( if_num, axi4_if_v[if_num].wvalid, "WVALID" );
      if( RANDOM_WREADY )
        wready = $urandom_range( 1 );
      else
        wready = 1'b1;
      axi4_if_v[if_num].wready <= wready;
      if( axi4_if_v[if_num].wvalid && axi4_if_v[if_num].wready )
        begin
          wr_semaphore.get();
          for( int i = 0; i < DATA_WIDTH_B; i++ )
            begin
              if( axi4_if_v[if_num].wstrb[i] )
                memory[cur_addr] = axi4_if_v[if_num].wdata[i * 8 + 7 -: 8];
              cur_addr++;
            end
          wr_semaphore.put();
          if( VERBOSE > 2 )
            begin
              $display( "%0d", $time() );
              $display( "AXI4 %0d Slave: %0h was written by master", if_num, axi4_if_v[if_num].wdata );
            end
          if( awlen == 0 || axi4_if_v[if_num].wlast )
            begin
              eot = 1'b1;
              wr_response( if_num );
              if( RANDOM_WREADY )
                axi4_if_v[if_num].wready <= 1'b0;
            end
          else
            awlen--;
        end
      @( posedge axi4_if_v[if_num].aclk );
    end
  while( ~eot );
  if( VERBOSE > 1 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4 %0d Slave: write transaction has been ended", if_num );
    end

endtask

local task automatic wr_response( int if_num );
  fork
    begin
      axi4_if_v[if_num].bvalid <= 1'b1;
      do
        @( posedge axi4_if_v[if_num].aclk );
      while( ~axi4_if_v[if_num].bready );
      axi4_if_v[if_num].bvalid <= 1'b0;
    end
  join_none

endtask

local task automatic rd_data( int if_num );

  bit                      rvalid;
  bit [8 : 0]              arlen    = axi4_if_v[if_num].arlen + 1'b1;
  bit [ADDR_WIDTH - 1 : 0] cur_addr = axi4_if_v[if_num].araddr;

  if( VERBOSE > 1 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4 %0d Slave: read transaction detected", if_num );
    end
  cur_addr[ADDR_WORD_BITS - 1 : 0] = '0;
  while( arlen )
    begin
      if( RANDOM_RVALID )
        rvalid = 1'b0;
      else
        rvalid = 1'b1;
      while( ~rvalid )
        begin
          rvalid = $urandom_range( 1 );
          if( ~rvalid )
            @( posedge axi4_if_v[if_num].aclk );
        end
      axi4_if_v[if_num].rvalid <= 1'b1;
      for( int i = 0; i < DATA_WIDTH_B; i++ )
        begin
          if( memory.exists( cur_addr ) )
            axi4_if_v[if_num].rdata[i * 8 + 7 -: 8] <= memory[cur_addr];
          else
            axi4_if_v[if_num].rdata[i * 8 + 7 -: 8] <= 8'b0;
          cur_addr++;
        end
      if( arlen == 9'd1 )
        axi4_if_v[if_num].rlast <= 1'b1;
      if( WATCHDOG_EN )
        watchdog( if_num, axi4_if_v[if_num].rready, "RREADY" );
      do
        @( posedge axi4_if_v[if_num].aclk );
      while( ~axi4_if_v[if_num].rready );
      if( VERBOSE > 2 )
        begin
          $display( "%0d", $time() );
          $display( "AXI4 %0d Slave: %0h was read by master", if_num, axi4_if_v[if_num].rdata );
        end
      arlen--;
      axi4_if_v[if_num].rvalid <= 1'b0;
    end
  axi4_if_v[if_num].rdata <= '0;
  axi4_if_v[if_num].rlast <= 1'b0;
  if( VERBOSE > 1 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4 %0d Slave: read transaction has been ended", if_num );
    end

endtask

local task automatic watchdog(
  int           if_num,
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
        @( posedge axi4_if_v[if_num].aclk );
        watchdog_cnt++;
      end
  join_none

endtask

endclass
