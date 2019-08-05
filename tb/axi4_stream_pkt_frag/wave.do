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
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/data_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tstrb_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tkeep_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/buf_valid
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/shifted_data_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/shifted_tstrb_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/shifted_tkeep_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/buf_shift
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tid_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tdest_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tuser_buf
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/rx_pkt_byte_cnt
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/frag_avail_bytes
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/unsent_bytes
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/pkt_bytes_left
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/backpressure
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/val_bytes_eof
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/last_frag_val_bytes_eof
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/eof_during_eop
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/last_frag_eof
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/rx_valid_bytes
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tx_valid_bytes
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tlast_lock
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tfirst
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tstrb_eof
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tstrb_last_frag_eof
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tkeep_eof
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/tkeep_last_frag_eof
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/state
add wave -noupdate /tb_axi4_stream_pkt_frag/DUT/next_state
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
WaveRestoreCursors {{Cursor 1} {15032500 ps} 0}
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
WaveRestoreZoom {0 ps} {2253481125 ps}
