//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.avx_float;

import core.simd;

import pfft.fft_impl;

version(LDC)
{
    import pfft.avx_declarations;
}
else version(GNU)
{
    import gcc.builtins;

    template shuf_mask(int a3, int a2, int a1, int a0)
    { 
        enum shuf_mask = a0 | (a1<<2) | (a2<<4) | (a3<<6); 
    }

    pragma(attribute, always_inline);
    float8 insert128_0(float8 a, float4 b)
    {
        return __builtin_ia32_vinsertf128_ps256(a, b, 0);
    }

    pragma(attribute, always_inline);
    float8 insert128_1(float8 a, float4 b)
    {
        return __builtin_ia32_vinsertf128_ps256(a, b, 1);
    }

    pragma(attribute, always_inline);
    float4 extract128_0(float8 a)
    {
        return __builtin_ia32_vextractf128_ps256(a, 0);
    }

    pragma(attribute, always_inline);
    float4 extract128_1(float8 a)
    {
        return __builtin_ia32_vextractf128_ps256(a, 1);
    }

    pragma(attribute, always_inline);
    float8 interleave128_lo(float8 a, float8 b)
    {
        return __builtin_ia32_vperm2f128_ps256(a, b, shuf_mask!(0,2,0,0));
    }

    pragma(attribute, always_inline);
    float8 interleave128_hi(float8 a, float8 b)
    {
        return __builtin_ia32_vperm2f128_ps256(a, b, shuf_mask!(0,3,0,1));
    }

    pragma(attribute, always_inline);
    float8  reverse128(float8 v)
    {
        return __builtin_ia32_vperm2f128_ps256(v, v, shuf_mask!(0, 0, 0, 1));
    }

    alias __builtin_ia32_unpcklps256 unpcklps;
    alias __builtin_ia32_unpckhps256 unpckhps;
    alias __builtin_ia32_vbroadcastf128_ps256 broadcast128;
    alias __builtin_ia32_loadups256 loadups;
    alias __builtin_ia32_storeups256 storeups;
    
    pragma(attribute, always_inline);
    auto shufps(param...)(float8 a, float8 b)
    {
        return __builtin_ia32_shufps256(a, b, shuf_mask!param);
    }

}

struct Vector 
{
    alias float8 vec;
    alias float T;
    
    enum vec_size = 8;
  
    enum log2_bitreverse_chunk_size = 3;
 
    static auto v(T* p){ return cast(float4*) p; }
    static auto v8(T* p){ return cast(float8*) p; }
    
    static void complex_array_to_real_imag_vec(int n)(T* arr, ref vec rr, ref vec ri)
    {
        static if(n == 8)
            deinterleave!8(v8(arr)[0], v8(arr)[1], rr, ri);
        else static if (n == 4)
        {
            vec a = *v8(arr);
            rr = shufps!(2, 2, 0, 0)(a, a);
            ri = shufps!(3, 3, 1, 1)(a, a);
        }
        else static if(n == 2)
        {
            rr = insert128_0(rr, arr[0]);
            rr = insert128_1(rr, arr[2]);
            ri = insert128_0(ri,  arr[1]);
            ri = insert128_1(ri,  arr[3]);
        }
        else
            static assert(0);
    }
   
    pragma(attribute, always_inline) 
    static void _deinterleave2(vec a0, vec a1, ref vec r0, ref vec r1)
    {
        r0 = interleave128_lo(a0, a1);
        r1 = interleave128_hi(a0, a1);
    }
    
    static void interleave(int interleaved)(vec a0, vec a1, ref vec r0, ref vec r1)
    {
        static if(interleaved == 8)
        {
            vec a0_tmp = unpcklps(a0, a1);
            a1 =         unpckhps(a0, a1);
            _deinterleave2(a0_tmp, a1, r0, r1);
        }
        else static if(interleaved == 4)
        {
            vec a0_tmp = shufps!(1,0,1,0)(a0, a1);
            a1 =         shufps!(3,2,3,2)(a0, a1);
            _deinterleave2(a0_tmp, a1, r0, r1);
        }
        else static if(interleaved == 2)
            _deinterleave2(a0, a1, r0, r1);
        else
            static assert(0);
    }
    
