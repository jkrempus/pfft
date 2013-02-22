//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.avx_double;

import core.simd;

version(LDC)
{
    import ldc.simd;
    import ldc.gccbuiltins_x86;    

    alias shufflevector!(double4, 0, 1, 4, 5) interleave128_lo;
    alias shufflevector!(double4, 2, 3, 6, 7) interleave128_hi;
    alias shufflevector!(double4, 0, 4, 2, 6) unpcklpd;
    alias shufflevector!(double4, 1, 5, 3, 7) unpckhpd;
    alias loadUnaligned!double4 loadups;
    alias __builtin_ia32_storeupd256 storeupd;
    
    double4 reverse_elements(double4 v)
    {
        return shufflevector!(double4, 3, 2, 1, 0)(v, v);
    }
}
else version(GNU)
{
    import gcc.builtins;

    template shuf_mask(int a3, int a2, int a1, int a0)
    { 
        enum shuf_mask = a0 | (a1<<2) | (a2<<4) | (a3<<6); 
    }

    double4 interleave128_lo(double4 a, double4 b)
    {
        return __builtin_ia32_vperm2f128_pd256(a, b, shuf_mask!(0,2,0,0));
    }

    double4 interleave128_hi(double4 a, double4 b)
    {
        return __builtin_ia32_vperm2f128_pd256(a, b, shuf_mask!(0,3,0,1));
    }

    alias __builtin_ia32_unpcklpd256 unpcklpd;
    alias __builtin_ia32_unpckhpd256 unpckhpd;
    alias __builtin_ia32_loadupd256 loadupd;
    alias __builtin_ia32_storeupd256 storeupd;
    
    double4 reverse_elements(double4 v)
    {
        v = __builtin_ia32_shufpd256(v, v, shuf_mask!(0, 0, 1, 1));
        v = __builtin_ia32_vperm2f128_pd256(v, v, shuf_mask!(0,0,0,1));
        return v;
    }
}

template Vector()
{
    alias double4 vec;
    alias double T;
    
    enum vec_size = 4;
    enum log2_bitreverse_chunk_size = 2;
    
    auto v(T* p){ return cast(vec*) p; }

    void complex_array_to_real_imag_vec(int n)(T* arr, ref vec rr, ref vec ri)
    {
        static if (n == 4)
            deinterleave(v(arr)[0], v(arr)[1], rr, ri);
        else static if(n == 2)
        {
            vec a = *v(arr);
            rr = unpcklpd(a, a);
            ri = unpckhpd(a, a);
        }
        else
            static assert(0);
    }
      
    void transpose(int elements_per_vector)(vec a0, vec a1, ref vec r0, ref vec r1)
    {
        static if(elements_per_vector == 4)
        {
            r0 = unpcklpd(a0, a1);
            r1 = unpckhpd(a0, a1);
        }
        else static if(elements_per_vector == 2)
        {
            r0 = interleave128_lo(a0, a1);
            r1 = interleave128_hi(a0, a1);
        }
        else
            static assert(0);
    }

    void interleave(vec a0, vec a1, ref vec r0, ref vec r1)
    {
        vec b0, b1;

        b0 = unpcklpd(a0, a1);
        b1 = unpckhpd(a0, a1);
        transpose!2(b0, b1, r0, r1);
    }
    
    void deinterleave(vec a0, vec a1, ref vec r0, ref vec r1)
    {
        vec b0, b1;

        transpose!2(a0, a1, b0, b1);
        r0 = unpcklpd(b0, b1);
        r1 = unpckhpd(b0, b1);
    }

    void bit_reverse(ref vec a0, ref vec a1, ref vec a2, ref vec a3)
    {
        vec b0, b1, b2, b3;

        b0 = unpcklpd(a0, a2);
        b2 = unpckhpd(a0, a2);
        b1 = unpcklpd(a1, a3);
        b3 = unpckhpd(a1, a3);

        a0 = interleave128_lo(b0, b1);
        a1 = interleave128_hi(b0, b1);
        a2 = interleave128_lo(b2, b3);
        a3 = interleave128_hi(b2, b3);
    }    

    vec scalar_to_vector(T a)
    {
        return a;
    }
   
    static if(
        is(typeof(loadupd)) &&
        is(typeof(storeupd)) &&
        is(typeof(reverse_elements)))
    {
        vec unaligned_load(T* p)
        {
            return loadupd(p);
        }

        void unaligned_store(T* p, vec v)
        {
            storeupd(p, v);
        }

        alias reverse_elements reverse;
    }
}

template Options()
{
    enum log2_bitreverse_large_chunk_size = 5;
    enum large_limit = 14;
    enum log2_optimal_n = 8;
    enum passes_per_recursive_call = 4;
    enum log2_recursive_passes_chunk_size = 4;
}

version(SSE_AVX)
{
    version(InstantiateAdditionalSimd)
    {
        import pfft.fft_impl;
        alias TypeTuple!(FFT!(Vector!(), Options!())) FFTs;
        mixin Instantiate!();
    }
    else
    {
        import pfft.instantiate_declarations;
        alias double T;
        mixin Instantiate!();
    }
}
