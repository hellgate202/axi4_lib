class AXI4Master #(
  parameter int DATA_WIDTH     = 32,
  parameter int ADDR_WIDTH     = 16,
  parameter int ID_WIDTH       = 4,
  parameter int AWUSER_WIDTH   = 1,
  parameter int WUSER_WIDTH    = 1,
  parameter int BUSER_WIDTH    = 1,
  parameter int ARUSER_WIDTH   = 1,
  parameter int RUSER_WIDTH    = 1,
  
  parameter int RANDOM_WVALID  = 0,
  parameter int RANDOM_RREADY  = 0,
  parameter int VERBOSE        = 0,
  parameter int WATCHDOG_EN    = 1,
  parameter int WATCHDOG_LIMIT = 100
);

localparam DATA_WIDTH_B   = DATA_WIDTH / 8;
localparam ADDR_WORD_BITS = $clog2( DATA_WIDTH_B );

typedef struct{
  bit [ADDR_WIDTH - 1 : 0] start_addr;
  bit [7 : 0]              wr_byte_q [$];
} wr_req_t;

typedef struct packed{
  bit [DATA_WIDTH - 1 : 0]   wdata;
  bit [DATA_WIDTH_B - 1 : 0] wstrb;
} wr_transfer_t;

typedef struct{
  bit [ADDR_WIDTH - 1 :0] start_addr;
  wr_transfer_t           wr_transfer_q [$];
} wr_burst_t;

typedef wr_burst_t wr_transaction_t [$];

typedef struct packed {
  bit [ADDR_WIDTH - 1 : 0] start_addr;
  int                      words_amount;
} rd_req_t;

typedef rd_req_t rd_transaction_t [$];

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

mailbox wr_mbx = new();
mailbox rd_mbx = new();

mailbox rd_data_mbx;

event   wr_transaction_start;
event   wr_transaction_end;
event   rd_transaction_start;
event   rd_transaction_end;

bit     running;
bit     wr_in_progress;
bit     rd_in_progress;

wr_req_t wr_req;
rd_req_t rd_req;

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
  mailbox rd_data_mbx
);

  this.axi4_if_v    = axi4_if_v;
  this.rd_data_mbx  = rd_data_mbx;
  init_interface();

endfunction

local function automatic void init_interface();

  axi4_if_v.awid     = '0;
  axi4_if_v.awaddr   = '0;
  axi4_if_v.awlen    = 8'b0;
  axi4_if_v.awsize   = $clog2( DATA_WIDTH_B );
  axi4_if_v.awburst  = 2'b01;
  axi4_if_v.awlock   = 1'b0;
  axi4_if_v.awcache  = 4'b0;
  axi4_if_v.awprot   = 3'b0;
  axi4_if_v.awqos    = 4'b0;
  axi4_if_v.awregion = 4'b0;
  axi4_if_v.awuser   = '0;
  axi4_if_v.awvalid  = 1'b0;
  axi4_if_v.wdata    = '0;
  axi4_if_v.wstrb    = '0;
  axi4_if_v.wlast    = 1'b0;
  axi4_if_v.wuser    = '0;
  axi4_if_v.wvalid   = 1'b0;
  axi4_if_v.bready   = 1'b1;
  axi4_if_v.arid     = '0;
  axi4_if_v.araddr   = '0;
  axi4_if_v.arlen    = 8'b0;
  axi4_if_v.arsize   = $clog2( DATA_WIDTH_B );
  axi4_if_v.arburst  = 2'b01;
  axi4_if_v.arlock   = 1'b0;
  axi4_if_v.arcache  = 4'b0;
  axi4_if_v.arprot   = 3'b0;
  axi4_if_v.arqos    = 4'b0;
  axi4_if_v.arregion = 4'b0;
  axi4_if_v.aruser   = '0;
  axi4_if_v.arvalid  = 1'b0;
  axi4_if_v.rready   = 1'b1;
  fork
    run();
  join_none

endfunction

