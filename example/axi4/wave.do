onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /axi4_example/dut_if/aclk
add wave -noupdate /axi4_example/dut_if/aresetn
add wave -noupdate -divider {Write Address Channel}
add wave -noupdate -radix unsigned /axi4_example/dut_if/awid
add wave -noupdate /axi4_example/dut_if/awvalid
add wave -noupdate -radix hexadecimal /axi4_example/dut_if/awaddr
add wave -noupdate -radix unsigned /axi4_example/dut_if/awlen
add wave -noupdate -radix unsigned /axi4_example/dut_if/awsize
add wave -noupdate /axi4_example/dut_if/awburst
add wave -noupdate /axi4_example/dut_if/awlock
add wave -noupdate /axi4_example/dut_if/awcache
add wave -noupdate /axi4_example/dut_if/awprot
add wave -noupdate /axi4_example/dut_if/awqos
add wave -noupdate -radix unsigned /axi4_example/dut_if/awregion
add wave -noupdate /axi4_example/dut_if/awuser
add wave -noupdate /axi4_example/dut_if/awready
add wave -noupdate -divider {Write Data Channel}
add wave -noupdate -radix hexadecimal /axi4_example/dut_if/wdata
add wave -noupdate /axi4_example/dut_if/wstrb
add wave -noupdate /axi4_example/dut_if/wlast
add wave -noupdate /axi4_example/dut_if/wuser
add wave -noupdate /axi4_example/dut_if/wvalid
add wave -noupdate /axi4_example/dut_if/wready
add wave -noupdate -divider {Write Response Channel}
add wave -noupdate -radix unsigned /axi4_example/dut_if/bid
add wave -noupdate /axi4_example/dut_if/bresp
add wave -noupdate /axi4_example/dut_if/buser
add wave -noupdate /axi4_example/dut_if/bvalid
add wave -noupdate /axi4_example/dut_if/bready
add wave -noupdate -divider {Address Read Channel}
add wave -noupdate -radix unsigned /axi4_example/dut_if/arid
add wave -noupdate -radix hexadecimal /axi4_example/dut_if/araddr
add wave -noupdate -radix unsigned /axi4_example/dut_if/arlen
add wave -noupdate -radix unsigned /axi4_example/dut_if/arsize
add wave -noupdate /axi4_example/dut_if/arburst
add wave -noupdate /axi4_example/dut_if/arlock
add wave -noupdate /axi4_example/dut_if/arcache
add wave -noupdate /axi4_example/dut_if/arprot
add wave -noupdate /axi4_example/dut_if/arqos
add wave -noupdate -radix unsigned /axi4_example/dut_if/arregion
add wave -noupdate /axi4_example/dut_if/aruser
add wave -noupdate /axi4_example/dut_if/arvalid
add wave -noupdate /axi4_example/dut_if/arready
add wave -noupdate -divider {Read Data Channel}
add wave -noupdate -radix unsigned /axi4_example/dut_if/rid
add wave -noupdate -radix hexadecimal /axi4_example/dut_if/rdata
add wave -noupdate /axi4_example/dut_if/rresp
add wave -noupdate /axi4_example/dut_if/rlast
add wave -noupdate /axi4_example/dut_if/ruser
add wave -noupdate /axi4_example/dut_if/rvalid
add wave -noupdate /axi4_example/dut_if/rready
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1674642 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 265
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
WaveRestoreZoom {17213 ps} {7246463 ps}
