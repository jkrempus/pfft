//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.avx_double;

import core.simd;

import pfft.fft_impl;

version(LDC)
{
    import pfft.avx_declarations;
}
else version(GNU)
{
    import gcc.builtins;

    double4 interleave128_lo_d(double4 a, double4 b)
    {
        return __builtin_ia32_vperm2f128_pd256(a, b, shuf_mask!(0,2,0,0));
    }

    double4 interleave128_hi_d(double4 a, double4 b)
    {
        return __builtin_ia32_vperm2f128_pd256(a, b, shuf_mask!(0,3,0,1));
    }

    double4 unpcklpd(double4 a, double4 b)
    {
        return __builtin_ia32_unpcklpd256(a, b);
    }

    double4 unpckhpd(double4 a, double4 b)
    {
        return __builtin_ia32_unpckhpd256(a, b);
    }
}

struct Vector 
{
    alias double4 vec;
    alias double T;
    
    enum vec_size = 4;
    
    static auto v(T* p){ return cast(vec*) p; }
    
    static void bit_reverse_swap_16(double * p0, double * p1, double * p2, double * p3, size_t i1, size_t i2)
    {
        //Scalar!(T).bit_reverse_swap_16(p0, p1, p2, p3, i1, i2);
        
        vec a0, a1, a2, a3, b0, b1, b2, b3;

        a0 = *v(p0 + i1);
        a1 = *v(p1 + i1);
        a2 = *v(p2 + i1);
        a3 = *v(p3 + i1);

        b0 = unpcklpd(a0, a2);
        b2 = unpckhpd(a0, a2);
        b1 = unpcklpd(a1, a3);
        b3 = unpckhpd(a1, a3);

        a0 = interleave128_lo_d(b0, b1);
        a1 = interleave128_hi_d(b0, b1);
        a2 = interleave128_lo_d(b2, b3);
        a3 = interleave128_hi_d(b2, b3);

        b0 = *v(p0 + i2);
        b1 = *v(p1 + i2);
        b2 = *v(p2 + i2);
        b3 = *v(p3 + i2);

        *v(p0 + i2) = a0;
        *v(p1 + i2) = a1;
        *v(p2 + i2) = a2;
        *v(p3 + i2) = a3;

        a0 = unpcklpd(b0, b2);
        a2 = unpckhpd(b0, b2);
        a1 = unpcklpd(b1, b3);
        a3 = unpckhpd(b1, b3);

        b0 = interleave128_lo_d(a0, a1);
        b1 = interleave128_hi_d(a0, a1);
        b2 = interleave128_lo_d(a2, a3);
        b3 = interleave128_hi_d(a2, a3);

        *v(p0 + i1) = b0;
        *v(p1 + i1) = b1;
        *v(p2 + i1) = b2;
        *v(p3 + i1) = b3;
    }

    static void bit_reverse_16(double * p0, double * p1, double * p2, double * p3, size_t i)
    {
        //Scalar!(T).bit_reverse_16(p0, p1, p2, p3, i);

        vec a0, a1, a2, a3, b0, b1, b2, b3;

        a0 = *v(p0 + i);
        a1 = *v(p1 + i);
        a2 = *v(p2 + i);
        a3 = *v(p3 + i);

        b0 = unpcklpd(a0, a2);
        b2 = unpckhpd(a0, a2);
        b1 = unpcklpd(a1, a3);
        b3 = unpckhpd(a1, a3);

        *v(p0 + i) = interleave128_lo_d(b0, b1);
        *v(p1 + i) = interleave128_hi_d(b0, b1);
        *v(p2 + i) = interleave128_lo_d(b2, b3);
        *v(p3 + i) = interleave128_hi_d(b2, b3);

    }

    
    static vec scalar_to_vector(T a)
    {
        return a;
    }
}

struct Options
{
    enum log2_bitreverse_large_chunk_size = 5;
    enum large_limit = 14;
    enum log2_optimal_n = 8;
    enum passes_per_recursive_call = 5;
    enum log2_recursive_passes_chunk_size = 4;
}

