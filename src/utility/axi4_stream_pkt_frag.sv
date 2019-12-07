module axi4_stream_pkt_frag #(
  parameter int TDATA_WIDTH         = 64,
  parameter int TID_WIDTH           = 1,
  parameter int TDEST_WIDTH         = 1,
  parameter int TUSER_WIDTH         = 1,
  parameter int MAX_FRAG_SIZE       = 2048,
  parameter int MAX_FRAG_SIZE_WIDTH = $clog2( MAX_FRAG_SIZE )
)(
  input                           clk_i,
  input                           rst_i,
  input [MAX_FRAG_SIZE_WIDTH : 0] max_frag_size_i,
  axi4_stream_if.slave            pkt_i,
  axi4_stream_if.master           pkt_o
);

localparam int TDATA_WIDTH_B  = TDATA_WIDTH / 8;
localparam int BYTE_CNT_WIDTH = $clog2( TDATA_WIDTH_B ) + 1;
localparam int BUF_SIZE_B     = TDATA_WIDTH_B * 2;
localparam int BUF_CNT_WIDTH  = $clog2( BUF_SIZE_B );
localparam int MAX_SHIFT      = TDATA_WIDTH_B;
localparam int SHIFT_WIDTH    = $clog2( MAX_SHIFT ) + 1;

logic                             rx_handshake;
logic                             tx_handshake;
logic [BYTE_CNT_WIDTH - 1: 0]     rx_bytes;
logic [BYTE_CNT_WIDTH - 1: 0]     tx_bytes;
logic [SHIFT_WIDTH - 1 : 0]       shift;
logic [BUF_SIZE_B - 1 : 0][7 : 0] tdata_buf;
logic [BUF_SIZE_B - 1 : 0]        tstrb_buf;
logic [BUF_SIZE_B - 1 : 0]        tkeep_buf;
logic [TID_WIDTH - 1 : 0]         tid_buf;
logic [TDEST_WIDTH - 1 : 0]       tdest_buf;
logic [TUSER_WIDTH - 1 : 0]       tuser_buf;
logic [BUF_CNT_WIDTH - 1 : 0]     bytes_in_buf;
logic [MAX_FRAG_SIZE_WIDTH : 0]   frag_bytes_left;
logic                             idle_flag;
logic                             was_eop;
logic                             flush_flag;
logic                             tfirst;
logic [MAX_FRAG_SIZE_WIDTH : 0]   max_frag_size_lock;
logic [MAX_FRAG_SIZE_WIDTH : 0]   max_frag_size;
logic                             buf_done;
logic                             frag_done;
logic                             acc_flag;
logic                             backpressure;

assign rx_handshake = pkt_i.tvalid && pkt_i.tready;
assign tx_handshake = pkt_o.tvalid && pkt_o.tready;

// Amount of ones in tkeep signal is amount of bytes to receive
always_comb
  begin
    rx_bytes = BYTE_CNT_WIDTH'( 0 );
    for( int i = 0; i < TDATA_WIDTH_B; i++ )
      if( pkt_i.tkeep[i] ) 
        rx_bytes++;
  end

// Shift register of incomning packet words
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      tdata_buf <= ( BUF_SIZE_B * 8 )'( 0 );
      tstrb_buf <= BUF_SIZE_B'( 0 );
      tkeep_buf <= BUF_SIZE_B'( 0 );
      tid_buf   <= TID_WIDTH'( 0 );
      tdest_buf <= TDEST_WIDTH'( 0 );
      tuser_buf <= TUSER_WIDTH'( 0 );
    end
  else
    if( rx_handshake )
      begin
        tdata_buf <= { pkt_i.tdata, tdata_buf[BUF_SIZE_B - 1 : TDATA_WIDTH_B] };
        tstrb_buf <= { pkt_i.tstrb, tstrb_buf[BUF_SIZE_B - 1 : TDATA_WIDTH_B] };
        tkeep_buf <= { pkt_i.tkeep, tkeep_buf[BUF_SIZE_B - 1 : TDATA_WIDTH_B] };
        // I don't know what to do with these signals, leave them as is
        tid_buf   <= pkt_i.tid;
        tdest_buf <= pkt_i.tdest;
        tuser_buf <= pkt_i.tuser;
      end

// Amount of actual bytes in buffer
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    bytes_in_buf <= BUF_CNT_WIDTH'( 0 );
  else
    if( rx_handshake && tx_handshake )
      bytes_in_buf <= bytes_in_buf + BUF_CNT_WIDTH'( rx_bytes ) - BUF_CNT_WIDTH'( tx_bytes );
    else
      if( rx_handshake )
        bytes_in_buf <= bytes_in_buf + BUF_CNT_WIDTH'( rx_bytes );
      else
        if( tx_handshake )
          bytes_in_buf <= bytes_in_buf - BUF_CNT_WIDTH'( tx_bytes );

// Used to determine if the previous packet has ended
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    was_eop <= 1'b1;
  else
    if( rx_handshake )
      if( pkt_i.tlast )
        was_eop <= 1'b1;
      else
        was_eop <= 1'b0;

