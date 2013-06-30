//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.sse_float;

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
    alias float4 vec;
    alias float T;
    alias float Twiddle;
    
    enum vec_size = 4;
    enum log2_bitreverse_chunk_size = 2;
    
    version(GNU)
    {
        import gcc.builtins;
                
        vec twiddle_to_vector()(T a)
        {
            return a;
        }  

        private vec shufps(int m0, int m1, int m2, int m3)(float4 a, float4 b)
        {
            return __builtin_ia32_shufps(a, b, shuf_mask!(m0, m1, m2, m3));
        }

        alias __builtin_ia32_unpcklps unpcklps;
        alias __builtin_ia32_unpckhps unpckhps;
              
        vec unaligned_load(T* p)
        {
            return __builtin_ia32_loadups(p);
        }

        void unaligned_store(T* p, vec v)
        {
            return __builtin_ia32_storeups(p, v);
        }

        vec reverse(vec v)
        {
            return shufps!(0, 1, 2, 3)(v, v);
        }
    }
    else version(DigitalMars)
    {
        vec twiddle_to_vector()(float a)
        {
            version(linux_x86_64)
                asm
                {
                    naked;
                    shufps XMM0, XMM0, 0;
                    ret;
                }
            else
            {
                struct quad
                {
                    align(16) float a;
                    float b;
                    float c;
                    float d;
                };
                auto q = quad(a,a,a,a);
                return *cast(vec*)& q;
            }
        }

        static if(is(typeof(XMM.SHUFPS)))
            private vec shufps(int m0, int m1, int m2, int m3)(float4 a, float4 b)
            {
                return __simd(XMM.SHUFPS, a, b, shuf_mask!(m0, m1, m2, m3));
            }

        private vec unpcklps(float4 a, float4 b)
        {
            return __simd(XMM.UNPCKLPS, a, b);
        }

        private vec unpckhps(float4 a, float4 b)
        {
            return __simd(XMM.UNPCKHPS, a, b);
        }
    }
    else version(LDC)
    {    
        import ldc.simd;
        import ldc.gccbuiltins_x86;

        vec twiddle_to_vector()(float a)
        {
            return a;
        }

        auto shufps(int m0, int m1, int m2, int m3)(vec a, vec b)
        {
            return shufflevector!(vec, m3, m2, m1 + 4, m0 + 4)(a, b);
        }
        
        alias shufflevector!(vec, 0, 4, 1, 5) unpcklps;
        alias shufflevector!(vec, 2, 6, 3, 7) unpckhps;
        alias loadUnaligned!vec unaligned_load;
        alias __builtin_ia32_storeups unaligned_store;
        
        vec reverse(vec v)
        {
            return shufps!(0, 1, 2, 3)(v, v);
        }
    }
    
    static if(is(typeof(shufps!(0, 0, 0, 0))))
    {
        void complex_array_to_real_imag_vec(int len)(
            float * arr, ref vec rr, ref vec ri)
        {
            static if(len==2)
            {
                rr = ri = (cast(vec*)arr)[0];
                rr = shufps!(2,2,0,0)(rr, rr);    // I could use __builtin_ia32_movsldup here but it doesn't seem to increase performance
                ri = shufps!(3,3,1,1)(ri, ri);
            }
            else static if(len==4)
            {
                vec tmp = (cast(vec*)arr)[0];
                ri = (cast(vec*)arr)[1];
                rr = shufps!(2,0,2,0)(tmp, ri);
                ri = shufps!(3,1,3,1)(tmp, ri);
            }
        }

        void transpose(int elements_per_vector)(
            vec a0,  vec a1, ref vec r0, ref vec r1)
        {
            if(elements_per_vector==4)
            {
                r0 = shufps!(2,0,2,0)(a0,a1);
                r1 = shufps!(3,1,3,1)(a0,a1);
                r0 = shufps!(3,1,2,0)(r0,r0);
                r1 = shufps!(3,1,2,0)(r1,r1);
            }
            else if(elements_per_vector==2)
            {
                r0 = shufps!(1,0,1,0)(a0,a1);
                r1 = shufps!(3,2,3,2)(a0,a1);
            }
        }
        
        void interleave( 
            vec a0,  vec a1, ref vec r0, ref vec r1)
        {
            r0 = unpcklps(a0,a1);
            r1 = unpckhps(a0,a1);
        }
        
        void deinterleave(
            vec a0,  vec a1, ref vec r0, ref vec r1)
        {
            r0 = shufps!(2,0,2,0)(a0,a1);
            r1 = shufps!(3,1,3,1)(a0,a1);
        }
        
        void bit_reverse()(
            ref float4 a0, ref float4 a1, ref float4 a2, ref float4 a3)
        {
            float4 b0 = shufps!(1,0,1,0)(a0, a2);
            float4 b1 = shufps!(1,0,1,0)(a1, a3);
            float4 b2 = shufps!(3,2,3,2)(a0, a2);
            float4 b3 = shufps!(3,2,3,2)(a1, a3);
            a0 = shufps!(2,0,2,0)(b0, b1);
            a1 = shufps!(2,0,2,0)(b2, b3);
            a2 = shufps!(3,1,3,1)(b0, b1);
            a3 = shufps!(3,1,3,1)(b2, b3);
        }
    }
}

template Options()
{
    enum log2_bitreverse_large_chunk_size = 5;
    enum large_limit = 14;
    enum log2_optimal_n = 10;
    enum passes_per_recursive_call = 4;
    enum log2_recursive_passes_chunk_size = 5;
}