function automatic void wr_transaction_byte(
  input bit [ADDR_WIDTH - 1 : 0] start_addr = '0,
  ref   bit [7 : 0]              wr_byte_q [$]
);

  wr_req_t wr_req;

  wr_req.start_addr = start_addr;
  wr_req.wr_byte_q  = wr_byte_q;
  void'( wr_mbx.try_put( wr_req ) );

endfunction

function automatic void wr_transaction_word(
  input bit [ADDR_WIDTH - 1 : 0] start_addr = '0,
  ref   bit [DATA_WIDTH - 1 : 0] wr_word_q [$]
);

  bit [DATA_WIDTH - 1 : 0] wr_data;
  bit [7 : 0]              wr_byte_q [$];

  while( wr_word_q.size() )
    begin
      wr_data = wr_word_q.pop_front();
      for( int i = 0; i < DATA_WIDTH_B; i++ )
        wr_byte_q.push_back( wr_data[i * 8 + 7 -: 8] );
    end
  wr_transaction_byte( .start_addr ( start_addr ),
                       .wr_byte_q  ( wr_byte_q  )
                     );

endfunction

function automatic void rd_transaction(
  input bit [ADDR_WIDTH - 1 : 0] start_addr   = '0,
  input int                      words_amount = 0
);

  rd_req_t rd_req;

  rd_req.start_addr   = start_addr;
  rd_req.words_amount = words_amount;
  void'( rd_mbx.try_put( rd_req ) );

endfunction

task automatic run();

  if( ~running )
    begin
      running = 1'b1;
      if( RANDOM_RREADY )
        axi4_if_v.rready = 1'b0;
      else
        axi4_if_v.rready = 1'b1;
      if( VERBOSE > 0 )
        begin
          $display( "%0d", $time() );
          $display( "AXI4 Master: mailbox scanning has been started." );
        end
      fork
        forever
          begin
            fork
              begin : wr_check
                if( wr_mbx.num() > 0 && ~wr_in_progress )
                  begin
                    if( VERBOSE > 1 )
                      begin
                        $display( "%0d", $time() );
                        $display( "AXI4 Master: new write transaction detected!" );
                      end
                    wr_mbx.get( wr_req );
                    wr_data( wr_req );
                  end
                else
                  @( posedge axi4_if_v.aclk );
              end
              begin : rd_check
                if( rd_mbx.num() > 0 && ~rd_in_progress )
                  begin
                    if( VERBOSE > 1 )
                      begin
                        $display( "%0d", $time() );
                        $display( "AXI4 Master: new read transaction detected" );
                      end
                    rd_mbx.get( rd_req );
                    rd_data( rd_req );
                  end
                else
                  @( posedge axi4_if_v.aclk );
              end
            join
            if( ~running )
              begin
                if( VERBOSE > 0 )
                  begin
                    $display( "%0d", $time() );
                    $display( "AXI4 Master: mailbox scanning has been stopped." );
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
        $display( "AXI4 Master: mailbox scanning is already running!" );
      end

endtask

