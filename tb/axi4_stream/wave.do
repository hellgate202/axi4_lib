onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /axi4_stream_example/dut_if/aclk
add wave -noupdate /axi4_stream_example/dut_if/aresetn
add wave -noupdate /axi4_stream_example/dut_if/tvalid
add wave -noupdate /axi4_stream_example/dut_if/tready
add wave -noupdate /axi4_stream_example/dut_if/tdata
add wave -noupdate /axi4_stream_example/dut_if/tstrb
add wave -noupdate /axi4_stream_example/dut_if/tkeep
add wave -noupdate /axi4_stream_example/dut_if/tlast
add wave -noupdate -radix unsigned /axi4_stream_example/dut_if/tid
add wave -noupdate -radix unsigned /axi4_stream_example/dut_if/tdest
add wave -noupdate /axi4_stream_example/dut_if/tuser
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {178383930 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 417
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
WaveRestoreZoom {0 ps} {914209800 ps}
