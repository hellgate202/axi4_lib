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
localparam int BYTE_CNT_WIDTH = $clog2( TDATA_WIDTH_B );
localparam int BUF_SIZE_W     = TDATA_WIDTH_B * 3;
localparam int BUF_CNT_WIDTH  = $clog2( BUF_SIZE_W );
localparam int MAX_SHIFT      = TDATA_WIDTH_B * 2;
localparam int SHIFT_WIDTH    = $clog2( MAX_SHIFT );

logic                             rx_handshake;
logic                             tx_handshake;
logic [BYTE_CNT_WIDTH : 0]        rx_bytes;
logic [BYTE_CNT_WIDTH : 0]        tx_bytes;
logic [SHIFT_WIDTH : 0]           shift;
logic [BUF_SIZE_W - 1 : 0][7 : 0] tdata_buf;
logic [BUF_SIZE_W - 1 : 0][7 : 0] tdata_buf_shifted;
logic [BUF_SIZE_W - 1 : 0]        tstrb_buf;
logic [BUF_SIZE_W - 1 : 0]        tstrb_buf_shifted;
logic [BUF_SIZE_W - 1 : 0]        tkeep_buf;
logic [BUF_SIZE_W - 1 : 0]        tkeep_buf_shifted;
logic [TID_WIDTH - 1 : 0]         tid_buf;
logic [TDEST_WIDTH - 1 : 0]       tdest_buf;
logic [TUSER_WIDTH - 1 : 0]       tuser_buf;
logic [BUF_CNT_WIDTH - 1 : 0]     bytes_in_buf;
logic [BYTE_CNT_WIDTH : 0]        avail_bytes;
logic [MAX_FRAG_SIZE_WIDTH : 0]   frag_bytes_left;
logic                             was_eop;
logic                             flush_flag;
logic [MAX_FRAG_SIZE_WIDTH : 0]   max_frag_size_lock;
logic [MAX_FRAG_SIZE_WIDTH : 0]   max_frag_size;

assign rx_handshake = pkt_i.tvalid && pkt_i.tready;
assign tx_handshake = pkt_o.tvalid && pkt_o.tready;

always_comb
  begin
    rx_bytes = ( BYTE_CNT_WIDTH + 1 )'( 0 );
    for( int i = 0; i < TDATA_WIDTH_B; i++ )
      if( pkt_i.tkeep[i] ) 
        rx_bytes++;
  end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      tdata_buf <= ( BUF_SIZE_W * 8 )'( 0 );
      tstrb_buf <= BUF_SIZE_W'( 0 );
      tkeep_buf <= BUF_SIZE_W'( 0 );
      tid_buf   <= TID_WIDTH'( 0 );
      tdest_buf <= TDEST_WIDTH'( 0 );
      tuser_buf <= TUSER_WIDTH'( 0 );
    end
  else
    if( rx_handshake )
      begin
        tdata_buf <= { pkt_i.tdata, tdata_buf[BUF_SIZE_W - 1 -: MAX_SHIFT] };
        tstrb_buf <= { pkt_i.tstrb, tstrb_buf[BUF_SIZE_W - 1 -: MAX_SHIFT] };
        tkeep_buf <= { pkt_i.tkeep, tkeep_buf[BUF_SIZE_W - 1 -: MAX_SHIFT] };
        tid_buf   <= pkt_i.tid;
        tdest_buf <= pkt_i.tdest;
        tuser_buf <= pkt_i.tuser;
      end

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

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    was_eop <= 1'b1;
  else
    if( rx_handshake )
      if( pkt_i.tlast )
        was_eop <= 1'b1;
      else
        was_eop <= 1'b0;

assign flush_flag = was_eop && ( BUF_CNT_WIDTH'( tx_bytes ) != bytes_in_buf || BUF_CNT_WIDTH'( tx_bytes ) == bytes_in_buf && !pkt_o.tready );

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    frag_bytes_left <= '0;
  else
    if( pkt_o.tlast )
      frag_bytes_left <= max_frag_size;
    else
      if( tx_handshake )
        frag_bytes_left <= frag_bytes_left - tx_bytes;

