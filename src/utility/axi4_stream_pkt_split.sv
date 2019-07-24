module axi4_stream_pkt_split #(
  parameter int DATA_WIDTH     = 32,
  parameter int ID_WIDTH       = 1,
  parameter int DEST_WIDTH     = 1,
  parameter int USER_WIDTH     = 1,
  parameter int MAX_PKT_SIZE_B = 2048,
  parameter int PKT_SIZE_WIDTH = $clog2( MAX_PKT_SIZE_B )
)(
  input                      clk_i,
  input                      rst_i,
  input [PKT_SIZE_WIDTH : 0] max_pkt_size_i,
  axi4_stream_if             pkt_i,
  axi4_stream_if             pkt_o
);

localparam int DATA_WIDTH_B   = DATA_WIDTH / 8;
localparam int BYTE_CNT_WIDTH = $clog2( DATA_WIDTH_B );

logic [DATA_WIDTH - 1 : 0][1 : 0] data_buf;
logic                             word_buf_valid;
logic [ID_WIDTH - 1 : 0]          id_buf;
logic [DEST_WIDTH - 1 : 0]        dest_buf;
logic [USER_WIDTH - 1 : 0]        user_buf;
logic [DATA_WIDTH - 1 : 0][1 : 0] shifted_buf;
logic [BYTE_CNT_WIDTH : 0]        data_buf_shift;
logic [PKT_SIZE_WIDTH - 1 : 0]    rx_pkt_byte_cnt, rx_pkt_byte_cnt_comb;
logic [PKT_SIZE_WIDTH - 1 : 0]    tx_pkt_avail_bytes, tx_pkt_avail_bytes_comb;
logic [BYTE_CNT_WIDTH : 0]        unsent_bytes, unsent_bytes_comb;
logic [PKT_SIZE_WIDTH - 1 : 0]    tlast_bytes_left;
logic                             backpressure;
logic [DATA_WIDTH_B - 1 : 0]      pkt_o_usual_tstrb;
logic [DATA_WIDTH_B - 1 : 0]      pkt_o_tlast_tstrb;
logic                             pkt_o_cut_pkt;
logic [BYTE_CNT_WIDTH : 0]        pkt_i_valid_bytes;
logic                             last_transfer;

logic                             pkt_i_hsk;

enum logic [2 : 0] { IDLE_S,
                     ACC_S,
                     INC_UNSENT_S,
                     DEC_UNSENT_S,
                     PKT_I_TLAST_S } state, next_state;

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
          if( pkt_i_hsk )
            if( pkt_i.tlast )
              next_state = PKT_I_TLAST_S;
            else
              if( max_pkt_size_i <= DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
                next_state = INC_UNSENT_S;
              else
                next_state = ACC_S;
        end
      ACC_S:
        begin
          if( pkt_i_hsk )
            if( pkt_i.tlast )
              next_state = PKT_I_TLAST_S;
            else
              if( ( rx_pkt_byte_cnt + unsent_bytes ) >= max_pkt_size_i )
                next_state = DEC_UNSENT_S;
              else
                if( ( rx_pkt_byte_cnt + DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] ) >= max_pkt_size_i )
                  next_state = INC_UNSENT_S;
        end
      INC_UNSENT_S:
        begin
          if( pkt_i_hsk )
            if( unsent_bytes > max_pkt_size_i[BYTE_CNT_WIDTH : 0] )
              next_state = DEC_UNSENT_S;
            else
              if( pkt_i.tlast )
                next_state = PKT_I_TLAST_S;
              else
                if( max_pkt_size_i > DATA_WIDTH_B[BYTE_CNT_WIDTH : 0] )
                  next_state = ACC_S;
        end
      DEC_UNSENT_S:
        begin
          if( pkt_i_hsk )
            if( max_pkt_size_i > DATA_WIDTH_B[EMPTY_WIDTH : 0] )
              next_state = ACC_S;
            else
              if( unsent_bytes <= max_pkt_size_i[EMPTY_WIDTH : 0] )
                if( pkt_i.tlast )
                  next_state = PKT_I_TLAST_S;
                else
                  next_state = INC_UNSENT_S;
        end
      PKT_I_TLAST_S:
        begin
          if( last_transfer && pkt_o.tready )
            next_state = IDLE_S;
        end
    endcase
  end

assign pkt_o_usual_tstrb = DATA_WIDTH\[EMPTY_WIDTH - 1 : 0] - max_pkt_size_i[EMPTY_WIDTH - 1 : 0];


endmodule
