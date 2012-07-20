//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

// This example reads data from stdin and writes its fourier transform to
// stdout. The program expects one argument, which is the number of data
// points and must be a power of two. There should be two numbers on each
// line of stdin, the first being the real part of a complex number and 
// the second the imaginary part. The fft in this example operates on 
// double precission floating point numbers.
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
    auto data = Fft.allocate!(double)(n);

    foreach(ref e; data)
        readf("%s %s\n", &e.re, &e.im);
    
    auto ft = f.fft!double(data);

    foreach(e; ft)
        writefln("%s %s", e.re, e.im);
}
