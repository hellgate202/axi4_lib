`include "../../src/class/AXI4Master.sv"
`include "../../src/class/AXI4MultiportMemory.sv"

`timescale 1 ps / 1 ps

module axi4_multiport_mem_example;

parameter int PORTS_AMOUNT   = 2;

parameter int DATA_WIDTH     = 32;
parameter int ADDR_WIDTH     = 32;
parameter int ID_WIDTH       = 4;
parameter int AWUSER_WIDTH   = 1;
parameter int WUSER_WIDTH    = 1;
parameter int BUSER_WIDTH    = 1;
parameter int ARUSER_WIDTH   = 1;
parameter int RUSER_WIDTH    = 1;

parameter int RANDOM_WVALID  = 1;
parameter int RANDOM_RREADY  = 1;
parameter int RANDOM_WREADY  = 1;
parameter int RANDOM_RVALID  = 1;
parameter int VERBOSE        = 3;

parameter int CLK_T          = 10000;
parameter int TRANSACTIONS   = 100;
parameter int WORD_SIZE_MIN  = 1;
parameter int WORD_SIZE_MAX  = 1000; 

parameter int DATA_WIDTH_B   = DATA_WIDTH / 8;
parameter int ADDR_WORD_BITS = $clog2( DATA_WIDTH_B );

logic clk;
logic rst;

mailbox rd_data_mbx_0 = new();
mailbox rd_data_mbx_1 = new();

bit [DATA_WIDTH - 1 : 0] wr_word_q [$];
bit [DATA_WIDTH - 1 : 0] wr_word_q_buf [$];
bit [DATA_WIDTH - 1 : 0] rd_word_q [$];
bit [ADDR_WIDTH - 1 : 0] addr;
int                      words;

axi4_if #(
  .DATA_WIDTH   ( DATA_WIDTH   ),
  .ADDR_WIDTH   ( ADDR_WIDTH   ),
  .ID_WIDTH     ( ID_WIDTH     ),
  .AWUSER_WIDTH ( AWUSER_WIDTH ),
  .WUSER_WIDTH  ( WUSER_WIDTH  ),
  .BUSER_WIDTH  ( BUSER_WIDTH  ),
  .ARUSER_WIDTH ( ARUSER_WIDTH ),
  .RUSER_WIDTH  ( RUSER_WIDTH  )
) dut_if [PORTS_AMOUNT - 1 : 0] (
  .aclk         ( clk          ),
  .aresetn      ( ~rst         )
);

typedef AXI4Master #(
  .DATA_WIDTH    ( DATA_WIDTH    ),
  .ADDR_WIDTH    ( ADDR_WIDTH    ),
  .ID_WIDTH      ( ID_WIDTH      ),
  .AWUSER_WIDTH  ( AWUSER_WIDTH  ),
  .WUSER_WIDTH   ( WUSER_WIDTH   ),
  .BUSER_WIDTH   ( BUSER_WIDTH   ),
  .ARUSER_WIDTH  ( ARUSER_WIDTH  ),
  .RUSER_WIDTH   ( RUSER_WIDTH   ),
  .RANDOM_WVALID ( RANDOM_WVALID ),
  .RANDOM_RREADY ( RANDOM_RREADY ),
  .VERBOSE       ( VERBOSE       )
) axi4_master_0;

typedef AXI4Master #(
  .DATA_WIDTH    ( DATA_WIDTH    ),
  .ADDR_WIDTH    ( ADDR_WIDTH    ),
  .ID_WIDTH      ( ID_WIDTH      ),
  .AWUSER_WIDTH  ( AWUSER_WIDTH  ),
  .WUSER_WIDTH   ( WUSER_WIDTH   ),
  .BUSER_WIDTH   ( BUSER_WIDTH   ),
  .ARUSER_WIDTH  ( ARUSER_WIDTH  ),
  .RUSER_WIDTH   ( RUSER_WIDTH   ),
  .RANDOM_WVALID ( RANDOM_WVALID ),
  .RANDOM_RREADY ( RANDOM_RREADY ),
  .VERBOSE       ( VERBOSE       )
) axi4_master_1;

typedef AXI4MultiportMemory #(
  .PORTS_AMOUNT  ( PORTS_AMOUNT  ),
  .DATA_WIDTH    ( DATA_WIDTH    ),
  .ADDR_WIDTH    ( ADDR_WIDTH    ),
  .ID_WIDTH      ( ID_WIDTH      ),
  .AWUSER_WIDTH  ( AWUSER_WIDTH  ),
  .WUSER_WIDTH   ( WUSER_WIDTH   ),
  .BUSER_WIDTH   ( BUSER_WIDTH   ),
  .ARUSER_WIDTH  ( ARUSER_WIDTH  ),
  .RUSER_WIDTH   ( RUSER_WIDTH   ),
  .RANDOM_WREADY ( RANDOM_WREADY ),
  .RANDOM_RVALID ( RANDOM_RVALID ),
  .VERBOSE       ( VERBOSE       )
) axi4_mem;

axi4_master_0 master_0;
axi4_master_1 master_1;
axi4_mem      mem;

task automatic clk_gen();
  clk = 1'b0;
  forever
    begin
      #( CLK_T / 2 );
      clk = ~clk;
    end
endtask


initial
  begin
    master_0 = new( .axi4_if_v   ( dut_if[0]     ),
                    .rd_data_mbx ( rd_data_mbx_0 )
                  );
    master_1 = new( .axi4_if_v   ( dut_if[1]     ),
                    .rd_data_mbx ( rd_data_mbx_1 )
                  );
    mem      = new( dut_if );
    fork
      clk_gen();
    join_none
    rst = 1'b0;
    @( posedge clk );
    repeat( TRANSACTIONS )
      begin
        // There is two ways to write data via Avalon-MM Master
        // wr_transaction_word() and wr_transaction_byte() the only
        // different between them is that "word" method takes word bit size
        // queue at the input and "byte" method takes byte size queue
        // Address for write method may be unaligned with word size
        addr[31 : ADDR_WORD_BITS] = $urandom_range( 2 ** ( 31 - ADDR_WORD_BITS - 1 ) );
        words = $urandom_range( WORD_SIZE_MAX, WORD_SIZE_MIN );
        repeat( words )
          // Create word queue
          wr_word_q.push_back( $urandom_range( 2 ** DATA_WIDTH - 1 ) );
        wr_word_q_buf = wr_word_q;
        master_0.wr_transaction_word( .start_addr ( addr      ),
                                      .wr_word_q  ( wr_word_q )
                                    );
        // Wait untill write transaction ends
        @( master_0.wr_transaction_end );
        // Read from the same location
        // Read address must be word aligned! It's lower bits will be
        // zeroes.
        master_1.rd_transaction( .start_addr   ( addr  ),
                                 .words_amount ( words )
                               );
        // Wait untill read transaction ends
        @( master_1.rd_transaction_end );
        // Get received data from mailbox
        rd_data_mbx_1.get( rd_word_q );
        // Compare it
        if( rd_word_q != wr_word_q_buf )
          begin
            $display( "Everything is NOT fine" );
            $stop();
          end
        else
          begin
            rd_word_q.delete();
            wr_word_q_buf.delete();
          end
      end
    $display( "Everything is fine" );
    repeat( 50 )
      @( posedge clk );
    $stop();
  end

endmodule
