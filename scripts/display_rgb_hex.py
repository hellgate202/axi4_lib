#!/usr/bin/python3

import numpy as np
import cv2
import sys

px_width = 10

value_mult = 2 ** ( px_width - 8 )

img_path = sys.argv[1]
x = int( sys.argv[2] )
y = int( sys.argv[3] )

d_img = np.zeros( ( y, x, 3 ), np.uint8 )

img = open( img_path )

print( "Reading output image..." )
for i in range( y ):
  for j in range( x ):
    l = d.readline().strip()
    d_img[i][j][0] = ( int( ( "0b" + l ), 2 ) / value_mult );
    l = d.readline().strip()
    d_img[i][j][1] = ( int( ( "0b" + l ), 2 ) / value_mult );
    l = d.readline().strip()
    d_img[i][j][2] = ( int( ( "0b" + l ), 2 ) / value_mult );

cv2.imshow( "img", d_img )
cv2.waitKey( 0 )
cv2.destroyAllWindows()
