The "process" module performs image processing through three sequential operations: mirroring, grayscale and sharpness. The module receives the input pixels from an image, processes them based on the specified operations and generates the corresponding output pixels.
To perform the 3 operations, 2 "always" blocks are used:

1. The sequential part: at each positive clock edge, the state, line, column changes and in the case of the sharpness filter, the variable in which it is calculated also changes
the new pixel value;
2. The combinational part: at each change of any signal in the block, the state is identified and the logic within it is executed.
   
The 3 operations are performed as follows:
1. Mirror:
   
Mirroring starts in state 0.

For mirroring, the pixels in the upper half of the matrix are traversed. For each of these pixels, the mirror from the lower half is found, and then the switch between them is made using 2 auxiliary variables: pixel_aux1 and pixel_aux2, in which I keep the pixel values.
The input image is sequentially mirrored on the vertical axis until the entire image is processed.
The operation is completed when all rows have been mirrored, i.e. in state 7.

2. Grayscale:
   
Grayscale starts at state 7.

Each pixel is converted using an arithmetic mean between the maximum value and the minimum value of its RGB components. This operation was performed using 3
auxiliary variables: r, g and b, correlated with the 8 bits that represent the respective color. The operation is completed when all the pixels have been transformed, i.e. in state 10.

3. Sharpness:
   
Sharpness starts at state 10.

Each pixel is processed according to its neighbors using the convolution matrix [-1, -1, -1; -1, 9, -1; -1, -1, -1]. To perform this operation, we assume that we have a 3x3 matrix for which we note the positions of the elements from 1 to 9 as follows:

1 2 3

4 5 6

7 8 9

The pixel on position 5 is the one we are processing at a given time. For example, if the current pixel is at position (0,0) then its neighbors will be at positions 8, 9 and 6. The neighbors of the pixel are traversed in a trigonometric sense (3, 2, 1, 4, 7, 8, 9, 6 ).
The operation is completed when all the pixels have been filtered (state 26). The pixels are processed sequentially, and the result is stored in the output.
