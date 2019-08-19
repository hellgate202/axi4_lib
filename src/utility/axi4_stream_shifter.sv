module axi4_stream_shifter #(
  parameter int DATA_WIDTH     = 32,
  parameter int ID_WIDTH       = 1,
  parameter int DEST_WIDTH     = 1,
  parameter int USER_WIDTH     = 1,
  parameter int DATA_WIDTH_B   = DATA_WIDTH / 8,
  parameter int DATA_WIDTH_B_W = $clog2( DATA_WIDTH_B )

)(
  input                          clk_i,
  input                          rst_i,
  input [DATA_WIDTH_B_W - 1 : 0] shift_i,
  axi4_stream_if                 pkt_i,
  axi4_stream_if                 pkt_o
);

logic [1 : 0][DATA_WIDTH - 1 : 0] tdata_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] tstrb_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] tkeep_buf;
logic [1 : 0][DATA_WIDTH - 1 : 0] shifted_tdata_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] shifted_tstrb_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] shifted_tkeep_buf;
logic [DATA_WIDTH_B - 1 : 0]        tstrb_masked_tlast;
logic [DATA_WIDTH_B - 1 : 0]        tkeep_masked_tlast;
logic [DATA_WIDTH_B - 1 : 0]        tstrb_masked_tfirst;
logic [DATA_WIDTH_B - 1 : 0]        tkeep_masked_tfirst;
logic [DATA_WIDTH_B_W : 0]        rx_bytes;
logic [DATA_WIDTH_B_W : 0]        tx_bytes;
logic [DATA_WIDTH_B_W : 0]        bytes_in_buf;
logic                             tfirst;
logic                             tlast_lock;
logic                             tfirst_lock;
logic                             backpressure;

assign pkt_i.tready = pkt_o.tready && !backpressure;
assign pkt_o.tvalid = bytes_in_buf >= DATA_WIDTH_B[DATA_WIDTH_B_W : 0] || tlast_lock && bytes_in_buf > 'd0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      pkt_o.tid   <= '0;
      pkt_o.tuser <= '0;
      pkt_o.tdest <= '0;
    end
  else
    if( pkt_i.tvalid && pkt_i.tready && tfirst )
      begin
        pkt_o.tid   <= pkt_i.tid;
        pkt_o.tuser <= pkt_i.tuser;
        pkt_o.tdest <= pkt_i.tdest;
      end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    tlast_lock <= 'd1;
  else
    if( pkt_i.tvalid && pkt_i.tready ) 
      if( pkt_i.tlast )
        tlast_lock <= 1'b1;
      else
        tlast_lock <= 1'b0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    tfirst_lock <= '0;
  else
    if( tfirst && pkt_i.tready )
      tfirst_lock <= 1'b1;
    else
      if( pkt_o.tvalid && pkt_o.tready )
        tfirst_lock <= 1'b0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    backpressure <= '0;
  else
    if( pkt_i.tvalid && pkt_i.tready && pkt_i.tlast &&
        rx_bytes > ( DATA_WIDTH_B - shift_i ) )
      backpressure <= 1'b1;
    else
      if( pkt_o.tvalid && pkt_o.tready )
        backpressure <= 1'b0;

assign tfirst = tlast_lock && pkt_i.tvalid;
assign pkt_o.tlast = tlast_lock && bytes_in_buf == tx_bytes;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      tdata_buf <= '0;
      tkeep_buf <= '0;
      tstrb_buf <= '0;
    end
  else
    if( pkt_i.tvalid && pkt_i.tready || backpressure && pkt_o.tready )
      begin
        tdata_buf[1] <= pkt_i.tdata;
        tdata_buf[0] <= tdata_buf[1];
        tkeep_buf[1] <= pkt_i.tkeep;
        tkeep_buf[0] <= tkeep_buf[1];
        tstrb_buf[1] <= pkt_i.tstrb;
        tstrb_buf[0] <= tstrb_buf[1];
      end

always_comb
  begin
    rx_bytes = '0;
    if( pkt_i.tvalid )
      if( pkt_i.tlast )
        begin
          for( int i = 0; i < DATA_WIDTH_B; i++ )
            if( pkt_i.tstrb[i] || pkt_i.tkeep[i] )
              rx_bytes++;
        end
      else
        rx_bytes = DATA_WIDTH_B[DATA_WIDTH_B_W : 0];
  end

always_comb
  begin
    tx_bytes = '0;
    if( bytes_in_buf > '0 )
      if( tfirst_lock )
        if( bytes_in_buf <= ( DATA_WIDTH_B[DATA_WIDTH_B_W : 0] - shift_i ) )
          tx_bytes = bytes_in_buf;
        else
          tx_bytes = DATA_WIDTH_B[DATA_WIDTH_B_W : 0] - shift_i;
      else
        if( bytes_in_buf > DATA_WIDTH_B[DATA_WIDTH_B_W : 0] )
          tx_bytes = DATA_WIDTH_B[DATA_WIDTH_B_W : 0];
        else
          if( tlast_lock )
            tx_bytes = bytes_in_buf;
  end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    bytes_in_buf <= '0;
  else
    if( pkt_i.tready && pkt_o.tready )
      bytes_in_buf <= bytes_in_buf + rx_bytes - tx_bytes;
    else
      if( pkt_i.tready )
        bytes_in_buf <= bytes_in_buf + rx_bytes;
      else
        if( pkt_o.tready )
          bytes_in_buf <= bytes_in_buf - tx_bytes;

always_comb
  begin
    tkeep_masked_tlast = '0;
    tstrb_masked_tlast = '0;
    for( int i = 0; i < DATA_WIDTH_B; i++ )
      if( i < tx_bytes )
        begin
          tkeep_masked_tlast[i] = shifted_tkeep_buf[1][i];
          tstrb_masked_tlast[i] = shifted_tstrb_buf[1][i];
        end
  end

assign tkeep_masked_tfirst = tkeep_buf[1] << shift_i;
assign tstrb_masked_tfirst = tstrb_buf[1] << shift_i;


assign shifted_tdata_buf = tdata_buf << ( shift_i * 8 );
assign shifted_tstrb_buf = tstrb_buf << shift_i;
assign shifted_tkeep_buf = tkeep_buf << shift_i;
assign pkt_o.tdata       = shifted_tdata_buf[1];
assign pkt_o.tkeep       = tfirst_lock ? tkeep_masked_tfirst : 
                           pkt_o.tlast ? tkeep_masked_tlast : shifted_tkeep_buf[1];
assign pkt_o.tstrb       = tfirst_lock ? tstrb_masked_tfirst:
                           pkt_o.tlast ? tstrb_masked_tlast : shifted_tstrb_buf[1];

endmodule
