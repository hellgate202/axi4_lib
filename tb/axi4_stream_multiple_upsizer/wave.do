onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_i/aclk
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_i/aresetn
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_i/tvalid
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_i/tready
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_i/tdata
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_i/tstrb
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_i/tkeep
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_i/tlast
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_i/tid
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_i/tdest
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_i/tuser
add wave -noupdate /tb_axi4_stream_multiple_upsizer/DUT/rx_handshake
add wave -noupdate /tb_axi4_stream_multiple_upsizer/DUT/tx_handshake
add wave -noupdate /tb_axi4_stream_multiple_upsizer/DUT/ins_pos
add wave -noupdate /tb_axi4_stream_multiple_upsizer/DUT/tfirst
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_o/aclk
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_o/aresetn
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_o/tvalid
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_o/tready
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_o/tdata
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_o/tstrb
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_o/tkeep
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_o/tlast
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_o/tid
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_o/tdest
add wave -noupdate /tb_axi4_stream_multiple_upsizer/pkt_o/tuser
add wave -noupdate /tb_axi4_stream_multiple_upsizer/DUT/clk_i
add wave -noupdate /tb_axi4_stream_multiple_upsizer/DUT/rst_i
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {344550000 ps} 0}
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
WaveRestoreZoom {0 ps} {58501773750 ps}
