onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider pkt_i
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_i/aclk
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_i/aresetn
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_i/tvalid
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_i/tready
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_i/tdata
add wave -noupdate -radix binary /tb_axi4_stream_shifter/DUT/pkt_i/tstrb
add wave -noupdate -radix binary /tb_axi4_stream_shifter/DUT/pkt_i/tkeep
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_i/tlast
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_i/tid
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_i/tdest
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_i/tuser
add wave -noupdate -divider DUT
add wave -noupdate /tb_axi4_stream_shifter/DUT/clk_i
add wave -noupdate /tb_axi4_stream_shifter/DUT/rst_i
add wave -noupdate /tb_axi4_stream_shifter/DUT/shift_i
add wave -noupdate /tb_axi4_stream_shifter/DUT/tdata_buf
add wave -noupdate -radix binary /tb_axi4_stream_shifter/DUT/tstrb_buf
add wave -noupdate -radix binary /tb_axi4_stream_shifter/DUT/tkeep_buf
add wave -noupdate /tb_axi4_stream_shifter/DUT/shifted_tdata_buf
add wave -noupdate -radix binary /tb_axi4_stream_shifter/DUT/shifted_tstrb_buf
add wave -noupdate -radix binary /tb_axi4_stream_shifter/DUT/shifted_tkeep_buf
add wave -noupdate -radix binary /tb_axi4_stream_shifter/DUT/tstrb_masked_tlast
add wave -noupdate -radix binary /tb_axi4_stream_shifter/DUT/tkeep_masked_tlast
add wave -noupdate -radix binary /tb_axi4_stream_shifter/DUT/tstrb_masked_tfirst
add wave -noupdate -radix binary /tb_axi4_stream_shifter/DUT/tkeep_masked_tfirst
add wave -noupdate -radix unsigned /tb_axi4_stream_shifter/DUT/rx_bytes
add wave -noupdate -radix unsigned /tb_axi4_stream_shifter/DUT/tx_bytes
add wave -noupdate -radix unsigned /tb_axi4_stream_shifter/DUT/bytes_in_buf
add wave -noupdate /tb_axi4_stream_shifter/DUT/tfirst
add wave -noupdate /tb_axi4_stream_shifter/DUT/tlast_lock
add wave -noupdate /tb_axi4_stream_shifter/DUT/tfirst_lock
add wave -noupdate /tb_axi4_stream_shifter/DUT/backpressure
add wave -noupdate -divider pkt_o
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_o/aclk
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_o/aresetn
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_o/tvalid
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_o/tready
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_o/tdata
add wave -noupdate -radix binary /tb_axi4_stream_shifter/DUT/pkt_o/tstrb
add wave -noupdate -radix binary /tb_axi4_stream_shifter/DUT/pkt_o/tkeep
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_o/tlast
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_o/tid
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_o/tdest
add wave -noupdate /tb_axi4_stream_shifter/DUT/pkt_o/tuser
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1077500 ps} 0}
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
WaveRestoreZoom {0 ps} {2569875 ps}
