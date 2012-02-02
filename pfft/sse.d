//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.sse;

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
    
    version(GNU)
    {
        import gcc.builtins;
        
        static vec scalar_to_vector(T a)
        {
            return a;
        }
        
        private static float4 * v(float * a)
        {
            return cast(float4*)a;
        }
                
        static void complex_array_to_real_imag_vec(int len)(
            float * arr, ref vec rr, ref vec ri)
        {
            static if(len==2)
            {
                rr = ri = (cast(vec*)arr)[0];
                rr = __builtin_ia32_shufps(rr, rr, shuf_mask!(2,2,0,0));    // I could use __builtin_ia32_movsldup here but it doesn't seem to increase performance
                ri = __builtin_ia32_shufps(ri, ri, shuf_mask!(3,3,1,1));
            }
            else static if(len==4)
            {
                vec tmp = (cast(vec*)arr)[0];
                ri = (cast(vec*)arr)[1];
                rr = __builtin_ia32_shufps(tmp, ri, shuf_mask!(2,0,2,0));
                ri = __builtin_ia32_shufps(tmp, ri, shuf_mask!(3,1,3,1));
            }
        }

        static void interleave(int interleaved)( 
            vec a0,  vec a1, ref vec r0, ref vec r1)
        {
            static if(interleaved==4)
            {
                r0 = __builtin_ia32_unpcklps(a0,a1);
                r1 = __builtin_ia32_unpckhps(a0,a1);
            }
            else static if(interleaved==2)
            {
                r0 = __builtin_ia32_shufps(a0,a1,shuf_mask!(1,0,1,0));
                r1 = __builtin_ia32_shufps(a0,a1,shuf_mask!(3,2,3,2));
            }
        }

        static void deinterleave(int interleaved)(
            vec a0,  vec a1, ref vec r0, ref vec r1)
        {
            if(interleaved==4)
            {
                r0 = __builtin_ia32_shufps(a0,a1,shuf_mask!(2,0,2,0));
                r1 = __builtin_ia32_shufps(a0,a1,shuf_mask!(3,1,3,1));
            }
            else if(interleaved==2)
            {
                r0 = __builtin_ia32_shufps(a0,a1,shuf_mask!(1,0,1,0));
                r1 = __builtin_ia32_shufps(a0,a1,shuf_mask!(3,2,3,2));
            }
        }
        
        static void bit_reverse_swap_16(float * p0, float * p1, float * p2, float * p3, size_t i1, size_t i2)
        {
            float4 b0 = __builtin_ia32_shufps(*v(p0 + i1), *v(p2 + i1), shuf_mask!(1,0,1,0));
            float4 b1 = __builtin_ia32_shufps(*v(p1 + i1), *v(p3 + i1), shuf_mask!(1,0,1,0));
            float4 b2 = __builtin_ia32_shufps(*v(p0 + i1), *v(p2 + i1), shuf_mask!(3,2,3,2));
            float4 b3 = __builtin_ia32_shufps(*v(p1 + i1), *v(p3 + i1), shuf_mask!(3,2,3,2));
            float4 a0 = __builtin_ia32_shufps(b0, b1, shuf_mask!(2,0,2,0));
            float4 a1 = __builtin_ia32_shufps(b2, b3, shuf_mask!(2,0,2,0));
            float4 a2 = __builtin_ia32_shufps(b0, b1, shuf_mask!(3,1,3,1));
            float4 a3 = __builtin_ia32_shufps(b2, b3, shuf_mask!(3,1,3,1));
            b0 = *v(p0 + i2); 
            b1 = *v(p1 + i2); 
            b2 = *v(p2 + i2); 
            b3 = *v(p3 + i2);
            *v(p0 + i2) = a0; 
            *v(p1 + i2) = a1; 
            *v(p2 + i2) = a2; 
            *v(p3 + i2) = a3;
            a0 = __builtin_ia32_shufps(b0, b2, shuf_mask!(1,0,1,0));
            a1 = __builtin_ia32_shufps(b1, b3, shuf_mask!(1,0,1,0));
            a2 = __builtin_ia32_shufps(b0, b2, shuf_mask!(3,2,3,2));
            a3 = __builtin_ia32_shufps(b1, b3, shuf_mask!(3,2,3,2));
            b0 = __builtin_ia32_shufps(a0, a1, shuf_mask!(2,0,2,0));
            b1 = __builtin_ia32_shufps(a2, a3, shuf_mask!(2,0,2,0));
            b2 = __builtin_ia32_shufps(a0, a1, shuf_mask!(3,1,3,1));
            b3 = __builtin_ia32_shufps(a2, a3, shuf_mask!(3,1,3,1));
            *v(p0 + i1) = b0;
            *v(p1 + i1) = b1;
            *v(p2 + i1) = b2;
            *v(p3 + i1) = b3;
        }

        static void bit_reverse_16(float * p0, float * p1, float * p2, float * p3, size_t i)
        {
            float4 b0 = __builtin_ia32_shufps(*v(p0 + i), *v(p2 + i), shuf_mask!(1,0,1,0));
            float4 b1 = __builtin_ia32_shufps(*v(p1 + i), *v(p3 + i), shuf_mask!(1,0,1,0));
            float4 b2 = __builtin_ia32_shufps(*v(p0 + i), *v(p2 + i), shuf_mask!(3,2,3,2));
            float4 b3 = __builtin_ia32_shufps(*v(p1 + i), *v(p3 + i), shuf_mask!(3,2,3,2));
            float4 a0 = __builtin_ia32_shufps(b0, b1, shuf_mask!(2,0,2,0));
            float4 a1 = __builtin_ia32_shufps(b2, b3, shuf_mask!(2,0,2,0));
            float4 a2 = __builtin_ia32_shufps(b0, b1, shuf_mask!(3,1,3,1));
            float4 a3 = __builtin_ia32_shufps(b2, b3, shuf_mask!(3,1,3,1));
            *v(p0 + i) = a0;
            *v(p1 + i) = a1;
            *v(p2 + i) = a2;
            *v(p3 + i) = a3;
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
        
        static void bit_reverse_swap_16(T * p0, T * p1, T * p2, T * p3, size_t i1, size_t i2)
        {
            Scalar!T.bit_reverse_swap_16(p0, p1, p2, p3, i1, i2);
        }

        static void bit_reverse_16(T * p0, T * p1, T * p2, T * p3, size_t i)
        {
            Scalar!T.bit_reverse_16(p0, p1, p2, p3, i);
        }                         
    }
}

struct Options
{
    enum log2_bitreverse_large_chunk_size = 5;
    enum large_limit = 14;
    enum log2_optimal_n = 9;
    enum passes_per_recursive_call = 3;
    enum log2_recursive_passes_chunk_size = 7;
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

