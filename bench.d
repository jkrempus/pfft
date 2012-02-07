//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.conv, std.datetime;

version(StdSimd)
{
    import pfft.stdsimd;
}
else version(Scalar)
{
    import pfft.scalar;
}
else
{
    import pfft.sse;
}

void main(string[] args)
{
    int log2n = parse!int(args[1]);
    
    auto re = new float[1<<log2n];
    auto im = new float[1<<log2n];

    re []= 0f;
    im []= 0f;
    
    auto tables = fft_table(log2n);
    
    ulong flopsPerIter = 5UL * log2n * (1UL << log2n); 
    ulong niter = 10_000_000_000L / flopsPerIter;
    niter = niter ? niter : 1;
    
    StopWatch sw;
    sw.start();
    
    foreach(i; 0 .. niter)
        fft(re.ptr, im.ptr, log2n, tables);
    
    sw.stop();
    writeln(to!float(niter * flopsPerIter) / sw.peek().nsecs());
}
