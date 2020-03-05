`timescale 1 ps / 1 ps

class AXI4Slave #(
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

typedef struct {
  bit [ADDR_WIDTH - 1 : 0] start_addr;
  bit [7 : 0]              wr_data [$];
} wr_tran_t;

typedef struct {
  bit [ADDR_WIDTH - 1 : 0] start_addr;
  int                      words_amount;
} rd_tran_t;

bit [7 : 0] memory [*];
bit         running;

event wr_transaction_start;
event wr_transaction_end;
event rd_transaction_start;
event rd_transaction_end;

mailbox rd_tran_mbx;
mailbox wr_tran_mbx;

virtual axi4_if #(
  .DATA_WIDTH   ( DATA_WIDTH   ),
  .ADDR_WIDTH   ( ADDR_WIDTH   ),
  .ID_WIDTH     ( ID_WIDTH     ),
  .AWUSER_WIDTH ( AWUSER_WIDTH ),
  .WUSER_WIDTH  ( WUSER_WIDTH  ),
  .BUSER_WIDTH  ( BUSER_WIDTH  ),
  .ARUSER_WIDTH ( ARUSER_WIDTH ),
  .RUSER_WIDTH  ( RUSER_WIDTH  )
) axi4_if_v;

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
  ) axi4_if_v,
  mailbox rd_tran_mbx = this.rd_tran_mbx,
  mailbox wr_tran_mbx = this.wr_tran_mbx
);

  this.axi4_if_v   = axi4_if_v;
  this.rd_tran_mbx = rd_tran_mbx;
  this.wr_tran_mbx = wr_tran_mbx;
  if( this.rd_tran_mbx == null )
    this.rd_tran_mbx = new();
  if( this.wr_tran_mbx == null )
    this.wr_tran_mbx = new();
  init_interface();

endfunction

local function automatic void init_interface();

  axi4_if_v.awready = 1'b1;
  axi4_if_v.wready  = 1'b0;
  axi4_if_v.bid     = '0;
  axi4_if_v.bresp   = 2'b00;
  axi4_if_v.buser   = '0;
  axi4_if_v.bvalid  = 1'b0;
  axi4_if_v.arready = 1'b1;
  axi4_if_v.rid     = '0;
  axi4_if_v.rdata   = '0;
  axi4_if_v.rresp   = 2'b0;
  axi4_if_v.rlast   = 1'b0;
  axi4_if_v.ruser   = '0;
  axi4_if_v.rvalid  = 1'b0;
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

local task automatic run();

  if( ~running )
    begin
      running = 1'b1;
      if( VERBOSE > 0 )
        begin
          $display( "%0d", $time() );
          $display( "AXI4 Slave: interface listening is enabled." );
        end
      if( RANDOM_WREADY )
        axi4_if_v.wready = 1'b0;
      else
        axi4_if_v.wready = 1'b1;
      fork
        forever
          begin
            fork
              begin : wr_check
                if( axi4_if_v.awvalid )
                  wr_data();
                else
                  @( posedge axi4_if_v.aclk );
              end
              begin : rd_check
                if( axi4_if_v.arvalid )
                  rd_data();
                else
                  @( posedge axi4_if_v.aclk );
              end
            join
          end
      join_none
    end
  else
    if( VERBOSE > 0 )
      begin
        $display( "%0d", $time() );
        $display( "AXI4 Slave: interface listening is already enabled!" );
      end

endtask

local task automatic wr_data();

  bit                      wready;
  bit                      eot;
  bit [ADDR_WIDTH - 1 : 0] cur_addr = axi4_if_v.awaddr;
  bit [7:0]                awlen    = axi4_if_v.awlen;
  wr_tran_t      wr_tran;

  wr_tran.start_addr = axi4_if_v.awaddr;
  ->wr_transaction_start;
  if( VERBOSE > 1 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4 Slave: write transaction detected" );
    end
  do
    begin
      if( WATCHDOG_EN )
        watchdog( axi4_if_v.wvalid, "WVALID" );
      if( RANDOM_WREADY )
        wready = $urandom_range( 1 );
      else
        wready = 1'b1;
      axi4_if_v.wready <= wready;
      if( axi4_if_v.wvalid && axi4_if_v.wready )
        begin
          for( int i = 0; i < DATA_WIDTH_B; i++ )
            begin
              if( axi4_if_v.wstrb[i] )
                begin
                  wr_tran.wr_data.push_back( axi4_if_v.wdata[i * 8 + 7 -: 8] );
                  memory[cur_addr] = axi4_if_v.wdata[i * 8 + 7 -: 8];
                end
              cur_addr++;
            end
          if( VERBOSE > 2 )
            begin
              $display( "%0d", $time() );
              $display( "AXI4 Slave: %0h was written by master", axi4_if_v.wdata );
            end
          if( awlen == 0 || axi4_if_v.wlast )
            begin
              eot = 1'b1;
              wr_response();
              if( RANDOM_WREADY )
                axi4_if_v.wready <= 1'b0;
            end
          else
            awlen--;
        end
      @( posedge axi4_if_v.aclk );
    end
  while( ~eot );
  if( VERBOSE > 1 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4 Slave: write transaction has been ended" );
    end
  wr_tran_mbx.put( wr_tran );
  -> wr_transaction_end;

endtask

local task automatic wr_response();
  fork
    begin
      axi4_if_v.bvalid <= 1'b1;
      do
        @( posedge axi4_if_v.aclk );
      while( ~axi4_if_v.bready );
      axi4_if_v.bvalid <= 1'b0;
    end
  join_none

endtask

local task automatic rd_data();

  bit                      rvalid;
  bit [8 : 0]              arlen    = axi4_if_v.arlen + 1'b1;
  bit [ADDR_WIDTH - 1 : 0] cur_addr = axi4_if_v.araddr;
  rd_tran_t      rd_tran;

  rd_tran.start_addr   = axi4_if_v.araddr;
  rd_tran.words_amount = arlen;
  rd_tran_mbx.put( rd_tran );
  -> rd_transaction_start;
  if( VERBOSE > 1 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4 Slave: read transaction detected" );
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
            @( posedge axi4_if_v.aclk );
        end
      axi4_if_v.rvalid <= 1'b1;
      for( int i = 0; i < DATA_WIDTH_B; i++ )
        begin
          if( memory.exists( cur_addr ) )
            axi4_if_v.rdata[i * 8 + 7 -: 8] <= memory[cur_addr];
          else
            axi4_if_v.rdata[i * 8 + 7 -: 8] <= 8'b0;
          cur_addr++;
        end
      if( arlen == 9'd1 )
        axi4_if_v.rlast <= 1'b1;
      if( WATCHDOG_EN )
        watchdog( axi4_if_v.rready, "RREADY" );
      do
        @( posedge axi4_if_v.aclk );
      while( ~axi4_if_v.rready );
      if( VERBOSE > 2 )
        begin
          $display( "%0d", $time() );
          $display( "AXI4 Slave: %0h was read by master", axi4_if_v.rdata );
        end
      arlen--;
      axi4_if_v.rvalid <= 1'b0;
    end
  axi4_if_v.rdata <= '0;
  axi4_if_v.rlast <= 1'b0;
  if( VERBOSE > 1 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4 Slave: read transaction has been ended" );
    end
  ->rd_transaction_end;

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
        @( posedge axi4_if_v.aclk );
        watchdog_cnt++;
      end
  join_none

endtask

endclass
