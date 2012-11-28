//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

// This example reads a real valued seqeunce from stdin and writes its 
// fourier transform to stdout. The program expects one argument, which 
// is the number of data points and must be a power of two. There should 
// be one number on each line of stdin. The fft in this example operates 
// on single precission floating point numbers.
//
// This example uses pfft.pfft.

import std.stdio, std.conv, std.exception;
import pfft.pfft;

void main(string[] args)
{
    auto n = to!int(args[1]);
    enforce((n & (n-1)) == 0, "N must be a power of two.");
    
    alias Rfft!float F;

    auto f = new F(n);

    auto data = F.Array(n);

    foreach(ref e; data)
        readf("%s\n", &e);

    f.rfft(data);

    foreach(i; 0 .. n / 2 + 1)
        writefln("%s\t%s", data[i], (i == 0 || i == n / 2) ? 0 : data[i]);
}
