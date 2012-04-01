//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import core.stdc.stdio, core.stdc.stdlib;

import std.datetime, std.complex;
import pfft.stdapi;

alias float T;

StopWatch sw;

static this()
{
    sw.start();
}

double get_time()
{
    return sw.peek().nsecs() * 1e-9f;
}

auto gc_aligned_array(T)(size_t n)
{
    import core.memory;
    return (cast(T*)GC.malloc(T.sizeof*n))[0..n];
}

void bench(int log2n)
{

    auto a = gc_aligned_array!(Complex!T)(1 << log2n);
    auto b = gc_aligned_array!(Complex!T)(1 << log2n);

    a []= Complex!T(0, 0);
    b []= Complex!T(0, 0);
    
    auto fft = new Fft!T(log2n);
    
    ulong flopsPerIter = 5UL * log2n * (1UL << log2n); 
    ulong niter = 10_000_000_000L / flopsPerIter;
    niter = niter ? niter : 1;
    
    double t = get_time();
    
    foreach(i; 0 .. niter)
        fft.fft(a, b);
    
    t = get_time() - t;
    printf("%f\n", 1e-9 * niter * flopsPerIter / t);
}

void main(string[] args)
{     
    bench(atoi(args[1].ptr)); 
}
 
