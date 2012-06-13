// This example reads data from stdin and writes its fourier transform to
// stdout. The program expects one argument, which is the number of data
// points and must be a power of two. There should be two numbers on each
// line of stdin, the first being the real part of a complex number and 
// the second the imaginary part. The fft in this example operates on 
// single precission floating point numbers.
//
// This example uses pfft.pfft, which is the recommended way to use pfft.

import std.stdio, std.conv, std.exception;
import pfft.pfft;

void main(string[] args)
{
    // Alias Pfft!float to F so that we don't have to write it every time.
    // The template parameter must be a floating point type. This is the 
    // type the algorithm will operate on.
    alias Pfft!float F;

    auto n = to!int(args[1]);
    
    enforce((n & (n-1)) == 0, "N must be a power of two.");
   
    // Create an instance of F. The argument to the constructor is the
    // number of data points that the fft() method of the resulting object 
    // will operate on. This number must be a power of two.
    auto f = new F(n);

    // Allocate scalar arrays for the real and the imaginary part. Allocation 
    // must be done with F.allocate to ensure proper alignment. If an array
    // that we pass to f.fft() is not properly aligned, there will be an
    // assertion failure or, if compiled with -release, a segfault. 
    auto re = F.allocate(n);
    auto im = F.allocate(n);

    // This will not work 
    // auto im = cast(float[])((new byte[n * float.sizeof + 1])[1 .. $]);

    // Read the data from stdin.
    foreach(i, _; re)
        readf("%s %s\n", &re[i], &im[i]);

    // Calculate the fft. The length of arguments must be the same as the number
    // that was passed to the constructor when constructing f. The first 
    // parameter is the real part and the second is the imaginary part. The 
    // calculation is done in place - the real part of the fourier transform is 
    // stored to the first parameter and the imaginary part is stored to the 
    // second parameter. 
    f.fft(re, im);

    // Write the data out.
    foreach(i, _; re)
        writefln("%s %s", re[i], im[i]);
}
