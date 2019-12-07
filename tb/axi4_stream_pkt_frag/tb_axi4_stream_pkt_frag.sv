`include "../../src/class/AXI4StreamMaster.sv"
`include "../../src/class/AXI4StreamSlave.sv"

`timescale 1 ps / 1 ps

module tb_axi4_stream_pkt_frag;

parameter int DATA_WIDTH     = 64;
parameter int ID_WIDTH       = 1;
parameter int DEST_WIDTH     = 1;
parameter int USER_WIDTH     = 1;
parameter int RANDOM_TVALID  = 1;
parameter int RANDOM_TREADY  = 1;
parameter int VERBOSE        = 0;

parameter int MAX_PKT_SIZE_B = 64;
parameter int PKT_SIZE_WIDTH = $clog2( MAX_PKT_SIZE_B );

parameter int CLK_T          = 5000;
parameter int DATA_WIDTH_B   = DATA_WIDTH / 8;

typedef bit [7 : 0] pkt_q [$];

bit                      clk;
bit                      rst;
bit [PKT_SIZE_WIDTH : 0] max_frag_size;

pkt_q                    tx_pkt;

mailbox rx_data_mbx  = new();
mailbox ref_data_mbx = new();

axi4_stream_if #(
  .DATA_WIDTH  ( DATA_WIDTH ),
  .ID_WIDTH    ( ID_WIDTH   ),
  .DEST_WIDTH  ( DEST_WIDTH ),
  .USER_WIDTH  ( USER_WIDTH )
) tx_if (
  .aclk        ( clk        ),
  .aresetn     ( !rst       )
);

axi4_stream_if #(
  .DATA_WIDTH  ( DATA_WIDTH ),
  .ID_WIDTH    ( ID_WIDTH   ),
  .DEST_WIDTH  ( DEST_WIDTH ),
  .USER_WIDTH  ( USER_WIDTH )
) rx_if (
  .aclk        ( clk        ),
  .aresetn     ( !rst       )
);

AXI4StreamMaster #(
  .DATA_WIDTH     ( DATA_WIDTH    ),
  .ID_WIDTH       ( ID_WIDTH      ),
  .DEST_WIDTH     ( DEST_WIDTH    ),
  .USER_WIDTH     ( USER_WIDTH    ),
  .RANDOM_TVALID  ( RANDOM_TVALID ),
  .VERBOSE        ( VERBOSE       ),
  .WATCHDOG_EN    ( 1'b1          ),
  .WATCHDOG_LIMIT ( 200           )
) pkt_sender;

AXI4StreamSlave #(
  .DATA_WIDTH     ( DATA_WIDTH    ),
  .ID_WIDTH       ( ID_WIDTH      ),
  .DEST_WIDTH     ( DEST_WIDTH    ),
  .USER_WIDTH     ( USER_WIDTH    ),
  .RANDOM_TREADY  ( RANDOM_TREADY ),
  .VERBOSE        ( VERBOSE       ),
  .WATCHDOG_EN    ( 1'b1          ),
  .WATCHDOG_LIMIT ( 200           )
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

function automatic void ref_model( pkt_q tx_pkt, int max_size );
  pkt_q frag_pkt;
  while( tx_pkt.size() > 0 )
    begin
      while( frag_pkt.size() != max_size )
        begin
          if( tx_pkt.size() == 0 )
            break;
          frag_pkt.push_back( tx_pkt.pop_front() );
        end
      void'( ref_data_mbx.try_put( frag_pkt ) );
      frag_pkt.delete(); 
    end
endfunction

task automatic compare_mbx();

  pkt_q rx_pkt;
  pkt_q ref_pkt;

  fork
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
  join_none
endtask

axi4_stream_pkt_frag #(
  .TDATA_WIDTH      ( DATA_WIDTH      ),
  .TID_WIDTH        ( ID_WIDTH        ),
  .TDEST_WIDTH      ( DEST_WIDTH      ),
  .TUSER_WIDTH      ( USER_WIDTH      ),
  .MAX_FRAG_SIZE  ( MAX_PKT_SIZE_B  )
) DUT (
  .clk_i           ( clk             ),
  .rst_i           ( rst             ),
  .max_frag_size_i ( max_frag_size   ),
  .pkt_i           ( rx_if           ),
  .pkt_o           ( tx_if           )
);

initial
  begin
    pkt_sender   = new( .axi4_stream_if_v ( rx_if ) );
    pkt_receiver = new( .axi4_stream_if_v ( tx_if       ),
                        .rx_data_mbx      ( rx_data_mbx ) );
    fork
      clk_gen();
    join_none
    compare_mbx();
    apply_rst();
    @( posedge clk );
    for( int i = 1; i <= 8 * DATA_WIDTH_B; i++ )
      begin
        max_frag_size = i;
        for( int j = 1; j <= 8 * DATA_WIDTH_B; j++ )
          begin
            tx_pkt = generate_pkt( j );
            ref_model( tx_pkt, max_frag_size );
            pkt_sender.tx_data( tx_pkt );
          end
      end
    repeat( 200 )
      begin
        max_frag_size = $urandom_range( 64, 1 );
        repeat( 1000 )
          begin
            tx_pkt = generate_pkt( $urandom_range( 16, 1 ) );
            ref_model( tx_pkt, max_frag_size );
            pkt_sender.tx_data( tx_pkt );
            tx_pkt = generate_pkt( $urandom_range( 64, 16 ) );
            ref_model( tx_pkt, max_frag_size );
            pkt_sender.tx_data( tx_pkt );
          end
      end
    repeat( 10 )
      @( posedge clk );
    $display( "Everthing is fine." );
    $stop();
  end

endmodule