// Flag is determining the state when the incoming packet has ended and we
// still have bytes to send in buffer
assign flush_flag = was_eop && ( BUF_CNT_WIDTH'( tx_bytes ) < bytes_in_buf || !pkt_o.tready );
// Interface is idle when incoming packet has ended and no more bytes left in
// buffer
assign idle_flag  = was_eop && bytes_in_buf == BUF_CNT_WIDTH'( 0 );

// How many bytes we can send in current fragment
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    frag_bytes_left <= '0;
  else
    // Idle flag is used to initialize frag_bytes_left before the first packet
    // or if frag size is changed between packets 
    if( pkt_o.tlast && tx_handshake || idle_flag )
      frag_bytes_left <= max_frag_size;
    else
      if( tx_handshake )
        frag_bytes_left <= frag_bytes_left - tx_bytes;

always_comb
  // Current fragment has space for whole word
  if( frag_bytes_left > MAX_FRAG_SIZE_WIDTH'( TDATA_WIDTH_B ) )
    // And the whole word is in buffer
    if( bytes_in_buf > BUF_CNT_WIDTH'( TDATA_WIDTH_B ) )
      tx_bytes = BYTE_CNT_WIDTH'( TDATA_WIDTH_B );
    // Else send the whole buffer
    else
      tx_bytes = BYTE_CNT_WIDTH'( bytes_in_buf );
  // Current fragment has less space then one word
  else
    // But there is even less bytes in buffer, so we send the whole buffer
    if( frag_bytes_left > MAX_FRAG_SIZE'( bytes_in_buf ) )
      tx_bytes = BYTE_CNT_WIDTH'( bytes_in_buf );
    // Else send as much bytes as fragment can hold from buffer
    else
      tx_bytes = BYTE_CNT_WIDTH'( frag_bytes_left );

// First word of the packet
assign tfirst = was_eop && rx_handshake;

// Locking fragment size in the first word of the packet
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    max_frag_size_lock <= '0;
  else
    if( tfirst )
      max_frag_size_lock <= max_frag_size_i;

// For first word we use value from input and then the locked value
assign max_frag_size = tfirst ? max_frag_size_i : max_frag_size_lock;

// Core part of the module
// Decides which part of buffer we will transmit
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    shift <= SHIFT_WIDTH'( MAX_SHIFT );
  else
    // When we are fine and we are sending as much bytes as we can
    if( bytes_in_buf == BUF_CNT_WIDTH'( tx_bytes ) && tx_handshake )
      shift <= SHIFT_WIDTH'( MAX_SHIFT );
    else
      // Instead of rx_bytes we are shifting data by TDATA_WIDTH_B value
      // because input shift reg is shifting whole words
      // In other thing its the same as bytes_in_buf...
      if( tx_handshake && rx_handshake )
        shift <= shift - SHIFT_WIDTH'( TDATA_WIDTH_B ) + ( SHIFT_WIDTH + 1 )'( tx_bytes );
      else
        if( tx_handshake )
          shift <= shift + SHIFT_WIDTH'( tx_bytes );
        else
          // ...exept this one. We reduce shift only if there were some data
          // before new word was accepted
          if( rx_handshake && bytes_in_buf > BUF_CNT_WIDTH'( 0 ) )
            shift <= shift - SHIFT_WIDTH'( TDATA_WIDTH_B );

// Incoming packet has ended and buffer is about to be emptied
assign buf_done  = bytes_in_buf == tx_bytes && was_eop;

// When we are about to sent last word of the fragment
assign frag_done = frag_bytes_left == tx_bytes;

// When we are collecting bytes for one transfer, i.e. there is not enough
// bytes for single transfer
assign acc_flag  = tx_bytes < frag_bytes_left && tx_bytes < bytes_in_buf && 
                   tx_bytes != TDATA_WIDTH_B;

// We can't receive more bytes when we have more than MAX_SHIFT bytes in
// buffer or we are flushing buffer after incoming packet has ended
assign backpressure = bytes_in_buf >= BUF_SIZE_B'( MAX_SHIFT ) || flush_flag;

// Selection of tdata, tkeep and tstrb depending on shift value
always_comb
  for( int i = 0; i < TDATA_WIDTH_B; i++ )
    if( BYTE_CNT_WIDTH'( i ) < tx_bytes )
      begin
        pkt_o.tstrb[i] = tstrb_buf[shift + i];
        pkt_o.tkeep[i] = tkeep_buf[shift + i];
      end
    else
      begin
        pkt_o.tstrb[i] = 1'b0;
        pkt_o.tkeep[i] = 1'b0;
      end

assign pkt_o.tdata  = tdata_buf[TDATA_WIDTH_B + shift - 1 -: TDATA_WIDTH_B];
assign pkt_o.tlast  = buf_done || frag_done;
assign pkt_o.tvalid = !acc_flag && !idle_flag;
assign pkt_o.tid    = tid_buf;
assign pkt_o.tdest  = tdest_buf;
assign pkt_o.tuser  = tuser_buf;
assign pkt_i.tready = !backpressure;

endmodule
