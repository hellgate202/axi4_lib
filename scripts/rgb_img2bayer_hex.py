#!/usr/bin/python3

import numpy as np
import cv2
import sys

output_path = "./img.hex"

def convert2bayer( img ):
  img_bay = np.zeros( ( img.shape[0], img.shape[1] ), dtype = np.uint8 )
  for y in range( img.shape[0] ):
    for x in range( img.shape[1] ):
      if ( y % 2 ) == 0:
        if ( x % 2 ) == 0:
          img_bay[y][x] = img[y][x][2]
        else:
          img_bay[y][x] = img[y][x][1]
      else:
        if ( x % 2 ) == 0:
          img_bay[y][x] = img[y][x][1]
        else:
          img_bay[y][x] = img[y][x][0]
  return img_bay

img = cv2.imread( sys.argv[1] )
new_x = int( sys.argv[2] )
new_y = int( sys.argv[3] )
px_width = int( sys.argv[4] )
value_mult = 2 ** ( px_width - 8 )

print( "Resizing image to %0d x %0d" % ( new_x, new_y ) )
img = cv2.resize( img, ( new_x, new_y ) )

print( "Converting to Bayer pattern" )
bayer = convert2bayer( img )

print( "Creating sample hex file" )
with open( output_path, "w+" ) as f:
  for y in range( bayer.shape[0] ):
    for x in range( bayer.shape[1] ):
      f.write( hex( bayer[y][x] * value_mult )[2 :]+"\n" )
