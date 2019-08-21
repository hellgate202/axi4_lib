module axi4_stream_byte_shift #(
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

logic [1 : 0][DATA_WIDTH - 1 : 0]   tdata_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] tstrb_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] tkeep_buf;
logic [1 : 0][DATA_WIDTH - 1 : 0]   shifted_tdata_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] shifted_tstrb_buf;
logic [1 : 0][DATA_WIDTH_B - 1 : 0] shifted_tkeep_buf;
logic                               move_data;
logic [DATA_WIDTH_B - 1 : 0]        tstrb_masked_tlast;
logic [DATA_WIDTH_B - 1 : 0]        tkeep_masked_tlast;
logic [DATA_WIDTH_B - 1 : 0]        tstrb_masked_tfirst;
logic [DATA_WIDTH_B - 1 : 0]        tkeep_masked_tfirst;
logic [DATA_WIDTH_B_W : 0]          rx_bytes;
logic [DATA_WIDTH_B_W : 0]          tx_bytes;
logic [DATA_WIDTH_B_W + 1 : 0]      bytes_in_buf, bytes_in_buf_comb;
logic                               pkt_i_tfirst;
logic                               pkt_o_tfirst;
logic                               backpressure;
logic [DATA_WIDTH_B_W - 1 : 0]      shift_lock;

assign move_data = pkt_i.tvalid && pkt_i.tready || backpressure && pkt_o.tready;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      tdata_buf <= '0;
      tkeep_buf <= '0;
      tstrb_buf <= '0;
    end
  else
    if( move_data )
      begin
        tdata_buf[1] <= pkt_i.tdata;
        tdata_buf[0] <= tdata_buf[1];
        tkeep_buf[1] <= pkt_i.tkeep;
        tkeep_buf[0] <= tkeep_buf[1];
        tstrb_buf[1] <= pkt_i.tstrb;
        tstrb_buf[0] <= tstrb_buf[1];
      end

assign shifted_tdata_buf = tdata_buf << ( shift_lock * 8 );
assign shifted_tstrb_buf = tstrb_buf << shift_lock;
assign shifted_tkeep_buf = tkeep_buf << shift_lock;

// Currently I have no idea what to do with these signals
// I usually use tuser not as multiply of bytes in tdata but 
// as 1 bit signal, and I don't know how to split it, if the first
// word of the packet does. So, for now, I just remember the value in
// the first word and keep it for entire packet.
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      pkt_o.tid   <= '0;
      pkt_o.tuser <= '0;
      pkt_o.tdest <= '0;
    end
  else
    if( pkt_i.tvalid && pkt_i.tready && pkt_i_tfirst )
      begin
        pkt_o.tid   <= pkt_i.tid;
        pkt_o.tuser <= pkt_i.tuser;
        pkt_o.tdest <= pkt_i.tdest;
      end

// Backpressure is asserted when we need an additional transaction
// which appeared because of the byte shift
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    backpressure <= '0;
  else
    // TODO: check FMAX in both cases
    if( pkt_i.tvalid && pkt_i.tready && pkt_i.tlast &&
      ( ( pkt_i_tfirst && ( rx_bytes + shift_lock ) > DATA_WIDTH_B[DATA_WIDTH_B_W : 0] ) ||
        ( bytes_in_buf_comb > DATA_WIDTH_B[DATA_WIDTH_B_W : 0] ) ) )
        //( ( bytes_in_buf_comb + shift_lock ) > DATA_WIDTH_B[DATA_WIDTH_B_W : 0] ) )
      backpressure <= 1'b1;
    else
      if( pkt_o.tvalid && pkt_o.tready )
        backpressure <= 1'b0;

// We remember shift value at the begining of the packet
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    shift_lock <= '0;
  else
    if( pkt_i.tvalid && pkt_i.tready && pkt_i_tfirst )
      shift_lock <= shift_i;

