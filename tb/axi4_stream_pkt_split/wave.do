onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider pkt_i
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/rx_if/aclk
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/rx_if/aresetn
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/rx_if/tvalid
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/rx_if/tready
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/rx_if/tdata
add wave -noupdate -radix binary /tb_axi4_stream_pkt_split/rx_if/tstrb
add wave -noupdate -radix binary /tb_axi4_stream_pkt_split/rx_if/tkeep
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/rx_if/tlast
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/rx_if/tid
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/rx_if/tdest
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/rx_if/tuser
add wave -noupdate -divider DUT
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/clk_i
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/rst_i
add wave -noupdate -radix unsigned /tb_axi4_stream_pkt_split/DUT/max_pkt_size_i
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/data_buf
add wave -noupdate -radix binary /tb_axi4_stream_pkt_split/DUT/tstrb_buf
add wave -noupdate -radix binary /tb_axi4_stream_pkt_split/DUT/tkeep_buf
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/buf_valid
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/tid_buf
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/tdest_buf
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/tuser_buf
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/shifted_data_buf
add wave -noupdate -radix binary /tb_axi4_stream_pkt_split/DUT/shifted_tstrb_buf
add wave -noupdate -radix binary /tb_axi4_stream_pkt_split/DUT/shifted_tkeep_buf
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/buf_shift
add wave -noupdate -radix unsigned /tb_axi4_stream_pkt_split/DUT/rx_pkt_byte_cnt
add wave -noupdate -radix unsigned /tb_axi4_stream_pkt_split/DUT/rx_pkt_byte_cnt_comb
add wave -noupdate -radix unsigned /tb_axi4_stream_pkt_split/DUT/tx_pkt_avail_bytes
add wave -noupdate -radix unsigned /tb_axi4_stream_pkt_split/DUT/tx_pkt_avail_bytes_comb
add wave -noupdate -radix unsigned /tb_axi4_stream_pkt_split/DUT/unsent_bytes
add wave -noupdate -radix unsigned /tb_axi4_stream_pkt_split/DUT/unsent_bytes_comb
add wave -noupdate -radix unsigned /tb_axi4_stream_pkt_split/DUT/int_bytes_left
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/backpressure
add wave -noupdate -radix unsigned /tb_axi4_stream_pkt_split/DUT/usual_bytes_tlast
add wave -noupdate -radix unsigned /tb_axi4_stream_pkt_split/DUT/int_bytes_tlast
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/tlast_during_int
add wave -noupdate -radix unsigned /tb_axi4_stream_pkt_split/DUT/rx_valid_bytes
add wave -noupdate -radix unsigned /tb_axi4_stream_pkt_split/DUT/tx_valid_bytes
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/last_transfer
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/tlast_lock
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/tfirst
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/state
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/DUT/next_state
add wave -noupdate -radix binary /tb_axi4_stream_pkt_split/DUT/tstrb_masked_usual
add wave -noupdate -radix binary /tb_axi4_stream_pkt_split/DUT/tstrb_masked_int
add wave -noupdate -radix binary /tb_axi4_stream_pkt_split/DUT/tkeep_masked_usual
add wave -noupdate -radix binary /tb_axi4_stream_pkt_split/DUT/tkeep_masked_int
add wave -noupdate -divider pkt_o
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/tx_if/aclk
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/tx_if/aresetn
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/tx_if/tvalid
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/tx_if/tready
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/tx_if/tdata
add wave -noupdate -radix binary /tb_axi4_stream_pkt_split/tx_if/tstrb
add wave -noupdate -radix binary /tb_axi4_stream_pkt_split/tx_if/tkeep
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/tx_if/tlast
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/tx_if/tid
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/tx_if/tdest
add wave -noupdate -radix hexadecimal /tb_axi4_stream_pkt_split/tx_if/tuser
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {202442500 ps} 0}
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
WaveRestoreZoom {0 ps} {858199125 ps}
