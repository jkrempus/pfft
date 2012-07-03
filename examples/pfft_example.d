// This example reads data from stdin and writes its fourier transform to
// stdout. The program expects one argument, which is the number of data
// points and must be a power of two. There should be two numbers on each
// line of stdin, the first being the real part of a complex number and 
// the second the imaginary part. The fft in this example operates on 
// single precission floating point numbers.
//
// This example uses pfft.pfft.

import std.stdio, std.conv, std.exception;
import pfft.pfft;

void main(string[] args)
{
    auto n = to!int(args[1]);
    enforce((n & (n-1)) == 0, "N must be a power of two.");
    
    alias Fft!float F;

    auto f = new F(n);

    auto re = F.allocate(n);
    auto im = F.allocate(n);

    foreach(i, _; re)
        readf("%s %s\n", &re[i], &im[i]);

    f.fft(re, im);

    foreach(i, _; re)
        writefln("%s %s", re[i], im[i]);
}