always_comb
  begin
    if( frag_bytes_left > MAX_FRAG_SIZE_WIDTH'( TDATA_WIDTH_B ) )
      if( bytes_in_buf > BUF_CNT_WIDTH'( TDATA_WIDTH_B ) )
        tx_bytes = ( BYTE_CNT_WIDTH + 1 )'( TDATA_WIDTH_B );
      else
        tx_bytes = ( BYTE_CNT_WIDTH + 1 )'( bytes_in_buf );
    else
      if( frag_bytes_left > MAX_FRAG_SIZE'( bytes_in_buf ) )
        tx_bytes = ( BYTE_CNT_WIDTH + 1 )'( bytes_in_buf );
      else
        tx_bytes = ( BYTE_CNT_WIDTH + 1 )'( frag_bytes_left );
  end

assign avail_bytes = bytes_in_buf > BUF_CNT_WIDTH'( TDATA_WIDTH_B ) ? ( BYTE_CNT_WIDTH + 1 )'( TDATA_WIDTH_B ) :
                                                                      ( BYTE_CNT_WIDTH + 1 )'( bytes_in_buf );

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    max_frag_size_lock <= '0;
  else
    if( was_eop && rx_handshake )
      max_frag_size_lock <= max_frag_size_i;

assign max_frag_size = was_eop && rx_handshake ? max_frag_size_i :
                                                 max_frag_size_lock;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    shift <= ( SHIFT_WIDTH + 1 )'( MAX_SHIFT );
  else
    if( pkt_o.tlast && bytes_in_buf == BUF_CNT_WIDTH'( tx_bytes ) && tx_handshake )
      shift <= ( SHIFT_WIDTH + 1 )'( MAX_SHIFT );
    else
      if( tx_handshake && rx_handshake )
        shift <= shift - ( SHIFT_WIDTH + 1 )'( TDATA_WIDTH_B ) + ( SHIFT_WIDTH + 1 )'( tx_bytes );
      else
        if( tx_handshake && !rx_handshake )
          shift <= shift + ( SHIFT_WIDTH + 1 )'( tx_bytes );
        else
          if( !tx_handshake && rx_handshake && bytes_in_buf > BUF_CNT_WIDTH'( 0 ) )
            shift <= shift - ( SHIFT_WIDTH + 1 )'( TDATA_WIDTH_B );



assign tdata_buf_shifted = tdata_buf >> 32'( shift ) * 8;
assign tstrb_buf_shifted = tstrb_buf >> shift;
assign tkeep_buf_shifted = tkeep_buf >> shift;

always_comb
  for( int i = 0; i < TDATA_WIDTH_B; i++ )
    if( ( BYTE_CNT_WIDTH + 1 )'( i ) < tx_bytes )
      begin
        pkt_o.tstrb[i] = tstrb_buf_shifted[i];
        pkt_o.tkeep[i] = tkeep_buf_shifted[i];
      end
    else
      begin
        pkt_o.tstrb[i] = 1'b0;
        pkt_o.tkeep[i] = 1'b0;
      end

assign pkt_o.tdata  = tdata_buf_shifted[TDATA_WIDTH_B - 1 : 0];
assign pkt_o.tlast  = bytes_in_buf == tx_bytes && was_eop || frag_bytes_left == tx_bytes || flush_flag && tx_bytes == bytes_in_buf;
assign pkt_o.tvalid = frag_bytes_left > MAX_FRAG_SIZE_WIDTH'( TDATA_WIDTH_B  ) ? bytes_in_buf >= BUF_CNT_WIDTH'( TDATA_WIDTH_B ) ||
                                                                                 was_eop && bytes_in_buf > BUF_CNT_WIDTH'( 0 ) :
                                                                                 bytes_in_buf >= BUF_CNT_WIDTH'( frag_bytes_left ) && frag_bytes_left != MAX_FRAG_SIZE_WIDTH'( 0 ) || 
                                                                                 was_eop && bytes_in_buf > BUF_CNT_WIDTH'( 0 );
assign pkt_o.tid    = tid_buf;
assign pkt_o.tdest  = tdest_buf;
assign pkt_o.tuser  = tuser_buf;
assign pkt_i.tready = bytes_in_buf < BUF_SIZE_W'( MAX_SHIFT ) && !flush_flag;// && ( bytes_in_buf == 0 || pkt_o.tready );

endmodule
