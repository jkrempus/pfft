//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.range, std.algorithm, std.conv, 
    std.math, std.numeric, std.complex, std.random;

version(Double)
{
	alias double T;
    alias real U;
}
else
{
	alias float T;
	alias double U;
}

import pfft_module = pfft.stdapi;

auto rms(R)(R r)
{
    return std.math.sqrt(reduce!q{ a + b.re^^2 + b.im^^2 }(0.0, r) / r.length);
}

void main(string[] args)
{
    int log2n = parse!int(args[1]);
    int n = 1<<log2n;
    
	
    auto stdData = new Complex!(U)[n];
    auto pfftData = new Complex!(T)[n];
    
    rndGen.seed(1);
    foreach(i, e; stdData)
    {
        stdData[i].re = uniform(0.0,1.0);
        stdData[i].im = uniform(0.0,1.0);
        pfftData[i] = stdData[i];
    }
    
    auto stdFt = (new Fft(n)).fft!U(stdData);
    auto pfftFt = (new pfft_module.Fft!T(n)).fft(pfftData);
    
    auto diff = map!q{ a[0] - a[1] }(zip(stdFt, pfftFt[]));
    
    writefln("%.2e", rms(diff) / rms(stdFt));
}
