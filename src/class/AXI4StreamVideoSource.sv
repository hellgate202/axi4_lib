class AXI4StreamVideoSource #(
  parameter int    PX_WIDTH     = 10,
  parameter int    FRAME_RES_X  = 1920,
  parameter int    FRAME_RES_Y  = 1080,
  parameter int    TOTAL_X      = 2200,
  parameter int    TOTAL_Y      = 1125,
  parameter string FILE_PATH    = ""
);

localparam int TDATA_WIDTH   = PX_WIDTH % 8 ? ( PX_WIDTH / 8 + 1 ) * 8 : PX_WIDTH;
localparam int TDATA_WIDTH_B = TDATA_WIDTH / 8;
localparam int PX_AMOUNT     = FRAME_RES_X * FRAME_RES_Y;

bit [PX_WIDTH - 1 : 0] frame [PX_AMOUNT - 1 : 0];
bit                    running;

virtual axi4_stream_if #(
  .TDATA_WIDTH ( TDATA_WIDTH ),
  .TID_WIDTH   ( 1           ),
  .TDEST_WIDTH ( 1           ),
  .TUSER_WIDTH ( 1           )
) axi4_stream_if_v;

function new(
  virtual axi4_stream_if #(
    .TDATA_WIDTH ( TDATA_WIDTH ),
    .TID_WIDTH   ( 1           ),
    .TDEST_WIDTH ( 1           ),
    .TUSER_WIDTH ( 1           )
  ) axi4_stream_if_v
);

  this.axi4_stream_if_v = axi4_stream_if_v;
  init_interface();

endfunction

local function automatic void init_interface();

  axi4_stream_if_v.tdata  = '0;
  axi4_stream_if_v.tstrb  = '0;
  axi4_stream_if_v.tkeep  = '0;
  axi4_stream_if_v.tlast  = '0;
  axi4_stream_if_v.tid    = '0;
  axi4_stream_if_v.tdest  = '0;
  axi4_stream_if_v.tuser  = '0;
  axi4_stream_if_v.tvalid = '0;
  $readmemh( FILE_PATH, frame );

endfunction

task automatic run();
  if( !running )
    begin
      running = 1'b1;
      fork
        forever
          begin
            send_frame();
            if( !running )
              break;
          end
      join_none
  end
endtask

task automatic stop();

  running = 1'b0;

endtask

local task automatic send_frame();
  bit [TDATA_WIDTH - 1 : 0] line [$];
  for( int y = 0; y < FRAME_RES_Y; y++ )
    begin
      for( int x = 0; x < FRAME_RES_X; x++ )
        line.push_back( frame[y * FRAME_RES_X + x] );
      if( y == 0 )
        tx_data( line, 1 );
      else
        tx_data( line, 0 );
      repeat( TOTAL_X - FRAME_RES_X )
        @( posedge axi4_stream_if_v.aclk );
    end
  repeat( ( TOTAL_Y - FRAME_RES_Y ) * TOTAL_X )
    @( posedge axi4_stream_if_v.aclk );
endtask

local task automatic tx_data(
  ref   bit [TDATA_WIDTH - 1 : 0] px_q [$],
  input bit                       tuser_en = 1'b0
);

  bit was_tuser = 1'b0;

  while( px_q.size() > 0 )
    begin
      axi4_stream_if_v.tvalid <= 1'b1;
      axi4_stream_if_v.tdata  <= px_q.pop_front();
      for( int i = 0; i < TDATA_WIDTH_B; i++ )
        begin
          axi4_stream_if_v.tstrb[i] <= 1'b1;
          axi4_stream_if_v.tkeep[i] <= 1'b1;
        end
      if( tuser_en && !was_tuser )
        begin
          was_tuser              = 1'b1;
          axi4_stream_if_v.tuser <= 1'b1;
        end
      else
        axi4_stream_if_v.tuser <= 1'b0;
      if( px_q.size() == 0 )
        axi4_stream_if_v.tlast <= 1'b1;
      do
        @( posedge axi4_stream_if_v.aclk );
      while( !axi4_stream_if_v.tready );
    end
  axi4_stream_if_v.tvalid <= 1'b0;
  axi4_stream_if_v.tuser  <= '0;
  axi4_stream_if_v.tdata  <= '0;
  axi4_stream_if_v.tstrb  <= '0;
  axi4_stream_if_v.tkeep  <= '0;
  axi4_stream_if_v.tlast  <= 1'b0;

endtask

endclass
