`timescale 1 ps / 1 ps

class AXI4StreamMaster #(
  parameter int DATA_WIDTH     = 32,
  parameter int ID_WIDTH       = 1,
  parameter int DEST_WIDTH     = 1,
  parameter int USER_WIDTH     = 1,

  parameter int RANDOM_TVALID  = 0,
  parameter int VERBOSE        = 0,
  parameter int WATCHDOG_EN    = 1,
  parameter int WATCHDOG_LIMIT = 100
);

localparam int DATA_WIDTH_B = DATA_WIDTH / 8;

virtual axi4_stream_if #(
  .DATA_WIDTH ( DATA_WIDTH ),
  .ID_WIDTH   ( ID_WIDTH   ),
  .DEST_WIDTH ( DEST_WIDTH ),
  .USER_WIDTH ( USER_WIDTH )
) axi4_stream_if_v;

mailbox tx_mbx = new();

event pkt_start;
event pkt_end;

semaphore bus_busy = new(1);

bit [7 : 0] tx_byte_q [$];
bit         running;

function new(
  virtual axi4_stream_if #(
    .DATA_WIDTH ( DATA_WIDTH ),
    .ID_WIDTH   ( ID_WIDTH   ),
    .DEST_WIDTH ( DEST_WIDTH ),
    .USER_WIDTH ( USER_WIDTH )  
  ) axi4_stream_if_v
);

  this.axi4_stream_if_v = axi4_stream_if_v;
  init_interface();

endfunction

local function automatic void init_interface();

  axi4_stream_if_v.tdata  = '0;
  axi4_stream_if_v.tstrb  = '0;
  axi4_stream_if_v.tkeep  = '0;
  axi4_stream_if_v.tlast  = '0;
  axi4_stream_if_v.tid    = '0;
  axi4_stream_if_v.tdest  = '0;
  axi4_stream_if_v.tuser  = '0;
  axi4_stream_if_v.tvalid = '0;
  fork
    run();
  join_none

endfunction

function automatic void send_pkt(
  ref bit [7 : 0] tx_byte_q [$]
);

  void'( tx_mbx.try_put( tx_byte_q ) );

endfunction

task automatic run();

  if( ~running )
    begin
      running = 1'b1;
      if( VERBOSE > 0 )
        begin
          $display( "%0d", $time() );
          $display( "AXI4-Stream Master: mailbox scanning has been started." );
        end
      fork
        forever
          begin
            if( tx_mbx.num() > 0 )
              begin
                if( VERBOSE > 1 )
                  begin
                    $display( "%0d", $time() );
                    $display( "AXI4-Stream Master: new packet found in mailbox!" );
                  end
                tx_mbx.get( tx_byte_q );
                tx_data( tx_byte_q );
              end
            else
              @( posedge axi4_stream_if_v.aclk );
            if( ~running )
              begin
                if( VERBOSE > 0 )
                  begin
                    $display( "%0d", $time() );
                    $display( "AXI4-Stream Master: mailbox scanning has been stopped." );
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
        $display( "AXI4-Stream Master: mailbox scanning is already running!" );
      end

endtask

task automatic stop();

  running = 1'b0;

endtask

task automatic tx_data(
  ref bit [7 : 0] tx_byte_q [$],
  input bit       tuser_sof = 0
);

  bit tvalid;

  bus_busy.get();
  ->pkt_start;
  if( tuser_sof )
    fork
      begin
        while( !tvalid )
          @( posedge axi4_stream_if_v.aclk );
        axi4_stream_if_v.tuser <= 1'b1;
        do
          @( posedge axi4_stream_if_v.aclk );
        while( !axi4_stream_if_v.tready );
        axi4_stream_if_v.tuser <= 1'b0;
      end
    join_none
  if( VERBOSE > 1 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4-Stream Master: started transmitting a packet." );
    end
  while( tx_byte_q.size() > 0 )
    begin
      if( RANDOM_TVALID )
        tvalid = $urandom_range( 1 );
      else
        tvalid = 1'b1;
      axi4_stream_if_v.tvalid <= tvalid;
      if( tvalid )
        begin
          for( int i = 0; i < DATA_WIDTH_B; i++ )
            if( tx_byte_q.size() > 0 )
              begin
                axi4_stream_if_v.tdata[i * 8 + 7 -: 8] <= tx_byte_q.pop_front();
                axi4_stream_if_v.tstrb[i]              <= 1'b1;
                axi4_stream_if_v.tkeep[i]              <= 1'b1;
              end
            else
              begin
                axi4_stream_if_v.tdata[i * 8 + 7 -: 8] <= '0;
                axi4_stream_if_v.tstrb[i]              <= 1'b0;
                axi4_stream_if_v.tkeep[i]              <= 1'b0;
              end
          if( tx_byte_q.size() == 0 )
            axi4_stream_if_v.tlast <= 1'b1;
          if( WATCHDOG_EN )
            watchdog( axi4_stream_if_v.tready, "TREADY" );
          do
            @( posedge axi4_stream_if_v.aclk );
          while( ~axi4_stream_if_v.tready );
          if( VERBOSE > 2 )
            begin
              $display( "%0d", $time() );
              $display( "AXI4-Stream Master: %0h was transmitted", axi4_stream_if_v.tdata );
            end
        end
      else
        @( posedge axi4_stream_if_v.aclk );
    end
    axi4_stream_if_v.tvalid <= 1'b0;
    axi4_stream_if_v.tuser  <= '0;
    axi4_stream_if_v.tdata  <= '0;
    axi4_stream_if_v.tstrb  <= '0;
    axi4_stream_if_v.tkeep  <= '0;
    axi4_stream_if_v.tlast  <= 1'b0;
    bus_busy.put();
    ->pkt_end;
    if( VERBOSE > 1 )
      begin
        $display( "%0d", $time() );
        $display( "AXI4-Stream Master: ended transmitting a packet." );
      end

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
        @( posedge axi4_stream_if_v.aclk );
        watchdog_cnt++;
      end
  join_none

endtask

endclass
