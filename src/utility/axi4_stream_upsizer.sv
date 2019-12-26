module axi4_stream_upsizer #(
  parameter int RX_TDATA_WIDTH = 16,
  parameter int TX_TDATA_WIDTH = 64,
  parameter int TID_WIDTH      = 1,
  parameter int TDEST_WIDTH    = 1,
  parameter int TUSER_WIDTH    = 1
)(
  input                 clk_i,
  input                 rst_i,
  axi4_stream_if.slave  pkt_i,
  axi4_stream_if.master pkt_o
);

localparam int RX_TDATA_WIDTH_B   = RX_TDATA_WIDTH / 8;
localparam int TX_TDATA_WIDTH_B   = TX_TDATA_WIDTH / 8;
// How many bytes can be in buffer in worst case 
localparam int MAX_BYTES_IN_BUF   = TX_TDATA_WIDTH_B % RX_TDATA_WIDTH_B ?
                                    TX_TDATA_WIDTH_B + RX_TDATA_WIDTH_B - 1 : 
                                    TX_TDATA_WIDTH_B;
// Rounded up to input word size
localparam int BUF_WIDTH_W        = MAX_BYTES_IN_BUF % RX_TDATA_WIDTH_B ?
                                    MAX_BYTES_IN_BUF / RX_TDATA_WIDTH_B + 1 :
                                    MAX_BYTES_IN_BUF / RX_TDATA_WIDTH_B;
localparam int BUF_WIDTH_B        = BUF_WIDTH_W * RX_TDATA_WIDTH_B;
// How many input words required to handle one output word
localparam int RX_W_IN_TX_W       = TX_TDATA_WIDTH_B % RX_TDATA_WIDTH_B ?
                                    TX_TDATA_WIDTH_B / RX_TDATA_WIDTH_B + 1 :
                                    TX_TDATA_WIDTH_B / RX_TDATA_WIDTH_B;
localparam int DEFAULT_SHIFT      = ( BUF_WIDTH_W - RX_W_IN_TX_W ) * RX_TDATA_WIDTH_B;
localparam int SHIFT_WIDTH        = $clog2( MAX_BYTES_IN_BUF );
localparam int RX_BYTE_CNT_WIDTH  = $clog2( RX_TDATA_WIDTH_B ) + 1;
localparam int TX_BYTE_CNT_WIDTH  = $clog2( TX_TDATA_WIDTH_B ) + 1;
localparam int BUF_CNT_WIDTH      = $clog2( BUF_WIDTH_B ) + 1;

logic [BUF_WIDTH_W - 1 : 0][RX_TDATA_WIDTH - 1 : 0]   tdata_buf;
logic [BUF_WIDTH_W - 1 : 0][RX_TDATA_WIDTH_B - 1 : 0] tkeep_buf;
logic [BUF_WIDTH_W - 1 : 0][RX_TDATA_WIDTH_B - 1 : 0] tstrb_buf;
logic [BUF_WIDTH_B - 1 : 0][7 : 0]                    tdata_buf_shifted;
logic [BUF_WIDTH_B - 1 : 0]                           tkeep_buf_shifted;
logic [BUF_WIDTH_B - 1 : 0]                           tstrb_buf_shifted;
logic [TID_WIDTH - 1 : 0]                             tid_buf;
logic [TDEST_WIDTH - 1 : 0]                           tdest_buf;
logic [TUSER_WIDTH - 1 : 0]                           tuser_buf;
logic [SHIFT_WIDTH - 1 : 0]                           shift;
logic [BUF_CNT_WIDTH - 1 : 0]                         bytes_in_buf;
logic                                                 rx_handshake;
logic                                                 tx_handshake;
logic                                                 flush_flag;
logic [RX_BYTE_CNT_WIDTH - 1 : 0]                     rx_bytes;
logic [TX_BYTE_CNT_WIDTH - 1 : 0]                     tx_bytes;
logic                                                 backpressure;
logic                                                 tfirst;

assign rx_handshake = pkt_i.tready && pkt_i.tvalid;
assign tx_handshake = pkt_o.tready && pkt_o.tvalid;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      tdata_buf <= ( BUF_WIDTH_B * 8 )'( 0 );
      tkeep_buf <= ( BUF_WIDTH_B )'( 0 );
      tstrb_buf <= ( BUF_WIDTH_B )'( 0 );
    end
  else
    if( rx_handshake )
      begin
        tdata_buf <= { pkt_i.tdata, tdata_buf[BUF_WIDTH_W - 1 : 1] };
        tkeep_buf <= { pkt_i.tkeep, tkeep_buf[BUF_WIDTH_W - 1 : 1] };
        tstrb_buf <= { pkt_i.tstrb, tstrb_buf[BUF_WIDTH_W - 1 : 1] };
      end

