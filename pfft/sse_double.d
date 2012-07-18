//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.sse_double;

import core.simd;

import pfft.fft_impl;

template shuf_mask(int a3, int a2, int a1, int a0)
{ 
    enum shuf_mask = a0 | (a1<<2) | (a2<<4) | (a3<<6); 
}

version(X86_64)
    version(linux)
        version = linux_x86_64;

struct Vector
{
    alias double2 vec;
    alias double T;
    
    enum vec_size = 2;
    
    version(GNU)
    {
        import gcc.builtins;
        
        static vec scalar_to_vector(T a)
        {
            return a;
        }
        
        static void interleave(int interleaved)( 
            vec a0,  vec a1, ref vec r0, ref vec r1)
        {
            r0 = __builtin_ia32_unpcklpd(a0, a1);
            r1 = __builtin_ia32_unpckhpd(a0, a1);
        }

        
        static vec unaligned_load(T* p)
        {
            return __builtin_ia32_loadupd(p);
        }

        static void unaligned_store(T* p, vec v)
        {
            return __builtin_ia32_storeupd(p, v);
        }

        static vec reverse(vec v)
        {
            return __builtin_ia32_shufpd(v, v, 0x1);
        }
    }
    else version(LDC)
    {
        import pfft.sse_declarations;
        
        static vec scalar_to_vector(T a)
        {
            return a;
        }
        
        static void interleave(int interleaved)( 
            vec a0,  vec a1, ref vec r0, ref vec r1)
        {
            r0 = unpcklpd(a0, a1);
            r1 = unpckhpd(a0, a1);
        }
    }
    else 
    {
        static vec scalar_to_vector(T a)
        {
            version(linux_x86_64)
                asm
                {
                    naked;
                    movddup XMM0, XMM0;
                    ret;
                }
            else
            {
                static struct pair
                {
                    align(16) T a;
                    T b;
                };
		auto p = pair(a,a);
                return *cast(vec*)& p;
            }
        }
        
        static void interleave(int interleaved)( 
            vec a0,  vec a1, ref vec r0, ref vec r1)
        {
            r0 = __simd(XMM.UNPCKLPD, a0, a1);
            r1 = __simd(XMM.UNPCKHPD, a0, a1);
        }
    }
        
    private static vec * v(T * a)
    {
        return cast(vec*)a;
    }
            
    static void complex_array_to_real_imag_vec(int len)(
        T * arr, ref vec rr, ref vec ri)
    {
            interleave!2(v(arr)[0], v(arr)[1], rr, ri);
    }

    static void deinterleave(int interleaved)(
        vec a0,  vec a1, ref vec r0, ref vec r1)
    {
        interleave!2(a0, a1, r0, r1);
    }
    
    static void bit_reverse_swap_16(T * p0, T * p1, T * p2, T * p3, size_t i1, size_t i2)
    {
        vec a0, a1, a2, a3, b0, b1, b2, b3;

        a0 = v(p0 + i1)[0];
        a1 = v(p2 + i1)[0];
        b0 = v(p0+i2)[0];
        b1 = v(p2+i2)[0];
        interleave!2(a0, a1, a0, a1);
        interleave!2(b0, b1, b0, b1);
        v(p0+i2)[0] = a0;
        v(p2+i2)[0] = a1;
        v(p0 + i1)[0] = b0;
        v(p2 + i1)[0] = b1;
        
        a2 = v(p1 + i1)[1];
        a3 = v(p3 + i1)[1];
        b2 = v(p1+i2)[1];
        b3 = v(p3+i2)[1];
        interleave!2(a2, a3, a2, a3);
        interleave!2(b2, b3, b2, b3);
        v(p1+i2)[1] = a2;
        v(p3+i2)[1] = a3;
        v(p1 + i1)[1] = b2;
        v(p3 + i1)[1] = b3;
        
        a0 = v(p0 + i1)[1];
        a1 = v(p2 + i1)[1];
        a2 = v(p1 + i1)[0];
        a3 = v(p3 + i1)[0];
        interleave!2(a0, a1, a0, a1);
        interleave!2(a2, a3, a2, a3);
        b0 = v(p0+i2)[1];
        b1 = v(p2+i2)[1];
        b2 = v(p1+i2)[0];
        b3 = v(p3+i2)[0];
        v(p0+i2)[1] = a2;
        v(p2+i2)[1] = a3;
        v(p1+i2)[0] = a0;
        v(p3+i2)[0] = a1;
        interleave!2(b0, b1, b0, b1);
        interleave!2(b2, b3, b2, b3);
        v(p0 + i1)[1] = b2;
        v(p2 + i1)[1] = b3;
        v(p1 + i1)[0] = b0;
        v(p3 + i1)[0] = b1;
    }

    static void bit_reverse_16(T * p0, T * p1, T * p2, T * p3, size_t i)
    {
        vec a0, a1, a2, a3;
        a0 = v(p0 + i)[0];
        a1 = v(p2 + i)[0];
        a2 = v(p1 + i)[1];
        a3 = v(p3 + i)[1];
        interleave!2(a0, a1, a0, a1);
        interleave!2(a2, a3, a2, a3);
        v(p0 + i)[0] = a0;
        v(p2 + i)[0] = a1;
        v(p1 + i)[1] = a2;
        v(p3 + i)[1] = a3;
        
        a0 = v(p0 + i)[1];
        a1 = v(p2 + i)[1];
        a2 = v(p1 + i)[0];
        a3 = v(p3 + i)[0];
        interleave!2(a0, a1, a0, a1);
        interleave!2(a2, a3, a2, a3);
        v(p0 + i)[1] = a2;
        v(p2 + i)[1] = a3;
        v(p1 + i)[0] = a0;
        v(p3 + i)[0] = a1;
    }
}

struct Options
{
    enum log2_bitreverse_large_chunk_size = 5;
    enum large_limit = 13;
    enum log2_optimal_n = 10;
    enum passes_per_recursive_call = 4;
    enum log2_recursive_passes_chunk_size = 5;
    enum prefered_alignment = 4 * (1 << 10);
    enum { fast_init };
}

