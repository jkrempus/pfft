//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.neon;

import pfft.fft_impl;
import gcc.builtins;
import core.simd;

version(GNU) { } else
{
    static assert(0, "This compiler is not supported.");
}

struct NeonVec
{
    float4 v;
    
    this(float4 _v){ v = _v; }
    
    NeonVec opBinary(string s)(NeonVec other) if(s == "+")
    {
        return NeonVec(__builtin_neon_vaddv4sf(v, other.v, 3));
    }
    NeonVec opBinary(string s)(NeonVec other) if(s == "-")
    {
        return NeonVec(__builtin_neon_vsubv4sf(v, other.v, 3));
    }
    NeonVec opBinary(string s)(NeonVec other) if(s == "*")
    {
        return NeonVec(__builtin_neon_vmulv4sf(v, other.v, 3));
    }
}

struct Neon
{
    alias NeonVec vec;
    alias float T;
    
    enum vec_size = 4;
    
    static vec scalar_to_vector(T a)
    {
        return vec(a);
    }
    
    private static float4 * v(float * a)
    {
        return cast(float4*)a;
    }
    
    static void bit_reverse_swap_16(T * p0, T * p1, T * p2, T * p3, int i, int j)
    {
        float4[2] a, b, ra, rb;
        
        __builtin_neon_vuzpv4sf(&a[0], *v(p0 + i), *v(p1 + i));
        __builtin_neon_vuzpv4sf(&b[0], *v(p2 + i), *v(p3 + i));
        __builtin_neon_vtrnv4sf(&ra[0], a[0], b[0]);
        __builtin_neon_vtrnv4sf(&rb[0], a[1], b[1]);
        __builtin_neon_vuzpv4sf(&a[0], *v(p0 + j), *v(p1 + j));
        __builtin_neon_vuzpv4sf(&b[0], *v(p2 + j), *v(p3 + j));
        *v(p0 + j) = ra[0];
        *v(p1 + j) = ra[1];
        *v(p2 + j) = rb[0];
        *v(p3 + j) = rb[1];
        __builtin_neon_vtrnv4sf(&ra[0], a[0], b[0]);
        __builtin_neon_vtrnv4sf(&rb[0], a[1], b[1]);
        *v(p0 + i) = ra[0];
        *v(p1 + i) = ra[1];
        *v(p2 + i) = rb[0];
        *v(p3 + i) = rb[1];
    }

    static void bit_reverse_16(T * p0, T * p1, T * p2, T * p3, int i)
    {
        float4[2] a, b, ra, rb;
        __builtin_neon_vuzpv4sf(&a[0], *v(p0 + i), *v(p1 + i));
        __builtin_neon_vuzpv4sf(&b[0], *v(p2 + i), *v(p3 + i));
        __builtin_neon_vtrnv4sf(&ra[0], a[0], b[0]);
        __builtin_neon_vtrnv4sf(&rb[0], a[1], b[1]);
        *v(p0 + i) = ra[0];
        *v(p1 + i) = ra[1];
        *v(p2 + i) = rb[0];
        *v(p3 + i) = rb[1];
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

alias FFT!(Neon,Options) F;

extern(C) void fft(float* re, float* im, int log2n, F.Tables tables)
{
    F.fft(re, im, log2n, tables);
}

extern(C) auto fft_table(int log2n)
{
    return F.tables(log2n);
}
