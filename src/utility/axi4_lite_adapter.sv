module axi4_lite_adapter #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 32
)(
  input                             clk_i,
  input                             rst_i,
  input        [DATA_WIDTH - 1 : 0] wr_data_i,
  input        [ADDR_WIDTH - 1 : 0] addr_i,
  input                             wr_stb_i,
  input                             rd_stb_i,
  output logic [DATA_WIDTH - 1 : 0] rd_data_o,
  output                            ready_o,
  output                            done_stb_o,
  axi4_lite_if.master               axi4_lite_o
);

enum logic [1 : 0] { IDLE_S,
                     WAIT_WRITE_HANDSHAKES_S,
                     WAIT_READ_HANDSHAKES_S,
                     WAIT_BRESP_S } state, next_state;

logic was_w_handshake;
logic was_aw_handshake;
logic was_r_handshake;
logic was_ar_handshake;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    state <= IDLE_S;
  else
    state <= next_state;

always_comb
  begin
    next_state = state;
    case( state )
      IDLE_S:
        begin
          if( wr_stb_i )
            next_state = WAIT_WRITE_HANDSHAKES_S;
          else
            if( rd_stb_i )
              next_state = WAIT_READ_HANDSHAKES_S;
        end
      WAIT_WRITE_HANDSHAKES_S:
        begin
          if( ( axi4_lite_o.wready || was_w_handshake ) &&
              ( axi4_lite_o.awready || was_aw_handshake ) )
            if( axi4_lite_o.bvalid )
              next_state = IDLE_S;
            else
              next_state = WAIT_BRESP_S;
        end
      WAIT_READ_HANDSHAKES_S:
        begin
          if( ( axi4_lite_o.rvalid || was_r_handshake ) &&
              ( axi4_lite_o.arvalid || was_ar_handshake ) )
            next_state = IDLE_S;
        end
      WAIT_BRESP_S:
        begin
          if( axi4_lite_o.bvalid )
            next_state = IDLE_S;
        end
    endcase
  end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    was_w_handshake <= 1'b0;
  else
    if( state == IDLE_S )
      was_w_handshake <= 1'b0;
    else
      was_w_handshake <= axi4_lite_o.wvalid && axi4_lite_o.wready;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    was_aw_handshake <= 1'b0;
  else
    if( state == IDLE_S )
      was_aw_handshake <= 1'b0;
    else
      was_aw_handshake <= axi4_lite_o.awvalid && axi4_lite_o.awready;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    was_r_handshake <= 1'b0;
  else
    if( state == IDLE_S )
      was_r_handshake <= 1'b0;
    else
      was_r_handshake <= axi4_lite_o.rvalid && axi4_lite_o.rready;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    was_ar_handshake <= 1'b0;
  else
    if( state == IDLE_S )
      was_ar_handshake <= 1'b0;
    else
      was_ar_handshake <= axi4_lite_o.arvalid && axi4_lite_o.arready;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    axi4_lite_o.awvalid <= 1'b0;
  else
    if( state == IDLE_S && wr_stb_i )
      axi4_lite_o.awvalid <= 1'b1;
    else
      if( axi4_lite_o.awready )
        axi4_lite_o.awvalid <= 1'b0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    axi4_lite_o.awaddr <= ADDR_WIDTH'( 0 );
  else
    if( state == IDLE_S && wr_stb_i )
      axi4_lite_o.awaddr <= addr_i;
    else
      if( axi4_lite_o.awready )
        axi4_lite_o.awaddr <= ADDR_WIDTH'( 0 );

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    axi4_lite_o.arvalid <= 1'b0;
  else
    if( state == IDLE_S && rd_stb_i )
      axi4_lite_o.arvalid <= 1'b1;
    else
      if( axi4_lite_o.arready )
        axi4_lite_o.arvalid <= 1'b0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    axi4_lite_o.araddr <= ADDR_WIDTH'( 0 );
  else
    if( state == IDLE_S && rd_stb_i )
      axi4_lite_o.araddr <= addr_i;
    else
      if( axi4_lite_o.arready )
        axi4_lite_o.araddr <= ADDR_WIDTH'( 0 );

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    axi4_lite_o.wvalid <= 1'b0;
  else
    if( state == IDLE_S && wr_stb_i )
      axi4_lite_o.wvalid <= 1'b1;
    else
      if( axi4_lite_o.wready )
        axi4_lite_o.wvalid <= 1'b0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    axi4_lite_o.wdata <= DATA_WIDTH'( 0 );
  else
    if( state == IDLE_S && wr_stb_i )
      axi4_lite_o.wdata <= wr_data_i;
    else
      if( axi4_lite_o.wready )
        axi4_lite_o.wdata <= DATA_WIDTH'( 0 );

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    rd_data_o <= DATA_WIDTH'( 0 );
  else
    if( axi4_lite_o.rvalid )
      rd_data_o <= axi4_lite_o.rdata;

assign axi4_lite_o.awprot = 3'd0;
assign axi4_lite_o.arprot = 3'd0;
assign axi4_lite_o.wstrb  = '1;
assign axi4_lite_o.bready = 1'b1;
assign axi4_lite_o.rready = 1'b1;
assign ready_o            = state == IDLE_S;
assign done_stb_o         = state != IDLE_S && next_state == IDLE_S;

endmodule