assign tdata_buf_shifted = tdata_buf >> ( shift * 8 );
assign tkeep_buf_shifted = tkeep_buf >> shift;
assign tstrb_buf_shifted = tstrb_buf >> shift;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    shift <= SHIFT_WIDTH'( DEFAULT_SHIFT );
  else
    if( flush_flag )
      if( bytes_in_buf < BUF_CNT_WIDTH'( TX_TDATA_WIDTH_B ) )
        shift <= shift + SHIFT_WIDTH'( BUF_CNT_WIDTH'( TX_TDATA_WIDTH_B ) - bytes_in_buf )
/*
    if( tx_handshake )
      if( flush_flag )
        if( tx_bytes == bytes_in_buf )
          shift <= SHIFT_WIDTH'( DEFAULT_SHIFT );
        else
          shift <= shift + tx_bytes;
      else
        shift <= SHIFT_WIDTH'( BUF_CNT_WIDTH'( DEFAULT_SHIFT - TX_TDATA_WIDTH_B ) - bytes_in_buf );
*/
always_comb
  begin
    rx_bytes = '0;
    if( pkt_i.tvalid )
      if( pkt_i.tlast )
        begin
          for( integer lmo = 0; lmo < RX_TDATA_WIDTH_B; lmo++ )
            if( pkt_i.tkeep[lmo] )
              rx_bytes = RX_BYTE_CNT_WIDTH'( lmo ) + 1'b1;
        end
      else
        rx_bytes = RX_BYTE_CNT_WIDTH'( RX_TDATA_WIDTH_B );
  end

always_comb
  if( bytes_in_buf >= BUF_CNT_WIDTH'( TX_TDATA_WIDTH_B ) )
    tx_bytes = TX_BYTE_CNT_WIDTH'( TX_TDATA_WIDTH_B );
  else
    if( flush_flag )
      tx_bytes = TX_BYTE_CNT_WIDTH'( bytes_in_buf );
    else
      tx_bytes = TX_BYTE_CNT_WIDTH'( 0 );

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    bytes_in_buf <= BUF_CNT_WIDTH'( 0 );
  else
    if( tx_handshake && rx_handshake )
      bytes_in_buf <= bytes_in_buf + BUF_CNT_WIDTH'( rx_bytes ) - BUF_CNT_WIDTH'( tx_bytes );
    else
      if( tx_handshake )
        bytes_in_buf <= bytes_in_buf - BUF_WIDTH_W'( tx_bytes );
      else
        if( rx_handshake )
          bytes_in_buf <= bytes_in_buf + BUF_WIDTH_W'( rx_bytes );

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    flush_flag <= 1'b0;
  else
    if( rx_handshake && pkt_i.tlast )
      flush_flag <= 1'b1;
    else
      if( bytes_in_buf == BUF_CNT_WIDTH'( tx_bytes ) )
        flush_flag <= 1'b0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    tfirst <= 1'b1;
  else
    if( rx_handshake )
      if( pkt_i.tlast )
        tfirst <= 1'b1;
      else
        tfirst <= 1'b0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      tid_buf   <= TID_WIDTH'( 0 );
      tdest_buf <= TDEST_WIDTH'( 0 );
      tuser_buf <= TUSER_WIDTH'( 0 );
    end
  else
    if( tfirst )
      begin
        tid_buf   <= pkt_i.tid;
        tdest_buf <= pkt_i.tdest;
        tuser_buf <= pkt_i.tuser;
      end
    else
      if( tx_handshake )
        begin
          tid_buf   <= TID_WIDTH'( 0 );
          tdest_buf <= TDEST_WIDTH'( 0 );
          tuser_buf <= TUSER_WIDTH'( 0 );
        end

assign backpressure = flush_flag && bytes_in_buf > BUF_CNT_WIDTH'( TX_TDATA_WIDTH_B );

assign pkt_i.tready = pkt_o.tready && !backpressure;
assign pkt_o.tvalid = bytes_in_buf >= BUF_CNT_WIDTH'( TX_TDATA_WIDTH_B ) || flush_flag;
assign pkt_o.tdata  = tdata_buf_shifted[TX_TDATA_WIDTH_B - 1 : 0];
assign pkt_o.tkeep  = tkeep_buf_shifted[TX_TDATA_WIDTH_B - 1 : 0];
assign pkt_o.tstrb  = tstrb_buf_shifted[TX_TDATA_WIDTH_B - 1 : 0];
assign pkt_o.tlast  = flush_flag && bytes_in_buf == BUF_CNT_WIDTH'( tx_bytes );
assign pkt_o.tid    = tid_buf;
assign pkt_o.tdest  = tdest_buf;
assign pkt_o.tuser  = tuser_buf;

endmodule
