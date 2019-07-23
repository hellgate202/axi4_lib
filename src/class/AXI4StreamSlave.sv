`timescale 1 ps / 1 ps

class AXI4StreamSlave #(
  parameter int DATA_WIDTH     = 32,
  parameter int ID_WIDTH       = 1,
  parameter int DEST_WIDTH     = 1,
  parameter int USER_WIDTH     = 1,

  parameter int RANDOM_TREADY  = 0,
  parameter int VERBOSE        = 0,
  parameter int WATCHDOG_EN    = 1,
  parameter int WATCHDOG_LIMIT = 100
);

localparam int DATA_WIDTH_B = DATA_WIDTH / 8;

virtual axi4_stream_if #(
  .DATA_WIDTH ( DATA_WIDTH  ),
  .ID_WIDTH   ( ID_WIDTH    ),
  .DEST_WIDTH ( DEST_WIDTH  ),
  .USER_WIDTH ( USER_WIDTH  )
) axi4_stream_if_v;

mailbox rx_data_mbx;

event pkt_start;
event pkt_end;

bit running;

function new(
  virtual axi4_stream_if #(
    .DATA_WIDTH ( DATA_WIDTH ),
    .ID_WIDTH   ( ID_WIDTH   ),
    .DEST_WIDTH ( DEST_WIDTH ),
    .USER_WIDTH ( USER_WIDTH )  
  ) axi4_stream_if_v,
  mailbox rx_data_mbx
);

  this.axi4_stream_if_v = axi4_stream_if_v;
  this.rx_data_mbx      = rx_data_mbx;
  init_interface();

endfunction

local function automatic void init_interface();

  axi4_stream_if_v.tready = 1'b0;
  fork
    run();
  join_none
endfunction

task automatic run();

  if( ~running )
    begin
      running = 1'b1;
      if( RANDOM_TREADY )
        axi4_stream_if_v.tready = 1'b0;
      else
        axi4_stream_if_v.tready = 1'b1;
      if( VERBOSE > 0 )
        begin
          $display( "%0d", $time() );
          $display( "AXI4-Stream Slave: interface listening is enabled." );
        end
      fork
        forever
          begin
            if( axi4_stream_if_v.tvalid )
              get_pkt();
            else
              @( posedge axi4_stream_if_v.aclk );
            if( ~running )
              begin
                if( VERBOSE > 0 )
                  begin
                    $display( "%0d", $time() );
                    $display( "AXI4-Stream Slave: interface listening is disabled." );
                  end
                axi4_stream_if_v.tready = 1'b0;
                break;
              end
          end
      join_none
    end
  else
    if( VERBOSE > 0 )
      begin
        $display( "%0d", $time() );
        $display( "AXI4-Stream Slave: interface listening is already enabled!" );
      end

endtask

task automatic stop();

  running = 1'b0;

endtask

local task automatic get_pkt();
 
  bit [7 : 0] rx_byte_q [$];
  bit         tready;
  bit         eop;

  ->pkt_start;
  if( VERBOSE > 1 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4-Stream Slave: started receiving a packet." );
    end
  do
    begin
      if( WATCHDOG_EN )
        watchdog( axi4_stream_if_v.tvalid, "TVALID" );
      if( RANDOM_TREADY )
        tready = $urandom_range( 1 );
      else
        tready = 1'b1;
      axi4_stream_if_v.tready <= tready;
      if( axi4_stream_if_v.tvalid && axi4_stream_if_v.tready )
        begin
          if( VERBOSE > 2 )
            begin
              $display( "%0d", $time() );
              $display( "AXI4-Stream Slave: %0h was received", axi4_stream_if_v.tdata );
            end
          for( int i = 0; i < DATA_WIDTH_B; i++ )
            if( axi4_stream_if_v.tstrb[i] && axi4_stream_if_v.tkeep[i] )
              rx_byte_q.push_back( axi4_stream_if_v.tdata[i * 8 + 7 -: 8] );
          if( axi4_stream_if_v.tlast )
            begin
              eop = 1'b1;
              if( RANDOM_TREADY )
                axi4_stream_if_v.tready <= 1'b0;
            end
        end
      @( posedge axi4_stream_if_v.aclk );
    end
  while( ~eop );
  rx_data_mbx.put( rx_byte_q );
  ->pkt_end;
  if( VERBOSE > 1 )
    begin
      $display( "%0d", $time() );
      $display( "AXI4-Stream Slave: ended receiving a packet." );
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
