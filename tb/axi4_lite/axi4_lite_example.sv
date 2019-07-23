`include "../../src/class/AXI4LiteMaster.sv"
`include "../../src/class/AXI4LiteSlave.sv"

`timescale 1 ps / 1 ps

module axi4_lite_example;

parameter DATA_WIDTH   = 32;
parameter ADDR_WIDTH   = 16;
parameter VERBOSE      = 3;
parameter CLK_T        = 10000;
parameter TRANS_AMOUNT = 10000;

logic clk;
logic rst;

bit [31 : 0]             ref_mem_a [*];
bit [DATA_WIDTH - 1 : 0] wr_data;
bit [DATA_WIDTH - 1 : 0] rd_data;
bit [ADDR_WIDTH - 1 : 0] addr;

axi4_lite_if #(
  .DATA_WIDTH ( DATA_WIDTH ),
  .ADDR_WIDTH ( ADDR_WIDTH )
) dut_if (
  .aclk       ( clk        ),
  .aresetn    ( ~rst       )
);

AXI4LiteMaster #(
  .DATA_WIDTH ( DATA_WIDTH ),
  .ADDR_WIDTH ( ADDR_WIDTH ),
  .VERBOSE    ( VERBOSE    )
) master;

AXI4LiteSlave #(
  .DATA_WIDTH   ( DATA_WIDTH   ),
  .ADDR_WIDTH   ( ADDR_WIDTH   ),
  .VERBOSE      ( VERBOSE      )
) slave;

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
    master = new( .axi4_lite_if_v ( dut_if ) );
    slave  = new( .axi4_lite_if_v ( dut_if ) );
    fork
      clk_gen();
    join_none
    rst = 1'b0;
    @( posedge clk );
    repeat( TRANS_AMOUNT )
      begin
        addr    = $urandom_range( 2 ** ADDR_WIDTH - 1 );
        wr_data = $urandom_range( 2 ** DATA_WIDTH - 1 );
        master.wr_data( .addr ( addr    ),
                        .data ( wr_data )
                      );
        master.rd_data( .addr ( addr    ),
                        .data ( rd_data )
                      );
        if( rd_data != wr_data )
          begin
            $display( "Everything is NOT fine." );
            $stop();
          end
      end
    @( posedge clk );
    $display( "Everything is fine." );
    $stop();
  end

endmodule
