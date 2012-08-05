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
    enum log2_bitreverse_chunk_size = 2;
    
    version(GNU)
    {
        import gcc.builtins;
        
        static vec scalar_to_vector(T a)
        {
            return a;
        }
        
        static void interleave( 
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
        pragma(shufflevector) 
            double2 shufflevector(double2, double2, int, int);

        static vec scalar_to_vector(T a)
        {
            return a;
        }
        
        static void interleave( 
            vec a0,  vec a1, ref vec r0, ref vec r1)
        {
            r0 = shufflevector(a0, a1, 0, 2);
            r1 = shufflevector(a0, a1, 1, 3);
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
        
        static void interleave( 
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
            interleave(v(arr)[0], v(arr)[1], rr, ri);
    }

    alias interleave deinterleave;

    static void  transpose(int elements_per_vector)(
            vec a0,  vec a1, ref vec r0, ref vec r1)
    {
        static if(elements_per_vector == 2)
            interleave(a0, a1, r0, r1);
        else
            static assert(0);
    }
    
    static void bit_reverse_swap(T * p0, T * p1, size_t m)
    {
        vec a0, a1, a2, a3, b0, b1, b2, b3;

        a0 = v(p0 + m * 0)[0];
        a1 = v(p0 + m * 2)[0];
        b0 = v(p1 + m * 0)[0];
        b1 = v(p1 + m * 2)[0];
        interleave(a0, a1, a0, a1);
        interleave(b0, b1, b0, b1);
        v(p1 + m * 0)[0] = a0;
        v(p1 + m * 2)[0] = a1;
        v(p0 + m * 0)[0] = b0;
        v(p0 + m * 2)[0] = b1;
        
        a2 = v(p0 + m * 1)[1];
        a3 = v(p0 + m * 3)[1];
        b2 = v(p1 + m * 1)[1];
        b3 = v(p1 + m * 3)[1];
        interleave(a2, a3, a2, a3);
        interleave(b2, b3, b2, b3);
        v(p1 + m * 1)[1] = a2;
        v(p1 + m * 3)[1] = a3;
        v(p0 + m * 1)[1] = b2;
        v(p0 + m * 3)[1] = b3;
        
        a0 = v(p0 + m * 0)[1];
        a1 = v(p0 + m * 2)[1];
        a2 = v(p0 + m * 1)[0];
        a3 = v(p0 + m * 3)[0];
        interleave(a0, a1, a0, a1);
        interleave(a2, a3, a2, a3);
        b0 = v(p1 + m * 0)[1];
        b1 = v(p1 + m * 2)[1];
        b2 = v(p1 + m * 1)[0];
        b3 = v(p1 + m * 3)[0];
        v(p1 + m * 0)[1] = a2;
        v(p1 + m * 2)[1] = a3;
        v(p1 + m * 1)[0] = a0;
        v(p1 + m * 3)[0] = a1;
        interleave(b0, b1, b0, b1);
        interleave(b2, b3, b2, b3);
        v(p0 + m * 0)[1] = b2;
        v(p0 + m * 2)[1] = b3;
        v(p0 + m * 1)[0] = b0;
        v(p0 + m * 3)[0] = b1;
    }

    static void bit_reverse(T * p, size_t m)
    {
        vec a0, a1, a2, a3;
        a0 = v(p + m * 0)[0];
        a1 = v(p + m * 2)[0];
        a2 = v(p + m * 1)[1];
        a3 = v(p + m * 3)[1];
        interleave(a0, a1, a0, a1);
        interleave(a2, a3, a2, a3);
        v(p + m * 0)[0] = a0;
        v(p + m * 2)[0] = a1;
        v(p + m * 1)[1] = a2;
        v(p + m * 3)[1] = a3;
        
        a0 = v(p + m * 0)[1];
        a1 = v(p + m * 2)[1];
        a2 = v(p + m * 1)[0];
        a3 = v(p + m * 3)[0];
        interleave(a0, a1, a0, a1);
        interleave(a2, a3, a2, a3);
        v(p + m * 0)[1] = a2;
        v(p + m * 2)[1] = a3;
        v(p + m * 1)[0] = a0;
        v(p + m * 3)[0] = a1;
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

