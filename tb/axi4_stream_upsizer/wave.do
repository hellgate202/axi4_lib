onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider pkt_i
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_i/aclk
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_i/aresetn
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_i/tvalid
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_i/tready
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_i/tdata
add wave -noupdate -radix binary /tb_axi4_stream_upsizer/DUT/pkt_i/tstrb
add wave -noupdate -radix binary /tb_axi4_stream_upsizer/DUT/pkt_i/tkeep
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_i/tlast
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_i/tid
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_i/tdest
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_i/tuser
add wave -noupdate -divider DUT
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/RX_TDATA_WIDTH
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/TX_TDATA_WIDTH
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/TID_WIDTH
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/TDEST_WIDTH
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/TUSER_WIDTH
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/RX_TDATA_WIDTH_B
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/TX_TDATA_WIDTH_B
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/MAX_BYTES_IN_BUF
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/BUF_WIDTH_W
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/BUF_WIDTH_B
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/RX_W_IN_TX_W
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/VALID_BUF_POS
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/VALID_BUF_POS_B
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/SHIFT_WIDTH
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/RX_BYTE_CNT_WIDTH
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/TX_BYTE_CNT_WIDTH
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/BUF_CNT_WIDTH
add wave -noupdate /tb_axi4_stream_upsizer/DUT/clk_i
add wave -noupdate /tb_axi4_stream_upsizer/DUT/rst_i
add wave -noupdate /tb_axi4_stream_upsizer/DUT/tdata_buf
add wave -noupdate -radix binary /tb_axi4_stream_upsizer/DUT/tkeep_buf
add wave -noupdate -radix binary /tb_axi4_stream_upsizer/DUT/tstrb_buf
add wave -noupdate /tb_axi4_stream_upsizer/DUT/tid_buf
add wave -noupdate /tb_axi4_stream_upsizer/DUT/tdest_buf
add wave -noupdate /tb_axi4_stream_upsizer/DUT/tuser_buf
add wave -noupdate /tb_axi4_stream_upsizer/DUT/valid_bytes_buf
add wave -noupdate /tb_axi4_stream_upsizer/DUT/shift
add wave -noupdate /tb_axi4_stream_upsizer/DUT/tdata_buf_shifted
add wave -noupdate -radix binary /tb_axi4_stream_upsizer/DUT/tkeep_buf_shifted
add wave -noupdate -radix binary /tb_axi4_stream_upsizer/DUT/tstrb_buf_shifted
add wave -noupdate -radix binary /tb_axi4_stream_upsizer/DUT/valid_bytes_buf_shifted
add wave -noupdate -radix binary /tb_axi4_stream_upsizer/DUT/valid_bytes
add wave -noupdate /tb_axi4_stream_upsizer/DUT/rx_handshake
add wave -noupdate /tb_axi4_stream_upsizer/DUT/tx_handshake
add wave -noupdate /tb_axi4_stream_upsizer/DUT/flush_flag
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/rx_bytes
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/tx_bytes
add wave -noupdate -radix unsigned /tb_axi4_stream_upsizer/DUT/bytes_in_buf
add wave -noupdate /tb_axi4_stream_upsizer/DUT/tfirst
add wave -noupdate /tb_axi4_stream_upsizer/DUT/backpressure
add wave -noupdate -divider pkt_o
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_o/aclk
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_o/aresetn
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_o/tvalid
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_o/tready
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_o/tdata
add wave -noupdate -radix binary /tb_axi4_stream_upsizer/DUT/pkt_o/tstrb
add wave -noupdate -radix binary /tb_axi4_stream_upsizer/DUT/pkt_o/tkeep
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_o/tlast
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_o/tid
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_o/tdest
add wave -noupdate /tb_axi4_stream_upsizer/DUT/pkt_o/tuser
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {46804 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 428
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {144375 ps}
