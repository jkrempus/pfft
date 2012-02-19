//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import core.stdc.stdio, core.stdc.stdlib;

version( NoPhobos )
{
    import core.sys.posix.sys.time;
    
    double get_time()
    {
        timeval tv;
        gettimeofday(&tv, null);
        return tv.tv_sec + 1e-6 * tv.tv_usec;
    }
}
else
{
    import std.datetime;
    
    StopWatch sw;
    
    static this()
    {
        sw.start();
    }
    
    double get_time()
    {
        return sw.peek().nsecs() * 1e-9f;
    }
}

version(StdSimd)
{
    import pfft.stdsimd;
}
else version(Scalar)
{
    import pfft.scalar;
}
else version(Neon)
{
    import pfft.neon;
}
else
{
    import pfft.sse;
}

import pfft.fft_impl : aligned_array;

void bench(int log2n)
{

    auto re = aligned_array!float(1 << log2n, 64);
    auto im = aligned_array!float(1 << log2n, 64);

    re []= 0f;
    im []= 0f;
    
    auto tables = fft_table(log2n);
    
    ulong flopsPerIter = 5UL * log2n * (1UL << log2n); 
    ulong niter = 1_000_000_000L / flopsPerIter;
    niter = niter ? niter : 1;
    
    double t = get_time();
    
    foreach(i; 0 .. niter)
        fft(re.ptr, im.ptr, log2n, tables);
    
    t = get_time() - t;
    printf("%f\n", 1e-9 * niter * flopsPerIter / t);
    
    free(re.ptr);
    free(im.ptr);
}

void main(string[] args)
{     
    bench(atoi(args[1].ptr)); 
}
