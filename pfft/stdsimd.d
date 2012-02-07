//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.stdsimd;

import core.simd;

import pfft.fft_impl;

template shuf_mask(int a3, int a2, int a1, int a0)
{ 
    enum shuf_mask = a0 | (a1<<2) | (a2<<4) | (a3<<6); 
}

struct SSE
{
    alias float4 vec;
    alias float T;
    
    enum vec_size = 4;
    
    private static float4 * v(float * a)
    {
        return cast(float4*)a;
    }
    
    import std.simd;
    
    static void bit_reverse_swap_16(float * p0, float * p1, float * p2, float * p3, size_t i1, size_t i2)
    {
        auto m1 = float4x4(*v(p0 + i1), *v(p2 + i1), *v(p1 + i1), *v(p3 + i1));
        m1 = transpose(m1);
        
        auto m2 = float4x4(*v(p0 + i2), *v(p2 + i2), *v(p1 + i2), *v(p3 + i2));
        m2 = transpose(m2);
        
        *v(p0 + i1) = m2.xRow;
        *v(p2 + i1) = m2.yRow;
        *v(p1 + i1) = m2.zRow;
        *v(p3 + i1) = m2.wRow;
        
        *v(p0 + i2) = m1.xRow;
        *v(p2 + i2) = m1.yRow;
        *v(p1 + i2) = m1.zRow;
        *v(p3 + i2) = m1.wRow;
    }

    static void bit_reverse_16(float * p0, float * p1, float * p2, float * p3, size_t i)
    {
        auto m1 = float4x4(*v(p0 + i), *v(p2 + i), *v(p1 + i), *v(p3 + i));
        m1 = transpose(m1);
        
        *v(p0 + i) = m1.xRow;
        *v(p2 + i) = m1.yRow;
        *v(p1 + i) = m1.zRow;
        *v(p3 + i) = m1.wRow;
    }
    
    version(GNU)
    {
        static vec scalar_to_vector(T a)
        {
            return a;
        }
    }
    else
    {
        static vec scalar_to_vector(float a)
        {
            struct quad
            {
                align(16) float a;
                float b;
                float c;
                float d;
            };
            return *cast(vec*)&quad(a,a,a,a);
        }
    }
}

struct Options
{
    enum log2_bitreverse_large_chunk_size = 5;
    enum large_limit = 14;
    enum log2_optimal_n = 9;
    enum passes_per_recursive_call = 5;
    enum log2_recursive_passes_chunk_size = 5;
}

version(CPP_IMPL)
{
    struct Tables{ void* ptr1; void* ptr2; }
    extern(C) void fft(float* re, float* im, int log2n, Tables tables);
    extern(C) Tables fft_table(int log2n);
}
else
{
    alias FFT!(SSE,Options) F;
    
    extern(C) void fft(float* re, float* im, int log2n, F.Tables tables)
    {
        F.fft(re, im, log2n, tables);
    }

    extern(C) auto fft_table(int log2n)
    {
        return F.tables(log2n);
    }
}

