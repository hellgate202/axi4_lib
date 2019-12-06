onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider pkt_i
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_i/aclk
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_i/aresetn
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_i/tvalid
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_i/tready
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_i/tdata
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_i/tstrb
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_i/tkeep
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_i/tlast
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_i/tid
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_i/tdest
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_i/tuser
add wave -noupdate -divider DUT
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/clk_i
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/rst_i
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/max_frag_size_i
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/rx_handshake
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tx_handshake
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/rx_bytes
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tx_bytes
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/shift
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tdata_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tdata_buf_shifted
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tstrb_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tstrb_buf_shifted
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tkeep_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tkeep_buf_shifted
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tid_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tdest_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tuser_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/bytes_in_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/avail_bytes
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/frag_bytes_left
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/was_eop
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/flush_flag
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/max_frag_size_lock
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/max_frag_size
add wave -noupdate -divider pkt_o
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_o/aclk
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_o/aresetn
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_o/tvalid
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_o/tready
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_o/tdata
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_o/tstrb
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_o/tkeep
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_o/tlast
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_o/tid
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_o/tdest
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_o/tuser
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {39034 ps} 0}
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
WaveRestoreZoom {0 ps} {49875 ps}
