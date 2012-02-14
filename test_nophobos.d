//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import core.stdc.stdio, core.stdc.math, core.stdc.stdlib;

version(StdSimd)
{
    import pfft.stdsimd;
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

import scalar = pfft.scalar;

struct Rand
{
    int n;
    auto get()
    { 
        return (n = 1664525 * n + 1013904223) * (0.25 / (1 << 30)); 
    }
}

/*void tmp()
{
    import core.simd, gcc.builtins;
    float4 a;
    a = __builtin_neon_vcombinev2sf( __builtin_neon_vget_lowv4sf(a), 
                                     __builtin_neon_vget_highv4sf(a));
}*/

auto sq(T)(T a){ return a*a; }

void main(string[] args)
{
    int log2n = atoi(args[1].ptr);
    int n = 1<<log2n;
    
    auto re = aligned_array!float(n, 64);
    auto im = aligned_array!float(n, 64);
    auto re2 = aligned_array!double(n, 64);
    auto im2 = aligned_array!double(n, 64);
    
    auto rand = Rand(1);
    foreach(i, e; re)
    {
        re2[i] = rand.get();
        im2[i] = rand.get();
        re[i] = re2[i];
        im[i] = im2[i];
    }
    
    auto tables = fft_table(log2n);
    auto tables2 = scalar.fft_table_d(log2n);
    fft(re.ptr, im.ptr, log2n, tables);
    scalar.fft(re2.ptr, im2.ptr, log2n, tables2);
    
    float sumsq = 0;
    float sumsq_diff = 0;
    
    foreach(i; 0..n)
    {
        sumsq += sq(re2[i]) + sq(im2[i]);
        sumsq_diff += sq(re[i] -re2[i]) + sq(im[i] - im2[i]);
    }
    
    printf("%e\n", sqrt(sumsq_diff / sumsq));
}
