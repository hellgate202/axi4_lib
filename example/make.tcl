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
  vsim axi4_lite_example
  draw_waveforms axi4_lite
  run -all
}

proc axi4_stream {} {
  compile_src axi4_stream
  vsim axi4_stream_example
  draw_waveforms axi4_stream
  run -all
}

proc axi4 {} {
  compile_src axi4
  vsim axi4_example
  draw_waveforms axi4
  run -all
}

proc help {} {
  echo "Type following one of following commands to run appropriate example:"
  echo "axi4        - AXI4 example."
  echo "axi4_lite   - AXI4 Lite example."
  echo "axi4_stream - AXI4 Stream example."
  echo "Type help to repeat this message."
}

help
