// This example reads a real valued seqeunce from stdin and writes its 
// fourier transform to stdout. The program expects one argument, which 
// is the number of data points and must be a power of two. There should 
// be one number on each line of stdin. The fft in this example operates 
// on double precission floating point numbers.
//
// This example uses pfft.stdapi, which is a drop in replacement for
// std.numeric.Fft. This is slower than using pfft.pfft.

import std.stdio, std.conv, std.exception, std.complex;
import pfft.stdapi;

void main(string[] args)
{
    auto n = to!int(args[1]);
    
    enforce((n & (n-1)) == 0, "N must be a power of two.");

    auto f = new Fft(n);

    auto data = new double[n];

    foreach(ref e; data)
        readf("%s\n", &e);

    auto ft = f.fft!double(data);

    foreach(e; ft)
        writefln("%s %s", e.re, e.im);
}
