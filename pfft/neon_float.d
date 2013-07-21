//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.neon_float;

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
    
    /*NeonVec muladd(NeonVec a, NeonVec b)
    {
        return NeonVec(__builtin_neon_vmlav4sf(v, a.v, b.v, 3));
    }
    NeonVec mulsub(NeonVec a, NeonVec b)
    {
        return NeonVec(__builtin_neon_vmlsv4sf(v, a.v, b.v, 3));
    }*/
}

template Vector()
{
    alias NeonVec vec;
    alias float T;
    alias float Twiddle;
    
    enum vec_size = 4;
    enum log2_bitreverse_chunk_size = 2;   
 
    vec twiddle_to_vector(T a)
    {
        return vec(a);
    }
    
    void complex_array_to_real_imag_vec(int N)(T * arr, ref vec rr, ref vec ri)
    {
        static if(N==4)
        {
            deinterleave((cast(vec*)arr)[0], (cast(vec*)arr)[1], rr, ri);
        }
        else if(N==2)
        {
            asm
            {
                "vldmia  %2, {%e0-%f0}
                vmov %q1, %q0
                vuzp.32 %q0, %q1
                vuzp.32 %e0, %f0
                vuzp.32 %e1, %f1"
                : "=w" rr, "=w" ri //"
                : "r" arr ;
            }
        }
    }
    
    void transpose(int elements_per_vector)(
        vec a0, vec a1, ref vec r0, ref vec r1)
    {
        if(elements_per_vector == 4)
        {
            float4[2] tmp;
            __builtin_neon_vtrnv4sf(&tmp[0], a0.v, a1.v);
            r0.v = tmp[0];
            r1.v = tmp[1];
        }
        else if(elements_per_vector == 2)
        {
            asm
            {
                "vswp %f0, %e1 \n"
                :"+w" a0.v, "+w" a1.v ;
            }
            r0 = a0;
            r1 = a1;
        }
    }
    
    void interleave(vec a0, vec a1, ref vec r0, ref vec r1)
    {
        float4[2] tmp;
        __builtin_neon_vzipv4sf(&tmp[0], a0.v, a1.v);
        r0.v = tmp[0];
        r1.v = tmp[1];
    }
    
    void deinterleave(vec a0, vec a1, ref vec r0, ref vec r1)
    {
        float4[2] tmp;
        __builtin_neon_vuzpv4sf(&tmp[0], a0.v, a1.v);
        r0.v = tmp[0];
        r1.v = tmp[1];
    }
    
    private float4 * v(float * a)
    {
        return cast(float4*)a;
    }
    
    void bit_reverse(ref vec a0, ref vec a1, ref vec a2, ref vec a3)
    {
        asm
        {
            "vtrn.32 %q0, %q2
            vtrn.32 %q1, %q3
            vswp %f0, %e1
            vswp %f2, %e3"
            : "+w" a0.v, "+w" a1.v, "+w" a2.v, "+w" a3.v;
        }
    }
}

template Options()
{
    enum log2_bitreverse_large_chunk_size = 5;
    enum large_limit = 14;
    enum log2_optimal_n = 9;
    enum passes_per_recursive_call = 4;
    enum log2_recursive_passes_chunk_size = 6;
}

