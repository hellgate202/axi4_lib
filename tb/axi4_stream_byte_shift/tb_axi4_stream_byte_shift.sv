`include "../../src/class/AXI4StreamMaster.sv"
`include "../../src/class/AXI4StreamSlave.sv"

`timescale 1 ps / 1 ps

module tb_axi4_stream_byte_shift;

parameter int TDATA_WIDTH     = 128;
parameter int TID_WIDTH       = 1;
parameter int TDEST_WIDTH     = 1;
parameter int TUSER_WIDTH     = 1;
parameter int RANDOM_TVALID   = 1;
parameter int RANDOM_TREADY   = 1;
parameter int VERBOSE         = 0;

parameter int MAX_PKT_SIZE_B  = 48;
parameter int MIN_PKT_SIZE_B  = 1;
parameter int PKTS_AMOUNT     = 1000;

parameter int CLK_T           = 5000;
parameter int TDATA_WIDTH_B   = TDATA_WIDTH / 8;
parameter int TDATA_WIDTH_B_W = $clog2( TDATA_WIDTH_B );

typedef bit [7 : 0] pkt_q [$];

bit                          clk;
bit                          rst;
bit [TDATA_WIDTH_B_W - 1 : 0] shift;

pkt_q                        tx_pkt;
pkt_q                        tx_pkt_pool[$];

mailbox rx_data_mbx  = new();
mailbox ref_data_mbx = new();

axi4_stream_if #(
  .TDATA_WIDTH ( TDATA_WIDTH ),
  .TID_WIDTH   ( TID_WIDTH   ),
  .TDEST_WIDTH ( TDEST_WIDTH ),
  .TUSER_WIDTH ( TUSER_WIDTH )
) tx_if (
  .aclk        ( clk         ),
  .aresetn     ( !rst        )
);

axi4_stream_if #(
  .TDATA_WIDTH ( TDATA_WIDTH ),
  .TID_WIDTH   ( TID_WIDTH   ),
  .TDEST_WIDTH ( TDEST_WIDTH ),
  .TUSER_WIDTH ( TUSER_WIDTH )
) rx_if (
  .aclk        ( clk         ),
  .aresetn     ( !rst        )
);

AXI4StreamMaster #(
  .TDATA_WIDTH   ( TDATA_WIDTH   ),
  .TID_WIDTH     ( TID_WIDTH     ),
  .TDEST_WIDTH   ( TDEST_WIDTH   ),
  .TUSER_WIDTH   ( TUSER_WIDTH   ),
  .RANDOM_TVALID ( RANDOM_TVALID ),
  .VERBOSE       ( VERBOSE       )
) pkt_sender;

AXI4StreamSlave #(
  .TDATA_WIDTH   ( TDATA_WIDTH   ),
  .TID_WIDTH     ( TID_WIDTH     ),
  .TDEST_WIDTH   ( TDEST_WIDTH   ),
  .TUSER_WIDTH   ( TUSER_WIDTH   ),
  .RANDOM_TREADY ( RANDOM_TREADY ),
  .VERBOSE       ( VERBOSE       )
) pkt_receiver;

task automatic clk_gen();

  forever
    begin
      #( CLK_T / 2 );
      clk = !clk;
    end

endtask

task automatic apply_rst();

  @( posedge clk );
  rst = 1'b1;
  @( posedge clk );
  rst = 1'b0;

endtask

task automatic check_pkts();

  pkt_q rx_pkt;

  forever
    begin
      if( rx_data_mbx.num() > 0 )
        begin
          rx_data_mbx.get( rx_pkt );
          for( int i = 0; i < tx_pkt_pool.size(); i++ )
            begin
              if( rx_pkt == tx_pkt_pool[i] )
                begin
                  tx_pkt_pool.delete( i );
                  break;
                end
              if( i == tx_pkt_pool.size() )
                begin
                  for( int j = 0; j < rx_pkt.size(); j++ )
                    begin
                      $write( "%0h ", rx_pkt[j] );
                      $write( "\n" );
                    end
                  $display( "Wasn't fount in tx_pkt_pool" );
                  $display( "tx_pkt_pool: " );
                  for( int j = 0; j < tx_pkt_pool.size(); j++ )
                    begin
                      $display( "%0d:", j );
                      for( int k = 0; k < tx_pkt_pool[j].size(); k++ )
                        begin
                          $write( "%0h ", tx_pkt_pool[j][k] );
                          $write( "\n" );
                        end
                    end
                  $stop();
                end
            end
        end
      else
        @( posedge clk );
    end

endtask

function automatic pkt_q generate_pkt( int size ); 

  pkt_q pkt;

  for( int i = 0; i < size; i++ )
    pkt.push_back( $urandom_range( 255, 0 ) );

  return pkt;

endfunction

axi4_stream_byte_shift #(
  .TDATA_WIDTH ( TDATA_WIDTH ),
  .TID_WIDTH   ( TID_WIDTH   ),
  .TDEST_WIDTH ( TDEST_WIDTH ),
  .TUSER_WIDTH ( TUSER_WIDTH )
) DUT (
  .clk_i       ( clk         ),
  .rst_i       ( rst         ),
  .shift_i     ( shift       ),
  .pkt_i       ( rx_if       ),
  .pkt_o       ( tx_if       )
);

initial
  begin
    pkt_sender   = new( .axi4_stream_if_v ( rx_if ) );
    pkt_receiver = new( .axi4_stream_if_v ( tx_if       ),
                        .rx_data_mbx      ( rx_data_mbx ) );
    fork
      clk_gen();
      check_pkts();
    join_none
    apply_rst();
    @( posedge clk );
    for( int i = 0; i < TDATA_WIDTH_B; i++ )
      begin
        shift = i;
        for( int i = 1; i < PKTS_AMOUNT; i++ )
          begin
            tx_pkt = generate_pkt( $urandom_range( MAX_PKT_SIZE_B, MIN_PKT_SIZE_B ) );
            tx_pkt_pool.push_back( tx_pkt );
            pkt_sender.tx_data( tx_pkt );
          end
      end
    repeat( 10 )
      @( posedge clk );
    if( tx_pkt_pool.size() == 0 && rx_data_mbx.num() == 0 )
      $display( "Everything is fine" );
    else
      begin
        $display( "Everything is not fine" );
        $display( "tx_pkt_pool: " );
        for( int j = 0; j < tx_pkt_pool.size(); j++ )
          begin
            $display( "%0d:", j );
            for( int k = 0; k < tx_pkt_pool[j].size(); k++ )
              $write( "%0h ", tx_pkt_pool[j][k] );
            $write( "\n" );
          end
      end
    $stop();
  end

endmodule
