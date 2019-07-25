`include "../../src/class/AXI4StreamMaster.sv"
`include "../../src/class/AXI4StreamSlave.sv"

`timescale 1 ps / 1 ps

module tb_axi4_stream_pkt_split;

parameter int DATA_WIDTH     = 32;
parameter int ID_WIDTH       = 1;
parameter int DEST_WIDTH     = 1;
parameter int USER_WIDTH     = 1;
parameter int RANDOM_TVALID  = 1;
parameter int RANDOM_TREADY  = 1;
parameter int VERBOSE        = 0;

parameter int MAX_PKT_SIZE_B = 1024;
parameter int PKT_SIZE_WIDTH = $clog2( MAX_PKT_SIZE_B );

parameter int CLK_T          = 5000;

typedef bit [7 : 0] pkt_q [$];

bit                      clk;
bit                      rst;
bit [PKT_SIZE_WIDTH : 0] max_pkt_size;

pkt_q                    tx_pkt;

mailbox rx_data_mbx = new();

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
  .DATA_WIDTH    ( DATA_WIDTH    ),
  .ID_WIDTH      ( ID_WIDTH      ),
  .DEST_WIDTH    ( DEST_WIDTH    ),
  .USER_WIDTH    ( USER_WIDTH    ),
  .RANDOM_TVALID ( RANDOM_TVALID ),
  .VERBOSE       ( VERBOSE       )
) pkt_sender;

AXI4StreamSlave #(
  .DATA_WIDTH    ( DATA_WIDTH    ),
  .ID_WIDTH      ( ID_WIDTH      ),
  .DEST_WIDTH    ( DEST_WIDTH    ),
  .USER_WIDTH    ( USER_WIDTH    ),
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

function automatic pkt_q generate_pkt( int size ); 

  pkt_q pkt;

  for( int i = 0; i < size; i++ )
    pkt.push_back( $urandom_range( 255, 0 ) );

  return pkt;

endfunction

axi4_stream_pkt_split #(
  .DATA_WIDTH     ( DATA_WIDTH     ),
  .ID_WIDTH       ( ID_WIDTH       ),
  .DEST_WIDTH     ( DEST_WIDTH     ),
  .USER_WIDTH     ( USER_WIDTH     ),
  .MAX_PKT_SIZE_B ( MAX_PKT_SIZE_B )
) DUT (
  .clk_i          ( clk            ),
  .rst_i          ( rst            ),
  .max_pkt_size_i ( max_pkt_size   ),
  .pkt_i          ( rx_if          ),
  .pkt_o          ( tx_if          )
);

int pkt_size;
int predicted_pkt_cnt;

initial
  begin
    pkt_sender   = new( .axi4_stream_if_v ( rx_if ) );
    pkt_receiver = new( .axi4_stream_if_v ( tx_if       ),
                        .rx_data_mbx      ( rx_data_mbx ) );
    fork
      clk_gen();
    join_none
    apply_rst();
    @( posedge clk );
    max_pkt_size = 11;
    repeat( 10 )
      begin
        pkt_size = $urandom_range( MAX_PKT_SIZE_B, 1 );
        tx_pkt = generate_pkt( pkt_size );
        pkt_sender.send_pkt( tx_pkt );
        predicted_pkt_cnt += ( pkt_size % max_pkt_size ) ? ( pkt_size / max_pkt_size + 1 ): ( pkt_size / max_pkt_size );
      end
    @( posedge clk );
    while( rx_data_mbx.num() != predicted_pkt_cnt )
      @( posedge clk );
    repeat( 10 )
      @( posedge clk );
    $stop();
  end

endmodule
