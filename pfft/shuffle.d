//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.shuffle;

import core.bitop;

template st(alias a){ enum st = cast(size_t) a; }

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

template powers_up_to(int n, T...)
{
    static if(n > 1)
    {
        alias powers_up_to!(n / 2, n / 2, T) powers_up_to;
    }
    else
        alias T powers_up_to;
}

template RepeatType(T, int n, R...)
{
    static if(n == 0)
        alias R RepeatType;
    else
        alias RepeatType!(T, n - 1, T, R) RepeatType;
}

void iter_bit_reversed_pairs(alias dg, A...)(int log2n, A args)
{
    int mask = (0xffffffff<<(log2n));
    uint i2 = ~mask; 
    uint i1 = i2;

    while(i1 != (0U - 1U))
    {
        dg(i1, i2, args);
        i2 = mask ^ (i2 ^ (mask>>(bsf(i1)+1)));
        --i1;
    }
}

void bit_reverse_simple(T)(T* p, int log2n)
{
    static void loopBody(int i0, int i1, T* p)
    {
        if(i1 > i0)
            _swap(p[i0],p[i1]);
    };

    iter_bit_reversed_pairs!loopBody(log2n, p);
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
    
    static size_t br_table_size()(int log2n)
    { 
        return (st!1 << log2n) < 16 ? 0 : (1<<(log2n-4)) + 4;
    }
    
    static void init_br_table()(uint* table, int log2n)
    {
        static void loopBody0(int i0, int i1, uint** p)
        {
            if(i1 == i0)
                (**p = i0<<2), (*p)++;
        };
        iter_bit_reversed_pairs!loopBody0(log2n - 4, &table);

        static void loopBody1(int i0, int i1, uint** p)
        {
            if(i1 < i0)
            {
                **p = i0<<2;
                (*p)++;
                **p = i1<<2;
                (*p)++;
            }
        };
        iter_bit_reversed_pairs!loopBody1(log2n - 4, &table);
    }
    
    static void bit_reverse_small()(T*  p, uint log2n, uint*  table)
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

    private static auto highest_power_2(int a, int maxpower)
    {
        while(a % maxpower)
            maxpower /= 2;

        return maxpower;     
    }

    static void swap_some(int n, TT)(TT* a, TT* b)
    {
        RepeatType!(TT, 2 * n) tmp;
        
        foreach(i; ints_up_to!n)
            tmp[i] = a[i];
        foreach(i; ints_up_to!n)
            tmp[i + n] = b[i];
        
        foreach(i; ints_up_to!n)
            b[i] = tmp[i];
        foreach(i; ints_up_to!n)
            a[i] = tmp[i + n];
    }

    static void swap_array(int len, TT)(TT *  a, TT *  b)
    {
        static assert(len*TT.sizeof % vec.sizeof == 0);
        
        enum n = highest_power_2( len * TT.sizeof / vec.sizeof, 4);
        
        foreach(i; 0 .. len * TT.sizeof / n / vec.sizeof)
            swap_some!n((cast(vec*)a) + n * i, (cast(vec*)b) + n * i);
    }
    
    static void copy_some(int n, TT)(TT* dst, TT* src)
    {
        RepeatType!(TT, n) a;
        
        foreach(i, _; a)
            a[i] = src[i];
        foreach(i, _; a)
            dst[i] = a[i];
    }
    
    static void copy_array(int len, TT)(TT *  a, TT *  b)
    {
        static assert((len * TT.sizeof % vec.sizeof == 0));
        
        enum n = highest_power_2( len * TT.sizeof / vec.sizeof, 8);

        foreach(i; 0 .. len * TT.sizeof / n / vec.sizeof)
            copy_some!n((cast(vec*)a) + n * i, (cast(vec*)b) + n * i);
    }
    
    static void bit_reverse_large()(T* p, int log2n, uint * table)
    {
        enum log2l = Options.log2_bitreverse_large_chunk_size;
        enum l = 1<<log2l;
        
        ubyte[aligned_size!T(l * l, 64)] mem = void;
        auto buffer = aligned_ptr!T(mem.ptr, 64);
        
        int log2m = log2n - log2l;
        size_t m = 1<<log2m, n = 1<<log2n;
        T * pend = p + n;
        
        iter_bit_reversed_pairs!(function (size_t i0, size_t i1, 
	    T* p, T* pend, size_t m, uint* table, T* buffer)
        {
            if(i1 >= i0)
            {
          
                for(T* pp = p + i0 * l, pb = buffer; pp < pend; pb += l, pp += m)
                    copy_array!l(pb, pp);
          
                bit_reverse_small(buffer,log2l+log2l, table);

                if(i1 != i0)
                {
                    for(T* pp = p + i1 * l, pb = buffer; pp < pend; pb += l, pp += m)
                        swap_array!l(pp, pb);
                
                    bit_reverse_small(buffer,log2l+log2l, table);
                }

                for(T* pp = p + i0*l, pb = buffer; pp < pend; pp += m, pb += l)
                    copy_array!l(pp, pb);
            }
        })(log2m-log2l, p, pend, m, table, buffer);
    }
}

private struct Scalar(TT)
{
    public:

    alias TT T;
    alias TT vec;
    enum vec_size = 1;
    
    static void interleave(int n)(vec a0, vec a1, ref vec r0, ref vec r1)
    {
        r0 = a0;
        r1 = a1; 
    }
    