local task automatic wr_data(
  ref wr_req_t wr_req
);

  wr_transaction_t cur_transaction;
  wr_burst_t       cur_burst;
  wr_transfer_t    cur_transfer;
  bit [7 : 0]      awlen;
  bit              wvalid;

  ->wr_transaction_start;
  wr_in_progress  = 1'b1;
  cur_transaction = prep_wr_transaction( wr_req );
  if( VERBOSE > 1 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4 Master: current write transaction was splitted in %0d bursts.", cur_transaction.size() );
    end
  while( cur_transaction.size() )
    begin
      cur_burst = cur_transaction.pop_front();
      awlen     = cur_burst.wr_transfer_q.size() - 1;
      if( VERBOSE > 1 )
        begin
          $display( "%0d", $time() );
          $display( "AXI4 Master: starting write burst of size %0d transfers.", cur_burst.wr_transfer_q.size() );
        end
      fork
        begin : aw_channel
          axi4_if_v.awvalid <= 1'b1;
          axi4_if_v.awaddr  <= cur_burst.start_addr;
          axi4_if_v.awlen   <= awlen;
          if( WATCHDOG_EN )
            watchdog( axi4_if_v.awready, "AWREADY" );
          do
            @( posedge axi4_if_v.aclk );
          while( ~axi4_if_v.awready );
          if( VERBOSE > 2 )
            begin
              $display( "%0d", $time() );
              $display( "AXI4 Master: write burst with start address %0h was acknowledged by slave.", axi4_if_v.awaddr );
            end
          axi4_if_v.awvalid <= 1'b0;
          axi4_if_v.awaddr  <= '0;
          axi4_if_v.awlen   <= '0;
        end
        begin : w_channel
          while( cur_burst.wr_transfer_q.size() )
            begin
              cur_transfer = cur_burst.wr_transfer_q.pop_front();
              if( RANDOM_WVALID )
                wvalid = 1'b0;
              else
                wvalid = 1'b1;
              while( ~wvalid )
                begin
                  wvalid = $urandom_range( 1 );
                  if( ~wvalid )
                    @( posedge axi4_if_v.aclk );
                end
              axi4_if_v.wvalid <= 1'b1;
              axi4_if_v.wdata  <= cur_transfer.wdata;
              axi4_if_v.wstrb  <= cur_transfer.wstrb;
              if( cur_burst.wr_transfer_q.size() )
                axi4_if_v.wlast <= 1'b0;
              else
                axi4_if_v.wlast <= 1'b1;
              if( WATCHDOG_EN )
                watchdog( axi4_if_v.wready, "WREADY" );
              do
                @( posedge axi4_if_v.aclk );
              while( ~axi4_if_v.wready );
              if( VERBOSE > 2 )
                begin
                  $display( "%0d", $time() );
                  $display( "AXI4 Master: %0h was written to slave.", axi4_if_v.wdata );
                end
              axi4_if_v.wvalid <= 1'b0;
            end
          axi4_if_v.wdata  <= '0;
          axi4_if_v.wstrb  <= '0;
          axi4_if_v.wlast  <= 1'b0;
          if( VERBOSE > 1 )
            begin
              $display( "%0d", $time() );
              $display( "AXI4 Master: write burst has been ended." );
            end
        end
      join
    end
  wr_in_progress = 1'b0;
  ->wr_transaction_end;

endtask

local function automatic wr_transaction_t prep_wr_transaction(
  ref wr_req_t wr_req
);

  wr_burst_t       cur_burst;
  wr_transaction_t cur_transaction;
  while( wr_req.wr_byte_q.size() )
    begin
      cur_burst = prep_wr_burst( wr_req );
      cur_transaction.push_back( cur_burst );
    end

  return cur_transaction;

endfunction

local function automatic wr_burst_t prep_wr_burst(
  ref wr_req_t wr_req
);

  wr_transfer_t            cur_transfer;
  wr_burst_t               cur_burst;
  bit [ADDR_WIDTH - 1 : 0] cur_addr;
  int                      word_cnt;

  cur_addr                         = wr_req.start_addr;
  cur_addr[ADDR_WORD_BITS - 1 : 0] = '0;
  cur_burst.start_addr             = cur_addr;
  while( word_cnt < 256 && wr_req.wr_byte_q.size() != 0 )
    begin
      for( int i = 0; i < DATA_WIDTH_B; i++ )
        begin
          if( cur_addr >= wr_req.start_addr && 
              wr_req.wr_byte_q.size() )
            begin
              cur_transfer.wdata[i * 8 + 7 -: 8] = wr_req.wr_byte_q.pop_front();
              cur_transfer.wstrb[i]              = 1'b1;
            end
          else
            begin
              cur_transfer.wdata[i * 8 + 7 -: 8] = 8'b0;
              cur_transfer.wstrb[i]              = 1'b0;
            end
          cur_addr++;
        end
      cur_burst.wr_transfer_q.push_back( cur_transfer );
      word_cnt++;
    end
  wr_req.start_addr = cur_addr;

  return cur_burst;

endfunction

local task automatic rd_data(
  ref rd_req_t rd_req
);

  rd_transaction_t         cur_transaction;
  rd_req_t                 cur_burst;
  bit [7 : 0]              arlen;
  bit                      rready;
  bit                      eot;
  bit [DATA_WIDTH - 1 : 0] rd_data_q [$];

  ->rd_transaction_start;
  rd_in_progress = 1'b1;
  cur_transaction = prep_rd_transaction( rd_req );
  if( VERBOSE > 1 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4 Master: current write transaction was splitted in %0d bursts", cur_transaction.size() );
    end
  while( cur_transaction.size() )
    begin
      cur_burst = cur_transaction.pop_front();
      arlen     = cur_burst.words_amount - 1;
      if( VERBOSE > 1 )
        begin
          $display( "%0d", $time() );
          $display( "AXI4 Master: starting read burst of size %0d transfers", cur_burst.words_amount );
        end
      fork
        begin : ar_channel
          axi4_if_v.arvalid <= 1'b1;
          axi4_if_v.araddr  <= cur_burst.start_addr;
          axi4_if_v.arlen   <= arlen;
          if( WATCHDOG_EN )
            watchdog( axi4_if_v.arready, "ARREADY" );
          do
            @( posedge axi4_if_v.aclk );
          while( ~axi4_if_v.arready );
          if( VERBOSE > 2 )
            begin
              $display( "%0d", $time() );
              $display( "AXI4 Master: read burst with start address %0h was acknoledged by slave.", axi4_if_v.araddr );
            end
          axi4_if_v.arvalid <= 1'b0;
          axi4_if_v.araddr  <= '0;
          axi4_if_v.arlen   <= '0;
        end
        begin : r_channel
          do
            begin
              if( WATCHDOG_EN )
                  watchdog( axi4_if_v.rvalid, "RVALID" );
              if( RANDOM_RREADY )
                rready = $urandom_range( 1 );
              else
                rready = 1'b1;
              axi4_if_v.rready <= rready;
              if( axi4_if_v.rvalid && axi4_if_v.rready )
                begin
                  rd_data_q.push_back( axi4_if_v.rdata );
                  if( VERBOSE > 2 )
                    begin
                      $display( "%0d", $time() );
                      $display( "AXI4 Master: %0h was read from slave.", axi4_if_v.rdata );
                    end
                  if( axi4_if_v.rlast || !cur_burst.words_amount )
                    begin
                      eot = 1'b1;
                      if( RANDOM_RREADY )
                        axi4_if_v.rready <= 1'b0;
                      else
                        cur_burst.words_amount--;
                    end
                end
              @( posedge axi4_if_v.aclk );
            end
          while( ~eot );
          eot = 1'b0;
          if( VERBOSE > 1 )
            begin
              $display( "%0d", $time() );
              $display( "AXI4 Master: read burst has been ended." );
            end
        end
      join
    end
  rd_in_progress = 1'b0;
  rd_data_mbx.put( rd_data_q );
  ->rd_transaction_end;

endtask

local function automatic rd_transaction_t prep_rd_transaction(
  ref rd_req_t rd_req
);

  rd_transaction_t         cur_transaction;
  rd_req_t                 cur_burst;
  bit [ADDR_WIDTH - 1 : 0] cur_addr;

  rd_req.start_addr[ADDR_WORD_BITS - 1 : 0] = '0;
  while( rd_req.words_amount )
    begin
      cur_burst.start_addr = rd_req.start_addr;
      if( rd_req.words_amount >= 256 )
        cur_burst.words_amount = 256;
      else
        cur_burst.words_amount = rd_req.words_amount;
      rd_req.words_amount = rd_req.words_amount - 
                            cur_burst.words_amount;
      rd_req.start_addr  = rd_req.start_addr + 
                           DATA_WIDTH_B * cur_burst.words_amount;
      cur_transaction.push_back( cur_burst );
    end

  return cur_transaction;

endfunction

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