    static void deinterleave(int interleaved)(vec a0, vec a1, ref vec r0, ref vec r1)
    {
        static if(interleaved == 8)
        {
            _deinterleave2(a0, a1, a0, a1); 
            r0 = shufps!(2,0,2,0)(a0, a1);
            r1 = shufps!(3,1,3,1)(a0, a1);
        }
        else static if(interleaved == 4)
        {
            _deinterleave2(a0, a1, a0, a1); 
            r0 = shufps!(1,0,1,0)(a0, a1);
            r1 = shufps!(3,2,3,2)(a0, a1);
        }
        else static if(interleaved == 2)
        {
            r0 = interleave128_lo(a0, a1);
            r1 = interleave128_hi(a0, a1);
        }
        else
            static assert(0);
    }

    private static void br16_two(ref vec a0, ref vec a1, ref vec a2, ref vec a3)
    {
        vec b0 = shufps!(1, 0, 1, 0)(a0, a2);
        vec b1 = shufps!(1, 0, 1, 0)(a1, a3);
        vec b2 = shufps!(3, 2, 3, 2)(a0, a2);
        vec b3 = shufps!(3, 2, 3, 2)(a1, a3);

        a0 = shufps!(2, 0, 2, 0)(b0, b1);
        a1 = shufps!(2, 0, 2, 0)(b2, b3);
        a2 = shufps!(3, 1, 3, 1)(b0, b1);
        a3 = shufps!(3, 1, 3, 1)(b2, b3);
    }

    
    template RepeatType(T, int n, R...)
    {
        static if(n == 0)
            alias R RepeatType;
        else
            alias RepeatType!(T, n - 1, T, R) RepeatType;
    }
        
    static void bit_reverse_swap(T* p0, T* p1, size_t m)
    {
        RepeatType!(vec, 8) a, b;    

        foreach(i, _; a)
            a[i] = *v8(p0 + i * m);

        // reverse the outer four bits 
        br16_two(a[0], a[2], a[4], a[6]);
        br16_two(a[1], a[3], a[5], a[7]);

        // reverse the inner two bits
        _deinterleave2(a[0], a[1], a[0], a[1]); 
        _deinterleave2(a[2], a[3], a[2], a[3]); 
        _deinterleave2(a[4], a[5], a[4], a[5]); 
        _deinterleave2(a[6], a[7], a[6], a[7]); 

        foreach(i, _; a)
            b[i] = *v8(p1 + i * m);

        foreach(i, _; a)
            *v8(p1 + i * m) = a[i];

        br16_two(b[0], b[2], b[4], b[6]);
        br16_two(b[1], b[3], b[5], b[7]);

        _deinterleave2(b[0], b[1], b[0], b[1]); 
        _deinterleave2(b[2], b[3], b[2], b[3]); 
        _deinterleave2(b[4], b[5], b[4], b[5]); 
        _deinterleave2(b[6], b[7], b[6], b[7]); 

        foreach(i, _; a)
            *v8(p0 + i * m) = b[i];
    }

    static void bit_reverse(T* p0, size_t m)
    {
        RepeatType!(vec, 8) a;    

        foreach(i, _; a)
            a[i] = *v8(p0 + i * m);

        // reverse the outer four bits 
        br16_two(a[0], a[2], a[4], a[6]);
        br16_two(a[1], a[3], a[5], a[7]);

        // reverse the inner two bits
        _deinterleave2(a[0], a[1], a[0], a[1]); 
        _deinterleave2(a[2], a[3], a[2], a[3]); 
        _deinterleave2(a[4], a[5], a[4], a[5]); 
        _deinterleave2(a[6], a[7], a[6], a[7]); 

        foreach(i, _; a)
            *v8(p0 + i * m) = a[i];
    }

    static vec scalar_to_vector(T a)
    {
        return a;
    }

    static vec unaligned_load(T* p)
    {
        return loadups(p);
    }

    static void unaligned_store(T* p, vec v)
    {
        storeups(p, v);
    }

    static vec reverse(vec v)
    {
        v = shufps!(0, 1, 2, 3)(v, v);
        return reverse128(v);
    }
}

struct Options
{
    enum log2_bitreverse_large_chunk_size = 5;
    enum large_limit = 14;
    enum log2_optimal_n = 8;
    enum passes_per_recursive_call = 4;
    enum log2_recursive_passes_chunk_size = 4;
    enum prefered_alignment = 4 * (1 << 10);
    enum { fast_init };
}