    static void deinterleave(int n)(vec a0, vec a1, ref vec r0, ref vec r1)
    {
        r0 = a0;
        r1 = a1; 
    }
}

template hasInterleaving(V)
{
    enum hasInterleaving =  
        is(typeof(V.interleave!(V.vec_size))) && 
        is(typeof(V.deinterleave!(V.vec_size)));
}

struct InterleaveImpl(V, int chunk_size, bool isInverse) 
{
    static size_t itable_size_bytes()(int log2n)
    {
        return (bool.sizeof << log2n) / V.vec_size / chunk_size; 
    }

    static bool* interleave_table()(int log2n, void* p)
    {
        auto n = st!1 << log2n;
        auto is_cycle_minimum = cast(bool*) p;
        size_t n_chunks = n / V.vec_size / chunk_size;

        if(n_chunks < 4)
            return null;

        is_cycle_minimum[0 .. n_chunks] = true;    

        for(size_t i = 1;;)
        {
            size_t j = i;
            while(true)
            {
                j = j < n_chunks / 2 ? 2 * j : 2 * (j - n_chunks / 2) + 1;
                if(j == i)
                    break;

                is_cycle_minimum[j] = false;
            }

            // The last cycle minimum is at n / 2 - 1
            if(i == n_chunks / 2 - 1)
                break;           

            do i++; while(!is_cycle_minimum[i]);
        }

        return is_cycle_minimum;
    }

    static void interleave_chunks()(
        V.vec* a, size_t n_chunks, bool* is_cycle_minimum)
    {
        alias RepeatType!(V.vec, chunk_size) RT;
        alias ints_up_to!chunk_size indices;        

        for(size_t i = 1;;)
        {
            size_t j = i;

            RT element;
            auto p = &a[i * chunk_size];
            foreach(k; indices)
                element[k] = p[k];

            while(true)
            {
                static if(isInverse)
                    j = j & 1 ? j / 2 + n_chunks / 2 : j / 2;
                else
                    j = j < n_chunks / 2 ? 2 * j : 2 * (j - n_chunks / 2) + 1;
                
                if(j == i)
                    break;

                RT tmp;
                p = &a[j * chunk_size];
                foreach(k; indices)
                    tmp[k] = p[k];

                foreach(k; indices)
                    p[k] = element[k];

                foreach(k; indices)
                    element[k] = tmp[k];
            }

            p = &a[i * chunk_size];
            foreach(k; indices)
                p[k] = element[k];

            if(i == n_chunks / 2 - 1)
                break;           

            do i++; while(!is_cycle_minimum[i]);
        }
    }

    static void interleave_tiny()(V.vec* p, size_t len)
    {
        switch(len)
        {
            foreach(n; powers_up_to!(2 * chunk_size))
            {
                case 2 * n:

                    RepeatType!(V.vec, 2 * n) tmp;

                    static if(isInverse)
                        foreach(j; ints_up_to!n)
                            V.deinterleave!(V.vec_size)(
                                p[2 * j], p[2 * j + 1], tmp[j], 
                                tmp[n + j]);
                    else
                        foreach(j; ints_up_to!n)
                            V.interleave!(V.vec_size)(
                                p[j], p[n + j], 
                                tmp[2 * j], tmp[2 * j + 1]);

                    foreach(j; ints_up_to!(2 * n))
                        p[j] = tmp[j];

                    break;
            }

            default: {}
        }
    }

    static void interleave_chunk_elements()(V.vec* a, size_t n_chunks)
    {
        for(auto p = a; p < a + n_chunks * chunk_size; p += 2 * chunk_size)
        {
            RepeatType!(V.vec, 2 * chunk_size) tmp;

            static if(isInverse)
                foreach(j; ints_up_to!chunk_size)
                    V.deinterleave!(V.vec_size)(
                        p[2 * j], p[2 * j + 1], tmp[j], tmp[chunk_size + j]);
            else
                foreach(j; ints_up_to!chunk_size)
                    V.interleave!(V.vec_size)(
                        p[j], p[chunk_size + j], tmp[2 * j], tmp[2 * j + 1]);

            foreach(j; ints_up_to!(2 * chunk_size))
                p[j] = tmp[j];
        } 
    }

    static void interleave()(V.T* p, int log2n, bool* table)
    {
        auto n = st!1 << log2n;

        if(n < 4)
            return;
        else if(n < 2 * V.vec_size)
            return 
                InterleaveImpl!(Scalar!(V.T), V.vec_size / 2, isInverse)
                    .interleave_tiny(p, n);

        assert(n >= 2 * V.vec_size);
       
        auto vp = cast(V.vec*) p;
        auto vn = n / V.vec_size;
 
        if(n < 4 * V.vec_size * chunk_size)
            interleave_tiny(vp, vn);
        else
        {
            auto n_chunks = vn / chunk_size;
            static if(isInverse)
            {
                interleave_chunk_elements(vp, n_chunks);
                interleave_chunks(vp, n_chunks, table);
            }
            else
            {
                interleave_chunks(vp, n_chunks, table);
                interleave_chunk_elements(vp, n_chunks);
            }
        }  
    }
}

template Interleave(V, int chunk_size, bool isInverse)
{
    static if(hasInterleaving!V)
        alias InterleaveImpl!(V, chunk_size, isInverse) Interleave;
    else
        alias 
            InterleaveImpl!(Scalar!(V.T), chunk_size, isInverse) Interleave;
}
