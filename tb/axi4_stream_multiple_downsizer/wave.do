onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_i/aclk
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_i/aresetn
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_i/tvalid
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_i/tready
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_i/tdata
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_i/tstrb
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_i/tkeep
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_i/tlast
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_i/tid
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_i/tdest
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_i/tuser
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/clk_i
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/rst_i
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/rx_handshake
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/tx_handshake
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/ins_pos
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/tdata_buf
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/tstrb_buf
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/tkeep_buf
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/tuser_buf
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/tdest_buf
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/tid_buf
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/tlast_buf
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/word_lock
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/syms_in_rx_w
add wave -noupdate /tb_axi4_stream_multiple_downsizer/DUT/syms_in_rx_w_lock
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_o/aclk
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_o/aresetn
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_o/tvalid
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_o/tready
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_o/tdata
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_o/tstrb
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_o/tkeep
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_o/tlast
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_o/tid
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_o/tdest
add wave -noupdate /tb_axi4_stream_multiple_downsizer/pkt_o/tuser
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {147459211 ps} 0}
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
WaveRestoreZoom {0 ps} {7099107750 ps}
