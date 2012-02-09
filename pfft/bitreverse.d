//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.bitreverse;

import core.bitop;

void _swap(T)(ref T a, ref T b)
{
    auto aa = a;
    auto bb = b;
    b = aa;
    a = bb;
}

template ints_up_to(int n, T...)
{
    static if(n)
    {
        alias ints_up_to!(n-1, n-1, T) ints_up_to;
    }
    else
        alias T ints_up_to;
}

auto bit_reversed_pairs(int _log2n)
{
    struct R
    {
        int log2n;
        int opApply(int delegate(ref uint, ref uint) dg)
        {
            int mask = (0xffffffff<<(log2n));
            uint i2 = ~mask; 
            uint i1 = i2;
            
            while(i1 != (0U - 1U))
            {
                auto r = dg(i1, i2);
                if(r)
                    return r;
                i2 = mask ^ (i2 ^ (mask>>(bsf(i1)+1)));
                --i1;
            }
            return 0;
        }
    }
    
    return R(_log2n);
}

void bit_reverse_simple(T)(T* p, int log2n)
{
    foreach(i0, i1; bit_reversed_pairs(log2n))
        if(i1 > i0)
            _swap(p[i0],p[i1]);
}

void bit_reverse_step(size_t chunk_size, T)(T* p, size_t nchunks)
{
    for(size_t i = chunk_size, j = (nchunks >> 1) * chunk_size; 
        j < nchunks * chunk_size; 
        j += chunk_size*2, i += chunk_size*2)
    {        
        foreach(k; ints_up_to!chunk_size)
            _swap(p[i + k], p[j + k]);
    }
}

void bit_reverse_simple_small(int max_log2n, T)(T* p, int log2n)
{
    assert(log2n <= max_log2n);
    
    size_t n = 1 << log2n;
    
    foreach(i; ints_up_to!(max_log2n/2))
    {
        if(i == max_log2n/2)
            return;
                
        foreach(j; 0..(1 << i))
            bit_reverse_step!(1<<i)(p + (n >> i)*j, n >> (2*i));
    }
}

auto aligned_ptr(T, U)(U * ptr, size_t alignment)
{
    return cast(T*)
        (((cast(size_t)ptr) + alignment) & ~(alignment - 1UL));
}

auto aligned_size(T)(size_t size, size_t alignment)
{
    return size * T.sizeof + alignment;
}

struct BitReverse(alias V, Options)
{
    alias V.T T;
    alias V.vec vec;
    
    static size_t br_table_size(int log2n){ return (1<<(log2n-4)) + 4; }
    
    static void init_br_table(uint * table, int log2n)
    {
        int j = 0;
        foreach(i0, i1; bit_reversed_pairs(log2n - 4))
            if(i1 == i0)
                (table[j] = i0<<2), j++;
        foreach(i0, i1; bit_reversed_pairs(log2n - 4))
            if(i1 < i0)
            {
                table[j] = i0<<2;
                j++;
                table[j] = i1<<2;
                j++;
            }
    }
    
    static void bit_reverse_small(T*  p, uint log2n, uint*  table)
    {
        const uint Log2l = 2U;
        size_t 
            tmp = log2n -Log2l - Log2l,
            n1 = (1u<<((tmp + 1)>>1)),
            n2 = (1u<<tmp),
            m = n2 << Log2l;
      
        uint* t1 = table + n1, t2 = table + n2;
        T* p1 = p + m, p2 = p1 + m, p3 = p2 + m;
      
        for(; table < t1; table++)
            V.bit_reverse_16( p, p1, p2, p3, table[0]);
        for(; table < t2; table += 2)
            V.bit_reverse_swap_16( p, p1, p2, p3, table[0], table[1]);
    }

    static void swap4once(vec * dst, vec * src)
    {
        vec a0 = src[0];
        vec a1 = src[1];
        vec a2 = src[2];
        vec a3 = src[3];
        vec a4 = dst[0];
        vec a5 = dst[1];
        vec a6 = dst[2];
        vec a7 = dst[3];
        dst[0] = a0;
        dst[1] = a1;
        dst[2] = a2;
        dst[3] = a3;
        src[0] = a4;
        src[1] = a5;
        src[2] = a6;
        src[3] = a7;
    }

    static void swap_some(int len, TT)(TT *  a, TT *  b)
        if(len*TT.sizeof % (vec.sizeof * 4) == 0)
    {
        foreach(i; 0 .. len * TT.sizeof / 4 / vec.sizeof)
            swap4once((cast(vec*)a) + 4 * i, (cast(vec*)b) + 4 * i);
    }
    
    static void copy8once(vec * dst, vec * src)
    {
        vec a0 = src[0];
        vec a1 = src[1];
        vec a2 = src[2];
        vec a3 = src[3];
        vec a4 = src[4];
        vec a5 = src[5];
        vec a6 = src[6];
        vec a7 = src[7];
        dst[0] = a0;
        dst[1] = a1;
        dst[2] = a2;
        dst[3] = a3;
        dst[4] = a4;
        dst[5] = a5;
        dst[6] = a6;
        dst[7] = a7;
    }

    static void copy_some(int len, TT)(TT *  a, TT *  b)
        if(len*TT.sizeof % (vec.sizeof*8) == 0)
    {
        foreach(i; 0 .. len * TT.sizeof / 8 / vec.sizeof)
            copy8once((cast(vec*)a) + 8 * i, (cast(vec*)b) + 8 * i);
    }
    
    static void bit_reverse_large(T* p, int log2n, uint * table)
    {
        enum log2l = Options.log2_bitreverse_large_chunk_size;
        enum l = 1<<log2l;
        
        ubyte[aligned_size!T(l * l, 64)] mem = void;
        auto buffer = aligned_ptr!T(mem.ptr, 64);
        
        int log2m = log2n - log2l;
        size_t m = 1<<log2m, n = 1<<log2n;
        T * pend = p + n;
      
        foreach(i0, i1; bit_reversed_pairs(log2m-log2l))
        {
            if(i1 >= i0)
            {
          
                for(T* pp = p + i0 * l, pb = buffer; pp < pend; pb += l, pp += m)
                    copy_some!l(pb, pp);//memcpy(pb, pp, l * T.sizeof);
          
                bit_reverse_small(buffer,log2l+log2l, table);

                if(i1 != i0)
                {
                    for(T* pp = p + i1 * l, pb = buffer; pp < pend; pb += l, pp += m)
                        swap_some!l(pp,pb);
                
                    bit_reverse_small(buffer,log2l+log2l, table);
                }

                for(T* pp = p + i0*l, pb = buffer; pp < pend; pp += m, pb += l)
                    copy_some!l(pp, pb);//memcpy(pp, pb, l*T.sizeof);
            }
        }
    }
}
