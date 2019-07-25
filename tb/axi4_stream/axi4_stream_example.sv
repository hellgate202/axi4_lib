`include "../../src/class/AXI4StreamMaster.sv"
`include "../../src/class/AXI4StreamSlave.sv"

`timescale 1 ps / 1 ps

module axi4_stream_example;

parameter int DATA_WIDTH        = 32;
parameter int ID_WIDTH          = 8;
parameter int DEST_WIDTH        = 4;
parameter int USER_WIDTH        = 1;
parameter int RANDOM_TVALID     = 1;
parameter int RANDOM_TREADY     = 1;
parameter int CLK_T             = 8000;
parameter int VERBOSE           = 3;
parameter int DISCONNECT_TREADY = 0;

parameter int PKTS_AMOUNT       = 100;
parameter int PKT_SIZE_MIN      = 1;
parameter int PKT_SIZE_MAX      = 1000;

bit clk;
bit rst;

int pkt_size;

typedef bit [7 : 0] pkt_q [$];

pkt_q tx_q [$];
pkt_q rx_q [$];

pkt_q pkt;

mailbox rx_data_mbx = new();

axi4_stream_if #(
  .DATA_WIDTH  ( DATA_WIDTH ),
  .ID_WIDTH    ( ID_WIDTH   ),
  .DEST_WIDTH  ( DEST_WIDTH ),
  .USER_WIDTH  ( USER_WIDTH )
) dut_if (
  .aclk        ( clk        ),
  .aresetn     ( ~rst       )
);

AXI4StreamMaster #(
  .DATA_WIDTH    ( DATA_WIDTH    ),
  .ID_WIDTH      ( ID_WIDTH      ),
  .DEST_WIDTH    ( DEST_WIDTH    ),
  .USER_WIDTH    ( USER_WIDTH    ),
  .RANDOM_TVALID ( RANDOM_TVALID ),
  .VERBOSE       ( VERBOSE       )
) master;

AXI4StreamSlave #(
  .DATA_WIDTH        ( DATA_WIDTH        ),
  .ID_WIDTH          ( ID_WIDTH          ),
  .DEST_WIDTH        ( DEST_WIDTH        ),
  .USER_WIDTH        ( USER_WIDTH        ),
  .RANDOM_TREADY     ( RANDOM_TREADY     ),
  .VERBOSE           ( VERBOSE           ),
  .DISCONNECT_TREADY ( DISCONNECT_TREADY )
) slave;

task automatic clk_gen();

  forever
    begin
      #( CLK_T / 2 );
      clk = ~clk;
    end

endtask

function automatic pkt_q generate_pkt( int size ); 

  pkt_q pkt;

  for( int i = 0; i < size; i++ )
    pkt.push_back( $urandom_range( 255, 0 ) );

  return pkt;

endfunction

initial
  begin
    master = new( .axi4_stream_if_v ( dut_if ) );
    slave  = new( .axi4_stream_if_v ( dut_if      ),
                  .rx_data_mbx      ( rx_data_mbx ) );
    fork
      clk_gen();
    join_none
    rst = 1'b0;
    @( posedge clk );
    // If you want precision control over time between packets
    // you can use tx_data() method and then wait for
    // pkt_end event. At this point if you use this method again
    // next packet will be sent right after previous packet
    // You must use wait() becuse event triggers before task exits
    // but in the same timeslot
    repeat( PKTS_AMOUNT )
      begin
        pkt_size = $urandom_range( PKT_SIZE_MAX,
                                   PKT_SIZE_MIN );
        pkt      = generate_pkt( pkt_size );
        tx_q.push_back( pkt );
        master.tx_data( pkt ); 
        wait( master.pkt_end.triggered );
      end
    @( slave.pkt_end );
    // This is non-blocking variant of method mentioned above
    // the only drawback that there will be one tick pause between
    // packets if you orienting by pkt_end event
    repeat( PKTS_AMOUNT )
      begin
        pkt_size = $urandom_range( PKT_SIZE_MAX,
                                   PKT_SIZE_MIN );
        pkt      = generate_pkt( pkt_size );
        tx_q.push_back( pkt );
        master.send_pkt( pkt );
        @( master.pkt_end );
      end
    @( slave.pkt_end );
    // And the easy way. Just use send_pkt() before pkt_end() event
    // and next packet will be immediatly sent
    repeat( PKTS_AMOUNT )
      begin 
        pkt_size = $urandom_range( PKT_SIZE_MAX,
                                   PKT_SIZE_MIN );
        pkt      = generate_pkt( pkt_size );
        tx_q.push_back( pkt );
        master.send_pkt( pkt );
      end
    repeat( PKTS_AMOUNT )
      @( slave.pkt_end );
    while( rx_data_mbx.num() > 0 )
      begin
        rx_data_mbx.get( pkt );
        rx_q.push_back( pkt );
      end
    if( tx_q == rx_q )
      $display( "Everything is fine." );
    else
      begin
        $display( "Everything is NOT fine." );
        $stop();
      end
    tx_q.delete();
    rx_q.delete();
    @( posedge clk );
    $stop();
  end

endmodule
