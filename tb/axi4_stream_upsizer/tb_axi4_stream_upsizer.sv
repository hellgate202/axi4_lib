`include "../../src/class/AXI4StreamMaster.sv"
`include "../../src/class/AXI4StreamSlave.sv"

`timescale 1 ps / 1 ps

module tb_axi4_stream_upsizer;

parameter int RX_TDATA_WIDTH  = 16;
parameter int TX_TDATA_WIDTH  = 64;
parameter int TID_WIDTH       = 1;
parameter int TDEST_WIDTH     = 1;
parameter int TUSER_WIDTH     = 1;
parameter int RANDOM_TVALID   = 1;
parameter int RANDOM_TREADY   = 1;
parameter int VERBOSE         = 0;

parameter int PKTS_AMOUNT     = 1000;
parameter int MIN_PKT_SIZE    = 1;
parameter int MAX_PKT_SIZE    = ( RX_TDATA_WIDTH / 8 ) * 3;

parameter int CLK_T           = 5000;

typedef bit [7 : 0] pkt_q [$];

bit   clk;
bit   rst;
pkt_q tx_pkt;

mailbox rx_data_mbx  = new();
mailbox ref_data_mbx = new();

axi4_stream_if #(
  .TDATA_WIDTH ( TX_TDATA_WIDTH ),
  .TID_WIDTH   ( TID_WIDTH      ),
  .TDEST_WIDTH ( TDEST_WIDTH    ),
  .TUSER_WIDTH ( TUSER_WIDTH    )
) tx_if (
  .aclk        ( clk            ),
  .aresetn     ( !rst           )
);

axi4_stream_if #(
  .TDATA_WIDTH ( RX_TDATA_WIDTH ),
  .TID_WIDTH   ( TID_WIDTH      ),
  .TDEST_WIDTH ( TDEST_WIDTH    ),
  .TUSER_WIDTH ( TUSER_WIDTH    )
) rx_if (
  .aclk        ( clk            ),
  .aresetn     ( !rst           )
);

AXI4StreamMaster #(
  .TDATA_WIDTH    ( RX_TDATA_WIDTH ),
  .TID_WIDTH      ( TID_WIDTH      ),
  .TDEST_WIDTH    ( TDEST_WIDTH    ),
  .TUSER_WIDTH    ( TUSER_WIDTH    ),
  .RANDOM_TVALID  ( RANDOM_TVALID  ),
  .VERBOSE        ( VERBOSE        ),
  .WATCHDOG_EN    ( 1'b1           ),
  .WATCHDOG_LIMIT ( 200            )
) pkt_sender;

AXI4StreamSlave #(
  .TDATA_WIDTH    ( TX_TDATA_WIDTH ),
  .TID_WIDTH      ( TID_WIDTH      ),
  .TDEST_WIDTH    ( TDEST_WIDTH    ),
  .TUSER_WIDTH    ( TUSER_WIDTH    ),
  .RANDOM_TREADY  ( RANDOM_TREADY  ),
  .VERBOSE        ( VERBOSE        ),
  .WATCHDOG_EN    ( 1'b1           ),
  .WATCHDOG_LIMIT ( 200            )
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

function automatic pkt_q generate_pkt( int size ); 

  pkt_q pkt;

  for( int i = 0; i < size; i++ )
    pkt.push_back( $urandom_range( 255, 0 ) );

  return pkt;

endfunction

task automatic run_checker();
  
  pkt_q rx_pkt;
  pkt_q ref_pkt;

  forever
    begin
      if( rx_data_mbx.num() > 0 && ref_data_mbx.num() > 0 )
        begin
          rx_data_mbx.get( rx_pkt );
          ref_data_mbx.get( ref_pkt );
          if( rx_pkt != ref_pkt )
            begin
              $display( "Packet missmatch!" );
              $display( "Received packet:" );
              for( int i = 0; i < rx_pkt.size(); i++ )
                $write( "%0h ", rx_pkt[i] );
              $write( "\n" );
              $display( "Reference packet:" );
              for( int i = 0; i < ref_pkt.size(); i++ )
                $write( "%0h ", ref_pkt[i] );
              $write( "\n" );
              $stop();
            end
        end
      else
        @( posedge clk );
    end

endtask

axi4_stream_upsizer #(
  .RX_TDATA_WIDTH  ( RX_TDATA_WIDTH ),
  .TX_TDATA_WIDTH  ( TX_TDATA_WIDTH ),
  .TID_WIDTH       ( TID_WIDTH      ),
  .TDEST_WIDTH     ( TDEST_WIDTH    ),
  .TUSER_WIDTH     ( TUSER_WIDTH    )
) DUT (
  .clk_i           ( clk            ),
  .rst_i           ( rst            ),
  .pkt_i           ( rx_if          ),
  .pkt_o           ( tx_if          )
);

initial
  begin
    pkt_sender   = new( .axi4_stream_if_v ( rx_if ) );
    pkt_receiver = new( .axi4_stream_if_v ( tx_if       ),
                        .rx_data_mbx      ( rx_data_mbx ) );
    fork
      clk_gen();
      run_checker();
    join_none
    apply_rst();
    @( posedge clk );
    for( int i = 1; i < PKTS_AMOUNT; i++ )
      begin
        tx_pkt = generate_pkt( i );
        ref_data_mbx.put( tx_pkt );
        pkt_sender.tx_data( tx_pkt );
      end
    repeat( 10 )
      @( posedge clk );
    $display( "Everthing is fine." );
    $stop();
  end

endmodule