// First and last transactions contain as much bytes as the position of left most one
// in tkeep signal, i.e. we keep all bytes before as significant and we don't
// have logic to discard them
always_comb
  begin
    rx_bytes = '0;
    if( pkt_i.tvalid )
      if( pkt_i_tfirst || pkt_i.tlast )
        begin
          for( integer lmo = 0; lmo < DATA_WIDTH_B; lmo++ )
            if( pkt_i.tkeep[lmo] )
              rx_bytes = lmo[DATA_WIDTH_B_W : 0] + 1'b1;
        end
      else
        rx_bytes = DATA_WIDTH_B[DATA_WIDTH_B_W : 0];
  end

// In first word we transmit up to such amount of words that was left after
// shift, but could be lower if packet has only one word and this word is
// lower than maximum amount of words minus shift
always_comb
  begin
    tx_bytes = '0;
    if( bytes_in_buf > '0 )
      if( pkt_o_tfirst )
        if( bytes_in_buf <= ( DATA_WIDTH_B[DATA_WIDTH_B_W : 0] - shift_lock ) )
          tx_bytes = bytes_in_buf;
        else
          tx_bytes = DATA_WIDTH_B[DATA_WIDTH_B_W : 0] - shift_lock;
      else
        if( bytes_in_buf >= DATA_WIDTH_B[DATA_WIDTH_B_W : 0] )
          tx_bytes = DATA_WIDTH_B[DATA_WIDTH_B_W : 0];
        else
          if( pkt_i_tfirst )
            tx_bytes = bytes_in_buf;
  end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    bytes_in_buf <= '0;
  else
    bytes_in_buf <= bytes_in_buf_comb;

always_comb
  begin
    bytes_in_buf_comb = bytes_in_buf;
    if( pkt_i.tready && pkt_o.tready )
      bytes_in_buf_comb = bytes_in_buf + rx_bytes - tx_bytes;
    else
      if( pkt_i.tready )
        bytes_in_buf_comb = bytes_in_buf + rx_bytes;
      else
        if( pkt_o.tready )
          bytes_in_buf_comb = bytes_in_buf - tx_bytes;
  end

// Used to determine first word of the next packet and
// to declare that incoming packet has ended
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    pkt_i_tfirst <= 'd1;
  else
    if( pkt_i.tvalid && pkt_i.tready ) 
      if( pkt_i.tlast )
        pkt_i_tfirst <= 1'b1;
      else
        pkt_i_tfirst <= 1'b0;


always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    pkt_o_tfirst <= 'd1;
  else
    if( pkt_o.tvalid && pkt_o.tready ) 
      if( pkt_o.tlast )
        pkt_o_tfirst <= 1'b1;
      else
        pkt_o_tfirst <= 1'b0;

// The last word tstrb and tkeep signals must be masked,
// because we shift incoming values from two incoming words, and
// after shift there coulde be bits from the next packet
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

assign tkeep_masked_tfirst = tkeep_buf[1] << shift_lock;
assign tstrb_masked_tfirst = tstrb_buf[1] << shift_lock;

assign pkt_o.tdata         = shifted_tdata_buf[1];
assign pkt_o.tkeep         = pkt_o_tfirst ? tkeep_masked_tfirst : 
                             pkt_o.tlast ? tkeep_masked_tlast : shifted_tkeep_buf[1];
assign pkt_o.tstrb         = pkt_o_tfirst ? tstrb_masked_tfirst:
                             pkt_o.tlast ? tstrb_masked_tlast : shifted_tstrb_buf[1];
assign pkt_i.tready        = pkt_o.tready && !backpressure;
assign pkt_o.tvalid        = bytes_in_buf >= DATA_WIDTH_B[DATA_WIDTH_B_W : 0] || 
                             pkt_i_tfirst && bytes_in_buf > 'd0;
assign pkt_o.tlast         = pkt_i_tfirst && bytes_in_buf == tx_bytes;

endmodule
