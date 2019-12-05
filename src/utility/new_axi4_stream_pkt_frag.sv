module axi4_stream_pkt_frag #(
  parameter int TDATA_WIDTH         = 64,
  parameter int TID_WIDTH           = 1,
  parameter int TDEST_WIDTH         = 1,
  parameter int TUSER_WIDTH         = 1,
  parameter int MAX_FRAG_SIZE       = 2048,
  parameter int MAX_FRAG_SIZE_WIDTH = $clog2( MAX_FRAG_SIZE )
)(
  input                               clk_i,
  input                               rst_i,
  input [MAX_FRAG_SIZE_WIDTH - 1 : 0] max_frag_size_i,
  axi4_stream_if.slave                pkt_i,
  axi4_stream_if.master               pkt_o
);

localparam int DATA_WIDTH_B   = TDATA_WIDTH / 8;
localparam int BYTE_CNT_WIDTH = $clog2( DATA_WIDTH_B );
localparam int BUF_SIZE_W     = DATA_WIDTH_B * 3;
localparam int BUF_CNT_WIDTH  = $clog2( BUF_SIZE_W );
localparam int MAX_SHIFT      = DATA_WIDTH_B * 2;
localparam int SHIFT_WIDTH    = $clog2( MAX_SHIFT );

logic                               rx_handshake;
logic                               tx_handshake;
logic [BYTE_CNT_WIDTH : 0]          rx_bytes;
logic [BYTE_CNT_WIDTH : 0]          tx_bytes;
logic [BUF_SIZE_W - 1 : 0][7 : 0]   tdata_buf;
logic [BUF_SIZE_W - 1 : 0][7 : 0]   tdata_buf_shifted;
logic [BUF_SIZE_W - 1 : 0]          tstrb_buf;
logic [BUF_SIZE_W - 1 : 0]          tstrb_buf_shifted;
logic [BUF_SIZE_W - 1 : 0]          tkeep_buf;
logic [BUF_SIZE_W - 1 : 0]          tkeep_buf_shifted;
logic [TID_WIDTH - 1 : 0]           tid_buf;
logic [TDEST_WIDTH - 1 : 0]         tdest_buf;
logic [TUSER_WIDTH - 1 : 0]         tuser_buf;
logic [BUF_CNT_WIDTH - 1 : 0]       bytes_in_buf;
logic [SHIFT_WIDTH - 1 : 0]         bytes_in_debt;
logic                               shift_valid;
logic [MAX_FRAG_SIZE_WIDTH - 1 : 0] frag_bytes_left;
logic                               was_eop;

assign rx_handshake = pkt_i.tvalid && pkt_i.tready;
assign tx_handshake = pkt_o.tvalid && pkt_o.tready;

// Amount of bytes in RX word
always_comb
  begin
    rx_bytes = ( BYTE_CNT_WIDTH + 1 )'d0;
    for( int i = 0; i < DATA_WIDTH_B; i++ )
      if( pkt_i.tkeep[i] ) 
        rx_bytes++;
  end

// Shift reg for data
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      tdata_buf <= ( BUF_SIZE_W * 8 )'d0;
      tstrb_buf <= BUF_SIZE_W'd0;
      tkeep_buf <= BUF_SIZE_W'd0;
      tid_buf   <= TID_WIDTH'd0;
      tdest_buf <= TDEST_WIDTH'd0;
      tuser_buf <= TUSER_WIDTH'd0;
    end
  else
    if( rx_handshake )
      begin
        tdata_buf <= { pkt_i.tdata, tdata_buf[MAX_SHIFT - 1 : 0] };
        tstrb_buf <= { pkt_i.tstrb, tstrb_buf[MAX_SHIFT - 1 : 0] };
        tkeep_buf <= { pkt_i.tkeep, tkeep_buf[MAX_SHIFT - 1 : 0] };
        tid_buf   <= pkt_i.tid;
        tdest_buf <= pkt_i.tdest;
        tuser_buf <= pkt_i.tuser;
      end

// Amount of unsent bytes in buffer
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    bytes_in_buf <= BUF_CNT_WIDTH'd0;
  else
    if( rx_handshake && tx_handshake )
      bytes_in_buf <= bytes_in_buf + rx_bytes - tx_bytes;
    else
      if( rx_handshake )
        bytes_in_buf <= bytes_in_buf + rx_bytes;
      else
        if( tx_handshake )
          bytes_in_buf <= bytes_in_buf - tx_bytes;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    was_eop <= 1'b0;
  else
    if( rx_handshake )
      if( pkt_i.tlast )
        was_eop <= 1'b1;
      else
        was_eop <= 1'b0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    frag_bytes_left <= '0;
  else
    if( pkt_o.tlast )
      frag_bytes_left <= max_frag_size_i;
    else
      if( tx_handshake )
        frag_bytes_left <= frag_bytes_left - tx_bytes;

always_comb
  begin
    if( frag_bytes_left > MAX_FRAG_SIZE_WIDTH'( DATA_WIDTH_B ) )
      if( bytes_in_buf > BUF_CNT_WIDTH'( DATA_WIDTH_B )
        tx_bytes = BYTE_CNT_WIDTH'( DATA_WIDTH_B );
      else
        tx_bytes = BYTE_CNT_WIDTH'( bytes_in_buf );
    else
      if( frag_bytes_left > MAX_FRAG_SIZE'( bytes_in_buf ) )
        tx_bytes = BYTE_CNT_WIDTH'( bytes_in_buf );
      else
        tx_bytes = BYTE_CNT_WIDTH'( frag_bytes_left );
  end

// Amount of bytes in buffer that will left after sending current word
assign bytes_in_debt = SHIFT_WIDTH'( bytes_in_buf - BUF_CNT_WIDTH'( DATA_WIDTH_B ) );
assign shift_valid   = bytes_in_buf > BUF_CNT_WIDTH'( DATA_WIDTH_B );

assign tdata_buf_shifted = shift_valid ? tdata_buf << bytes_in_debt : tdata_buf;
assign tstrb_buf_shifted = shift_valid ? tstrb_buf << bytes_in_debt : tstrb_buf;
assign tkeep_buf_shifted = shift_valid ? tkeep_buf << bytes_in_debt : tkeep_buf;

always_comb
  for( int i = 0; i < DATA_WIDTH_B; i++ )
    if( BYTE_CNT_WIDTH'( i ) <= tx_bytes )
      begin
        pkt_o.tstrb[i] = tstrb_buf_shifted[BUF_SIZE_W - 1 - i];
        pkt_o.tkeep[i] = tkeep_buf_shifted[BUF_SIZE_W - 1 - i];
      end
    else
      begin
        pkt_o.tstrb[i] = 1'b0;
        pkt_o.tkeep[i] = 1'b0;
      end

assign pkt_o.tdata  = tdata_buf_shifted[BUF_SIZE_W - 1 -: DATA_WIDTH_B];
assign pkt_o.tlast  = tx_bytes < BYTE_CNT_WIDTH'( DATA_WIDTH_B ) ||
                      BUF_CNT_WIDTH'( tx_bytes ) == bytes_in_buf
assign pkt_o.tvalid = bytes_in_buf > BUF_CNT_WIDTH'd0;
assign pkt_o.tid    = tid_buf;
assign pkt_o.tdest  = tdest_buf;
assign pkt_o.tuser  = tuser_buf;
assign pkt_i.tready = bytes_in_debt > SHIFT_WIDTH'( DATA_WIDTH_B ) || was_eop && bytes_in_buf > '0;

endmodule
