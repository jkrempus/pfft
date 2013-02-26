//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.sse_double;

import core.simd;

import pfft.common;

template shuf_mask(int a3, int a2, int a1, int a0)
{ 
    enum shuf_mask = a0 | (a1<<2) | (a2<<4) | (a3<<6); 
}

version(X86_64)
    version(linux)
        version = linux_x86_64;

template Vector()
{
    @always_inline:

    alias double2 vec;
    alias double T;
    
    enum vec_size = 2;
    enum log2_bitreverse_chunk_size = 2;
    
    version(GNU)
    {
        import gcc.builtins;
        
        vec scalar_to_vector(T a)
        {
            return a;
        }
        
        void interleave( 
            vec a0,  vec a1, ref vec r0, ref vec r1)
        {
            r0 = __builtin_ia32_unpcklpd(a0, a1);
            r1 = __builtin_ia32_unpckhpd(a0, a1);
        }
        
        vec unaligned_load(T* p)
        {
            return __builtin_ia32_loadupd(p);
        }

        void unaligned_store(T* p, vec v)
        {
            return __builtin_ia32_storeupd(p, v);
        }

        vec reverse(vec v)
        {
            return __builtin_ia32_shufpd(v, v, 0x1);
        }
    }
    else version(LDC)
    {
        import ldc.simd;
        import ldc.gccbuiltins_x86;

        vec scalar_to_vector(T a)
        {
            return a;
        }
        
        void interleave( 
            vec a0,  vec a1, ref vec r0, ref vec r1)
        {
            r0 = shufflevector!(vec, 0, 2)(a0, a1);
            r1 = shufflevector!(vec, 1, 3)(a0, a1);
        }
        
        alias loadUnaligned!vec unaligned_load;
        alias __builtin_ia32_storeupd unaligned_store;

        vec reverse(vec v)
        {
            return shufflevector!(vec, 1, 0)(v, v);
        }
    }
    else 
    {
        vec scalar_to_vector(T a)
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
        
        void interleave( 
            vec a0,  vec a1, ref vec r0, ref vec r1)
        {
            r0 = __simd(XMM.UNPCKLPD, a0, a1);
            r1 = __simd(XMM.UNPCKHPD, a0, a1);
        }
    }
        
    private vec * v(T * a)
    {
        return cast(vec*)a;
    }
            
    void complex_array_to_real_imag_vec(int len)(
        T * arr, ref vec rr, ref vec ri)
    {
            interleave(v(arr)[0], v(arr)[1], rr, ri);
    }

    alias interleave deinterleave;

    void  transpose(int elements_per_vector)(
            vec a0,  vec a1, ref vec r0, ref vec r1)
    {
        static if(elements_per_vector == 2)
            interleave(a0, a1, r0, r1);
        else
            static assert(0);
    }
    
    void bit_reverse(
        ref vec a0, ref vec a1, ref vec a2, ref vec a3,
        ref vec a4, ref vec a5, ref vec a6, ref vec a7)
    {
        interleave(a0, a4, a0, a4);
        interleave(a3, a7, a3, a7);
        
        vec a2copy = a2;
        vec a6copy = a6;
        interleave(a1, a5, a2, a6);
        interleave(a2copy, a6copy, a1, a5);
    }
}

template Options()
{
    enum log2_bitreverse_large_chunk_size = 5;
    enum large_limit = 13;
    enum log2_optimal_n = 10;
    enum passes_per_recursive_call = 4;
    enum log2_recursive_passes_chunk_size = 5;
}
