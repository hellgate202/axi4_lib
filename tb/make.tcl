proc compile_src { name } {
  vlib work
  vlog -sv -incr -f ./$name/files 
}

proc draw_waveforms { tb_name } {
  if { [file exists "./$tb_name/wave.do"] } {
    do ./$tb_name/wave.do
  }
}

proc axi4_lite {} {
  compile_src axi4_lite
  vopt +acc axi4_lite_example -o axi4_lite_example_opt
  vsim axi4_lite_example_opt
  draw_waveforms axi4_lite
  run -all
}

proc axi4_stream {} {
  compile_src axi4_stream
  vopt +acc axi4_stream_example -o axi4_stream_example_opt
  vsim axi4_stream_example_opt
  draw_waveforms axi4_stream
  run -all
}

proc axi4_stream_pkt_frag {} {
  compile_src axi4_stream_pkt_frag
  vopt +acc tb_axi4_stream_pkt_frag -o tb_axi4_stream_pkt_frag_opt
  vsim tb_axi4_stream_pkt_frag_opt
  draw_waveforms axi4_stream_pkt_frag
  run -all
}

proc axi4_stream_byte_shift {} {
  compile_src axi4_stream_byte_shift
  vopt +acc tb_axi4_stream_byte_shift -o tb_axi4_stream_byte_shift_opt
  vsim tb_axi4_stream_byte_shift_opt
  draw_waveforms axi4_stream_byte_shift
  run -all
}

proc axi4_stream_upsizer {} {
  compile_src axi4_stream_upsizer
  vopt +acc tb_axi4_stream_upsizer -o tb_axi4_stream_upsizer_opt
  vsim tb_axi4_stream_upsizer_opt
  draw_waveforms axi4_stream_upsizer
  run -all
}

proc axi4 {} {
  compile_src axi4
  vopt +acc axi4_example -o axi4_example_opt
  vsim axi4_example_opt
  draw_waveforms axi4
  run -all
}


proc help {} {
  echo "axi4                   - AXI4 example."
  echo "axi4_lite              - AXI4 Lite example."
  echo "axi4_stream            - AXI4 Stream example."
  echo "axi4_stream_pkt_frag   - AXI4 Stream Packet Splitter Testbench"
  echo "axi4_stream_byte_shift - AXI4 Stream Byte Shifter"
  echo "axi4_stream_upsizer    - AXI4 Stream Upsizer"
  echo "Type help to repeat this message."
}

help
