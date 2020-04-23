`include "../../src/class/AXI4StreamMaster.sv"
`include "../../src/class/AXI4StreamSlave.sv"

`timescale 1 ps / 1 ps

module tb_axi4_stream_multiple_upsizer;

parameter int SLAVE_TDATA_WIDTH  = 16;
parameter int MASTER_TDATA_WIDTH = 64;
parameter int CLK_T              = 10_000;
parameter int RANDOM_TVALID      = 1;
parameter int RANDOM_TREADY      = 1;

bit clk;
bit rst;

mailbox rx_data_mbx  = new();
mailbox ref_data_mbx = new();

task automatic clk_gen();
  forever
    begin
      #( CLK_T / 2 );
      clk = !clk;
    end
endtask

task automatic apply_rst();

  @( posedge clk );
  rst <= 1'b1;
  @( posedge clk );
  rst <= 1'b0;
  @( posedge clk );

endtask

task automatic send_pkt( int size );

bit [7 : 0] byte_q [$];

for( int i = 0; i < size; i++ )
  byte_q.push_back( $urandom_range( 255 ) );
ref_data_mbx.put( byte_q );
pkt_sender.tx_data( byte_q );

endtask

task automatic check_data();

bit [7 : 0] rx_data [$];
bit [7 : 0] ref_data [$];

forever
  begin
    if( rx_data_mbx.num() > 0 )
      begin
        rx_data_mbx.get( rx_data );
        ref_data_mbx.get( ref_data );
        if( rx_data != ref_data )
          begin
            $display( "Packet missmatch" );
            $display( "Should: " );
            while( ref_data.size() )
              $write( "0x%0h ", ref_data.pop_front() );
            $write( "\n" );
            $display( "Was: " );
            while( rx_data.size() )
              $write( "0x%0h ", rx_data.pop_front() );
            $write( "\n" );
            $stop();
          end
      end
    else
      @( posedge clk );
  end

endtask

axi4_stream_if #(
  .TDATA_WIDTH ( SLAVE_TDATA_WIDTH ),
  .TDEST_WIDTH ( 1                 ),
  .TID_WIDTH   ( 1                 ),
  .TUSER_WIDTH ( 1                 )
) pkt_i (
  .aclk        ( clk               ),
  .aresetn     ( !rst              )
);

AXI4StreamMaster #(
  .TDATA_WIDTH   ( SLAVE_TDATA_WIDTH ),
  .TID_WIDTH     ( 1                 ),
  .TDEST_WIDTH   ( 1                 ),
  .TUSER_WIDTH   ( 1                 ),
  .RANDOM_TVALID ( RANDOM_TVALID     )
) pkt_sender;

axi4_stream_if #(
  .TDATA_WIDTH ( MASTER_TDATA_WIDTH ),
  .TDEST_WIDTH ( 1                  ),
  .TID_WIDTH   ( 1                  ),
  .TUSER_WIDTH ( 1                  )
) pkt_o (
  .aclk        ( clk                ),
  .aresetn     ( !rst               )
);

AXI4StreamSlave #(
  .TDATA_WIDTH   ( MASTER_TDATA_WIDTH ),
  .TID_WIDTH     ( 1                  ),
  .TDEST_WIDTH   ( 1                  ),
  .TUSER_WIDTH   ( 1                  ),
  .RANDOM_TREADY ( RANDOM_TREADY      )
) pkt_receiver;

axi4_stream_multiple_upsizer #(
  .SLAVE_TDATA_WIDTH  ( SLAVE_TDATA_WIDTH  ),
  .MASTER_TDATA_WIDTH ( MASTER_TDATA_WIDTH )
) DUT (
  .clk_i              ( clk                ),
  .rst_i              ( rst                ),
  .pkt_i              ( pkt_i              ),
  .pkt_o              ( pkt_o              )
);

initial
  begin
    pkt_sender   = new( pkt_i );
    pkt_receiver = new( pkt_o, rx_data_mbx );
    fork
      clk_gen();
      check_data();
    join_none
    apply_rst();
    repeat( 100000 )
      send_pkt( $urandom_range( 100, 1 ) );
    repeat( 1000 )
      @( posedge clk );
    $display( "Everything is fine." );
    $stop();
  end

endmodule
