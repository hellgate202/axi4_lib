#!/usr/bin/python3

import numpy as np
import cv2
import sys

img_path = sys.argv[1]
x = int( sys.argv[2] )
y = int( sys.argv[3] )
px_width = int( sys.argv[4] )
value_mult = 2 ** ( px_width - 8 )

d_img = np.zeros( ( y, x ), np.uint8 )

d = open( img_path )

print( "Reading output image..." )
for i in range( y ):
  for j in range( x ):
    l = d.readline().strip()
    d_img[i][j] = ( int( ( "0x" + l ), 16 ) / value_mult );

cv2.imshow( "img", d_img )
cv2.waitKey( 0 )
cv2.destroyAllWindows()
