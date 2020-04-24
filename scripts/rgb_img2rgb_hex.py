#!/usr/bin/python3

import numpy as np
import cv2
import sys

output_path = "./img.hex"

img = cv2.imread( sys.argv[1] )
new_x = int( sys.argv[2] )
new_y = int( sys.argv[3] )
px_width = int( sys.argv[4] )
value_mult = 2 ** ( px_width - 8 )

print( "Resizing image to %0d x %0d" % ( new_x, new_y ) )
img = cv2.resize( img, ( new_x, new_y ) )

print( "Creating sample hex file" )
with open( output_path, "w+" ) as f:
  for y in range( img.shape[0] ):
    for x in range( img.shape[1] ):
      f.write( hex( img[y][x][1] * value_mult + ( ( img[y][x][0] * value_mult ) << px_width ) + ( ( img[y][x][2] * value_mult ) << ( px_width * 2 ) ) )[2 :]+"\n" )
