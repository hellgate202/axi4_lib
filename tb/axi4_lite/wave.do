onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /axi4_lite_example/dut_if/aclk
add wave -noupdate /axi4_lite_example/dut_if/aresetn
add wave -noupdate -divider {Address Write Channel}
add wave -noupdate /axi4_lite_example/dut_if/awvalid
add wave -noupdate /axi4_lite_example/dut_if/awready
add wave -noupdate /axi4_lite_example/dut_if/awaddr
add wave -noupdate /axi4_lite_example/dut_if/awprot
add wave -noupdate -divider {Write Data Channel}
add wave -noupdate /axi4_lite_example/dut_if/wvalid
add wave -noupdate /axi4_lite_example/dut_if/wready
add wave -noupdate /axi4_lite_example/dut_if/wdata
add wave -noupdate /axi4_lite_example/dut_if/wstrb
add wave -noupdate -divider {Write Response Channel}
add wave -noupdate /axi4_lite_example/dut_if/bvalid
add wave -noupdate /axi4_lite_example/dut_if/bready
add wave -noupdate /axi4_lite_example/dut_if/bresp
add wave -noupdate -divider {Address Read Channel}
add wave -noupdate /axi4_lite_example/dut_if/arvalid
add wave -noupdate /axi4_lite_example/dut_if/arready
add wave -noupdate /axi4_lite_example/dut_if/araddr
add wave -noupdate /axi4_lite_example/dut_if/arprot
add wave -noupdate -divider {Read Data Channel}
add wave -noupdate /axi4_lite_example/dut_if/rvalid
add wave -noupdate /axi4_lite_example/dut_if/rready
add wave -noupdate /axi4_lite_example/dut_if/rdata
add wave -noupdate /axi4_lite_example/dut_if/rresp
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {83775 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 261
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {36750 ps}
