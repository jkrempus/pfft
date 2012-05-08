//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.avx;

import core.simd;

import pfft.fft_impl;


struct Vector 
{
    alias float8 vec;
    alias float T;
    
    enum vec_size = 8;
   
    import pfft.avx_declarations;

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
    
    static void interleave(int interleaved)(vec a0, vec a1, ref vec r0, ref vec r1)
    {
        static if(interleaved == 8)
        {
            vec a0_tmp = unpcklps(a0, a1);
            a1 =         unpckhps(a0, a1);
            deinterleave!2(a0_tmp, a1, r0, r1);
        }
        else static if(interleaved == 4)
        {
            vec a0_tmp = shufps!(1,0,1,0)(a0, a1);
            a1 =         shufps!(3,2,3,2)(a0, a1);
            deinterleave!2(a0_tmp, a1, r0, r1);
        }
        else static if(interleaved == 2)
            deinterleave!2(a0, a1, r0, r1);
        else
            static assert(0);
    }
    
    static void deinterleave(int interleaved)(vec a0, vec a1, ref vec r0, ref vec r1)
    {
        static if(interleaved == 8)
        {
            deinterleave!2(a0, a1, a0, a1); 
            r0 = shufps!(2,0,2,0)(a0, a1);
            r1 = shufps!(3,1,3,1)(a0, a1);
        }
        else static if(interleaved == 4)
        {
            deinterleave!2(a0, a1, a0, a1); 
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

    static void bit_reverse_swap_16(float * p0, float * p1, float * p2, float * p3, size_t i1, size_t i2)
    {
        float8 a0, a1, a2, a3; 
        
        a0 = insert128_0(a0, *v(p0 + i1)); 
        a0 = insert128_1(a0, *v(p0 + i2)); 
        a1 = insert128_0(a1, *v(p1 + i1)); 
        a1 = insert128_1(a1, *v(p1 + i2)); 
        a2 = insert128_0(a2, *v(p2 + i1)); 
        a2 = insert128_1(a2, *v(p2 + i2)); 
        a3 = insert128_0(a3, *v(p3 + i1)); 
        a3 = insert128_1(a3, *v(p3 + i2)); 
        
        vec b0 = shufps!(1, 0, 1, 0)(a0, a2);
        vec b1 = shufps!(1, 0, 1, 0)(a1, a3);
        vec b2 = shufps!(3, 2, 3, 2)(a0, a2);
        vec b3 = shufps!(3, 2, 3, 2)(a1, a3);
        
        a0 = shufps!(2, 0, 2, 0)(b0, b1);
        a1 = shufps!(2, 0, 2, 0)(b2, b3);
        a2 = shufps!(3, 1, 3, 1)(b0, b1);
        a3 = shufps!(3, 1, 3, 1)(b2, b3);   
        
        *v(p0 + i1) = extract128_1(a0);
        *v(p0 + i2) = extract128_0(a0);
        *v(p1 + i1) = extract128_1(a1);
        *v(p1 + i2) = extract128_0(a1);
        *v(p2 + i1) = extract128_1(a2);
        *v(p2 + i2) = extract128_0(a2);
        *v(p3 + i1) = extract128_1(a3);
        *v(p3 + i2) = extract128_0(a3);
    }

    static void bit_reverse_16(float * p0, float * p1, float * p2, float * p3, size_t i)
    {
        vec a0, a1;

        a0 = insert128_0(a0, *v(p0 + i));
        a0 = insert128_1(a0, *v(p1 + i));
        a1 = insert128_0(a1, *v(p2 + i));
        a1 = insert128_1(a1, *v(p3 + i));

        vec b0 = shufps!(1, 0, 1, 0)(a0, a1);
        vec b1 = shufps!(3, 2, 3, 2)(a0, a1);

        a0 = interleave128_lo(b0, b1);
        a1 = interleave128_hi(b0, b1);

        b0 = shufps!(2, 0, 2, 0)(a0, a1);
        b1 = shufps!(3, 1, 3, 1)(a0, a1);

        *v(p0 + i) = extract128_0(b0);
        *v(p1 + i) = extract128_1(b0);
        *v(p2 + i) = extract128_0(b1);
        *v(p3 + i) = extract128_1(b1);

    }

    
    static vec scalar_to_vector(T a)
    {
        return a;
    }
}

struct Options
{
    enum log2_bitreverse_large_chunk_size = 5;
    enum large_limit = 14;
    enum log2_optimal_n = 8;
    enum passes_per_recursive_call = 5;
    enum log2_recursive_passes_chunk_size = 4;
}

