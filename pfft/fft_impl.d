//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.fft_impl;

import pfft.shuffle;

struct Scalar(_T)
{
    alias _T vec;
    alias _T T;
    
    enum vec_size = 1;
    enum log2_bitreverse_chunk_size = 2;
    
    static vec scalar_to_vector(T a)
    {
        return a;
    }
   
    private static void load4br(T* p, size_t m, ref T a0, ref T a1, ref T a2, ref T a3)
    {
        a0 = p[0];
        a1 = p[m];
        a2 = p[1];
        a3 = p[m + 1];
    } 
 
    private static void store4(T* p, size_t m, T a0, T a1, T a2, T a3)
    {
        p[0] = a0;
        p[1] = a1;
        p[m] = a2;
        p[m + 1] = a3;
    }
 
    static void bit_reverse_swap(T * p0, T * p1, size_t m)
    {
        RepeatType!(T, 4) a, b;
       
        auto s = 2 * m;
        auto i0 = 0, i1 = 2, i2 = m, i3 = m + 2;
 
        load4br(p0, s, a); 
        load4br(p1, s, b); 
        store4(p1, s, a);     
        store4(p0, s, b);     
        
        load4br(p0 + i3, s, a); 
        load4br(p1 + i3, s, b); 
        store4(p1 + i3, s, a);     
        store4(p0 + i3, s, b);

        load4br(p0 + i1, s, a);
        load4br(p1 + i2, s, b);
        store4(p1 + i2, s, a);
        store4(p0 + i1, s, b);

        load4br(p1 + i1, s, a);
        load4br(p0 + i2, s, b);
        store4(p0 + i2, s, a);
        store4(p1 + i1, s, b);
    }

    static void bit_reverse(T * p,  size_t m)
    {
        //bit_reverse_static_size!4(p, m);
        T a0, a1, a2, b0, b1, b2;       

        a0 = p[1 + 0 * m];
        a1 = p[2 + 0 * m];
        a2 = p[3 + 0 * m];
        b0 = p[0 + 2 * m];
        b1 = p[0 + 1 * m];
        b2 = p[0 + 3 * m];

        p[0 + 2 * m] = a0;
        p[0 + 1 * m] = a1;
        p[0 + 3 * m] = a2;
        p[1 + 0 * m] = b0; 
        p[2 + 0 * m] = b1; 
        p[3 + 0 * m] = b2;

        a0 = p[1 + 1 * m];
        a1 = p[3 + 1 * m];
        a2 = p[3 + 2 * m];
        b0 = p[2 + 2 * m];
        b1 = p[2 + 3 * m];
        b2 = p[1 + 3 * m];

        p[2 + 2 * m] = a0;
        p[2 + 3 * m] = a1;
        p[1 + 3 * m] = a2;
        p[1 + 1 * m] = b0; 
        p[3 + 1 * m] = b1; 
        p[3 + 2 * m] = b2;
    }

    static T unaligned_load(T* p){ return *p; }
    static void unaligned_store(T* p, T a){ *p = a; }
    static T reverse(T a){ return a; }           
}

version(DisableLarge)
    enum disableLarge = true;
else 
    enum disableLarge = false;

struct _Tuple(A...)
{
    A a;
    alias a this;
}

void static_size_fft(int log2n, T)(T *pr, T *pi, T *table)
{ 
    enum n = 1 << log2n;
    RepeatType!(T, n) ar, ai;

    foreach(i; ints_up_to!n)
        ar[i] = pr[i];

    foreach(i; ints_up_to!n)
        ai[i] = pi[i];
    
    foreach(i; powers_up_to!n)
    {
        enum m = n / i;

        foreach(j; ints_up_to!(n / m))
        {
            enum offset = m * j;
            
            T wr = table[0];
            T wi = table[1];
            table += 2;
            foreach(k1; ints_up_to!(m / 2))
            {
                enum k2 = k1 + m / 2;
                static if(j == 0)
                {
                    T tr = ar[offset + k2], ti = ai[offset + k2];
                    T ur = ar[offset + k1], ui = ai[offset + k1];
                }
                else static if(j == 1)
                {
                    T tr = ai[offset + k2], ti = -ar[offset + k2];
                    T ur = ar[offset + k1], ui = ai[offset + k1];
                }
                else
                {
                    T tmpr = ar[offset + k2], ti = ai[offset + k2];
                    T ur = ar[offset + k1], ui = ai[offset + k1];
                    T tr = tmpr*wr - ti*wi;
                    ti = tmpr*wi + ti*wr;
                }
                ar[offset + k2] = ur - tr;
                ar[offset + k1] = ur + tr;                                                    
                ai[offset + k2] = ui - ti;                                                    
                ai[offset + k1] = ui + ti;
            }
        }
    }

    foreach(i; ints_up_to!n)
        pr[i] = ar[reverse_bits!(i, log2n)];

    foreach(i; ints_up_to!n)
        pi[i] = ai[reverse_bits!(i, log2n)];
}

struct FFT(V, Options)
{    
    import core.bitop, core.stdc.stdlib;
   
    alias BitReverse!(V, Options) BR;
    
    alias V.vec_size vec_size;
    alias V.T T;
    alias V.vec vec;
    alias FFT!(Scalar!T, Options) SFFT;
  
    import cmath = core.stdc.math;

    static if(is(T == float))
    {
        alias cmath.sinf _sin;
        alias cmath.cosf _cos;
        alias cmath.asinf _asin;
    }
    else static if(is(T == double))
    {
        alias cmath.sin _sin;
        alias cmath.cos _cos;
        alias cmath.asin _asin;
    }
    else static if(is(T == real))
    {
        alias cmath.sinl _sin;
        alias cmath.cosl _cos;
        alias cmath.asinl _asin;
    }
    else
        static assert(0);

    template st(alias a){ enum st = cast(size_t) a; }

    alias _Tuple!(T,T) Pair;
    
    static void complex_array_to_vector()(Pair * pairs, size_t n)
    {
        for(size_t i=0; i<n; i += vec_size)
        {
          T buffer[vec_size*2] = void;
          for(size_t j = 0; j < vec_size; j++)
          {
            buffer[j] = pairs[i+j][0];
            buffer[j + vec_size] = pairs[i+j][1];
          }
          for(size_t j = 0; j < vec_size; j++)
          {
            pairs[i+j][0] = buffer[2*j];
            pairs[i+j][1] = buffer[2*j+1];
          }
        }
    }

    static int log2()(int a)
    {
        int r = 0;
        while(a)
        {
            a >>= 1;
            r++;
        }
        return r - 1;
    }

    static void sines_cosines_refine(bool computeEven)(
        Pair* src, Pair* dest, size_t n_from, T dphi)
    {
        T cdphi = _cos(dphi);
        T sdphi = _sin(dphi);
       
        enum compute = computeEven ? 0 : 1;
        enum copy = compute ^ 1;
 
        for(auto src_end = src + n_from; src < src_end; src++, dest += 2)
        {
            auto c = src[0][0];
            auto s = src[0][1];
            dest[copy][0] = c;
            dest[copy][1] = s;
            dest[compute][0] = c * cdphi - s * sdphi;   
            dest[compute][1] = c * sdphi + s * cdphi;
        }
    }

    static void sines_cosines_table(bool phi0_is_last)(
        Pair* r, size_t n, T phi0, T deltaphi, bool bit_reversed)
    {
        r[n - 1][0] = _cos(phi0);
        r[n - 1][1] = _sin(phi0);
        for(size_t len = 1; len < n; len *= 2)
        {
            auto denom = bit_reversed ? n / 2 / len : len;
            sines_cosines_refine!phi0_is_last(
                r + n - len, r + n - 2 * len, len, deltaphi / 2 / denom);
        }
    } 
    
    static void fft_table_impl()(int log2n, Pair * r)
    {
        int n_reversed_loops = 
            (log2n >= Options.large_limit || log2n < 2 * log2(vec_size)) ?
                 0 : log2(vec_size);
                
        auto p = r;
        for (int s = 0; s < log2n; ++s)
        {
            size_t m2 = 1 << s;
            
            if(s < log2n - n_reversed_loops)
                sines_cosines_table!false(p, m2, 0.0, -2 * _asin(1), true);
            else
            {
                sines_cosines_table!false(p, m2, 0.0, -2 * _asin(1), false);
                complex_array_to_vector(p, m2);
            }
            
            p += m2;
        }
        
        p = r;
      
        
        if(log2n < 2 * log2(vec_size))
            return;        
 
        int start_s = 
            log2n < Options.large_limit ? 
                0 : 
                log2n - Options.log2_optimal_n - log2(vec_size);

        int s = 0;
        for(; s < start_s; s++)
        {
            size_t m = 1 << (s + 1);
            p += m/2;
        }
        for (; s + 1 < log2n - log2(vec_size);  s += 2)
        {
            size_t m = 1 << (s + 1);
            
            foreach(i; 0 .. m / 2)
            {
                Pair a1 = p[m / 2 + 2 * i];
                Pair a2, a3;
                
                a2[0] = a1[0] * a1[0] - a1[1] * a1[1];
                a2[1] = a1[0] * a1[1] + a1[1] * a1[0];
                
                a3[0] = a2[0] * a1[0] - a2[1] * a1[1];
                a3[1] = a2[0] * a1[1] + a2[1] * a1[0];
                
                p[3 * i] = a1;
                p[3 * i + 1] = a2;
                p[3 * i + 2] = a3;
            }
            
            p += m / 2 + m;
        }
    }
    
    alias void* Table;
    
    static T* table_ptr(void* p, int log2n)
    { 
        return cast(T*)p;
    }
    
    static uint* br_table_ptr(void* p, int log2n)
    {
        return cast(uint*)(p + ((2 * T.sizeof) << log2n));
    }
    
    static size_t table_size_bytes()(uint log2n)
    {
        uint log2nbr = log2n < Options.large_limit ? 
            log2n : 2 * Options.log2_bitreverse_large_chunk_size;
        
        return 
            ((2 * T.sizeof) << log2n) + BR.br_table_size(log2nbr) * uint.sizeof;
    }
    
    static Table fft_table()(int log2n, void * p)
    {   
        if(log2n == 0)
            return p;
        //else if(log2n <= log2(vec_size))
         //   return SFFT.fft_table(log2n, p);
        
        Table tables = p;
        
        fft_table_impl(log2n, cast(Pair *)(table_ptr(tables, log2n) + 2));
        
        if(log2n < V.log2_bitreverse_chunk_size * 2)
        {
        }
        else if(log2n < Options.large_limit)
        {
            BR.init_br_table(br_table_ptr(tables, log2n), log2n);
        }
        else
        {
            enum log2size = 2*Options.log2_bitreverse_large_chunk_size;
            BR.init_br_table(br_table_ptr(tables, log2n), log2size);
        }
        return tables;
    }
    
    static void fft_passes_bit_reversed()(vec* re, vec* im, size_t N , 
        vec* table, size_t start_stride = 1)
    {
        table += start_stride + start_stride;
        vec* pend = re + N;
        for (size_t m2 = start_stride; m2 < N ; m2 <<= 1)
        {      
            size_t m = m2 + m2;
            for(
                vec* pr = re, pi = im; 
                pr < pend ;
                pr += m, pi += m)
            {
                for (size_t k1 = 0, k2 = m2; k1<m2; k1++, k2 ++) 
                {  
                    vec wr = table[2*k1], wi = table[2*k1+1];                       

                    vec tmpr = pr[k2], ti = pi[k2];
                    vec ur = pr[k1], ui = pi[k1];
                    vec tr = tmpr*wr - ti*wi;
                    ti = tmpr*wi + ti*wr;
                    pr[k2] = ur - tr;
                    pr[k1] = ur + tr;                                                    
                    pi[k2] = ui - ti;                                                    
                    pi[k1] = ui + ti;
                }
            }
            table += m;
        }
    }
    
    static void first_fft_passes()(vec* pr, vec* pi, size_t n)
    {
        size_t i0 = 0, i1 = i0 + n/4, i2 = i1 + n/4, i3 = i2 + n/4, iend = i1;

        for(; i0 < iend; i0++, i1++, i2++, i3++)
        {
            vec tr = pr[i2], ti = pi[i2];
            vec ur = pr[i0], ui = pi[i0];
            vec ar0 = ur + tr;
            vec ar2 = ur - tr;
            vec ai0 = ui + ti;
            vec ai2 = ui - ti;

            tr = pr[i3], ti = pi[i3];
            ur = pr[i1], ui = pi[i1];
            vec ar1 = ur + tr;
            vec ar3 = ur - tr;
            vec ai1 = ui + ti;
            vec ai3 = ui - ti;

            pr[i0] = ar0 + ar1;
            pr[i1] = ar0 - ar1;
            pi[i0] = ai0 + ai1;
            pi[i1] = ai0 - ai1;

            pr[i2] = ar2 + ai3;
            pr[i3] = ar2 - ai3;
            pi[i2] = ai2 - ar3;
            pi[i3] = ai2 + ar3;      
        }
    }
        
    static void fft_pass()(vec *pr, vec *pi, vec *pend, T *table, size_t m2)
    {
        size_t m = m2 + m2;
        for(; pr < pend ; pr += m, pi += m)
        {
            vec wr = V.scalar_to_vector(table[0]);
            vec wi = V.scalar_to_vector(table[1]);
            table += 2;
            for (size_t k1 = 0, k2 = m2; k1<m2; k1++, k2 ++) 
            { 
                vec tmpr = pr[k2], ti = pi[k2];
                vec ur = pr[k1], ui = pi[k1];
                vec tr = tmpr*wr - ti*wi;
                ti = tmpr*wi + ti*wr;
                pr[k2] = ur - tr;
                pr[k1] = ur + tr;                                                    
                pi[k2] = ui - ti;                                                    
                pi[k1] = ui + ti;
            }
        }
    }
    
    static void fft_two_passes()(vec *pr, vec *pi, vec *pend, T *table, size_t m2)
    {
        size_t m = m2 + m2;
        size_t m4 = m2 / 2;
        for(; pr < pend ; pr += m, pi += m)
        {
            vec w1r = V.scalar_to_vector(table[0]);
            vec w1i = V.scalar_to_vector(table[1]);
            
            vec w2r = V.scalar_to_vector(table[2]);
            vec w2i = V.scalar_to_vector(table[3]);
            
            vec w3r = V.scalar_to_vector(table[4]);
            vec w3i = V.scalar_to_vector(table[5]);
            
            table += 6;
            
            for (
                size_t k0 = 0, k1 = m4, k2 = m2, k3 = m2 + m4; 
                k0<m4; k0++, 
                k1++, k2++, k3++) 
            {                 
                vec tr, ur, ti, ui;
                
                vec r0 = pr[k0];
                vec r1 = pr[k1];
                vec r2 = pr[k2];
                vec r3 = pr[k3];
                
                vec i0 = pi[k0];
                vec i1 = pi[k1];
                vec i2 = pi[k2];
                vec i3 = pi[k3];
                
                tr = r2 * w2r - i2 * w2i;
                ti = r2 * w2i + i2 * w2r;
                r2 = r0 - tr;
                i2 = i0 - ti;
                r0 = r0 + tr;
                i0 = i0 + ti;
                
                tr = r3 * w3r - i3 * w3i;
                ti = r3 * w3i + i3 * w3r;
                ur = r1 * w1r - i1 * w1i;
                ui = r1 * w1i + i1 * w1r;
                r3 = ur - tr;
                i3 = ui - ti;
                r1 = ur + tr;
                i1 = ui + ti;
                
                tr = r1;
                ti = i1;
                r1 = r0 - tr;
                i1 = i0 - ti;
                r0 = r0 + tr;
                i0 = i0 + ti;
                
                tr = i3;
                ti = r3;                // take minus into account later
                r3 = r2 - tr;
                i3 = i2 + ti;
                r2 = r2 + tr;
                i2 = i2 - ti;
                
                pr[k0] = r0;
                pr[k1] = r1;
                pr[k2] = r2;
                pr[k3] = r3;
                
                pi[k0] = i0;
                pi[k1] = i1;
                pi[k2] = i2;
                pi[k3] = i3;
            }
        }
    }
    
    static void fft_passes()(vec* re, vec* im, size_t N , T* table)
    {
        vec * pend = re + N;

        size_t tableRowLen = 2;
        size_t m2 = N/2;

        if(m2 > 1)
        {
            first_fft_passes(re, im, N);
            
            m2 >>= 1;
            table += tableRowLen;
            tableRowLen += tableRowLen;
            m2 >>= 1;
            table += tableRowLen;
            tableRowLen += tableRowLen;
        }
        
        for (; m2 > 1 ; m2 >>= 2)
        {
            fft_two_passes(re, im, pend, table, m2);
            table += tableRowLen;
            tableRowLen += tableRowLen;
            table += tableRowLen;
            tableRowLen += tableRowLen;
        }
        
        if (m2 != 0)
        {
            fft_pass(re, im, pend, table, m2);
            table += tableRowLen;
            tableRowLen += tableRowLen;
        }
    }
    
    static void nextTableRow()(
        ref T*  table, ref size_t tableRowLen, ref size_t tableI)
    {
        table += tableRowLen;
        tableI += tableI;
        tableRowLen += tableRowLen;        
    }

    static void fft_pass_interleaved(int interleaved)(
        vec * pr, vec * pi, vec * pend, T * table) 
    if(is(typeof(V.interleave!2)))
    {
        for(; pr < pend; pr += 2, pi += 2, table += 2*interleaved)
        {
            vec tmpr, ti, ur, ui, wr, wi;
            V.complex_array_to_real_imag_vec!interleaved(table, wr, wi);
                
            V.deinterleave!interleaved(pr[0], pr[1], ur, tmpr);
            V.deinterleave!interleaved(pi[0], pi[1], ui, ti);

            vec tr = tmpr * wr - ti * wi;
            ti = tmpr * wi + ti * wr;

            V.interleave!interleaved(ur + tr, ur - tr, pr[0], pr[1]);
            V.interleave!interleaved(ui + ti, ui - ti, pi[0], pi[1]);
        }
    }
    
    static static void fft_passes_fractional()(
        vec * pr, vec * pi, vec * pend, 
        T * table, size_t tableI, size_t tableRowLen)
    {
        static if(is(typeof(V.interleave!2)))
        {
            foreach(i; ints_up_to!(log2(vec_size)))
            {
                fft_pass_interleaved!(1 << (1 + i))(
                    pr, pi, pend, table + tableI);

                nextTableRow(table, tableRowLen, tableI);
            }
        }
        else
            for (size_t m2 = vec_size >> 1; m2 > 0 ; m2 >>= 1)
            {
                SFFT.fft_pass(
                    cast(T*) pr, cast(T*) pi, cast(T*)pend, table + tableI, m2);
                
                nextTableRow(table, tableRowLen, tableI);  
            }
    }
    
    static void fft_passes_strided(int l, int chunk_size)(
        vec * pr, vec * pi, size_t N , 
        ref T * table, ref size_t tableI, ref size_t tableRowLen, 
        size_t stride, int nPasses)
    {
        ubyte[aligned_size!vec(l * chunk_size, 64)] rmem = void;
        ubyte[aligned_size!vec(l * chunk_size, 64)] imem = void;
        
        auto rbuf = aligned_ptr!vec(rmem.ptr, 64);
        auto ibuf = aligned_ptr!vec(imem.ptr, 64);
      
        for(
            vec* pp = pr, pb = rbuf; 
            pp < pr + N; 
            pb += chunk_size, pp += stride)
        {
            BR.copy_array!chunk_size(pb, pp);
        }
        
        for(
            vec* pp = pi, pb = ibuf; 
            pp < pi + N; 
            pb += chunk_size, pp += stride)
        {
            BR.copy_array!chunk_size(pb, pp);
        }
        
        size_t m2 = l*chunk_size/2;
        size_t m2_limit = m2>>nPasses;

        if(tableRowLen == 2 && nPasses >= 2)
        {
            first_fft_passes(rbuf, ibuf, l*chunk_size);
            m2 >>= 1;
            nextTableRow(table, tableRowLen, tableI);
            m2 >>= 1;
            nextTableRow(table, tableRowLen, tableI);
        }
        
        for(; m2 > m2_limit; m2 >>= 1)
        {
            fft_pass(rbuf, ibuf, rbuf + l*chunk_size, table + tableI, m2);
            nextTableRow(table, tableRowLen, tableI);  
        }
      
        for(
            vec* pp = pr, pb = rbuf; 
            pp < pr + N; 
            pb += chunk_size, pp += stride)
        {
            BR.copy_array!chunk_size(pp, pb);
        }
        
        for(
            vec* pp = pi, pb = ibuf; 
            pp < pi + N; 
            pb += chunk_size, pp += stride)
        {
            BR.copy_array!chunk_size(pp, pb);
        }
    }
    
    static void fft_passes_recursive()(
        vec * pr, vec *  pi, size_t N , 
        T * table, size_t tableI, size_t tableRowLen)
    {
        if(N <= (1<<Options.log2_optimal_n))
        {
            size_t m2 = N >> 1;
            for (; m2 > 1 ; m2 >>= 2)
            {
                fft_two_passes(pr, pi, pr + N, table + 3 * tableI, m2);
                nextTableRow(table, tableRowLen, tableI); 
                nextTableRow(table, tableRowLen, tableI);  
            }
            if (m2 != 0)
            {
                fft_pass(pr, pi, pr + N, table + tableI, m2);
                nextTableRow(table, tableRowLen, tableI);  
            }
            
            fft_passes_fractional(pr, pi, pr + N, 
                table, tableI, tableRowLen);

            return;
        }
    
        enum l = 1UL << Options.passes_per_recursive_call;
        enum chunk_size = 1UL << Options.log2_recursive_passes_chunk_size;

        int log2n = bsf(N);

        int nPasses = 
            log2n > Options.passes_per_recursive_call + Options.log2_optimal_n ?
                Options.passes_per_recursive_call : 
                log2n - Options.log2_optimal_n;

        int log2m = log2n - Options.passes_per_recursive_call;
        size_t m = st!1 << log2m;
        
        T *  tableOld = table;
        size_t tableIOld = tableI;
        size_t tableRowLenOld = tableRowLen;

        for(size_t i=0; i < m; i += chunk_size)
        {
            table = tableOld;
            tableI = tableIOld;
            tableRowLen = tableRowLenOld;

            fft_passes_strided!(l, chunk_size)(
                pr + i, pi + i, N, table, tableI, tableRowLen, m, nPasses);
        }

        {
            size_t nextN = (N>>nPasses);

            for(int i = 0; i<(1<<nPasses); i++)
                fft_passes_recursive(
                    pr + nextN*i, pi  + nextN*i, nextN, 
                    table, tableI + 2*i, tableRowLen);
        }
    }
   
    static void bit_reverse_small_two(int minLog2n)(
        T* re, T* im, int log2n, uint* brTable)
    {
        enum l = V.log2_bitreverse_chunk_size;
        
        static if(minLog2n < 2 * l)
        {
            if(log2n < 2 * l)
            {
                // only works for log2n < 2 * l
                //bit_reverse_step!1(re, 1 << log2n);                     
                //bit_reverse_step!1(im, 1 << log2n);
                bit_reverse_tiny!(2 * l)(re, log2n);
                bit_reverse_tiny!(2 * l)(im, log2n);
            }
            else
            {
                BR.bit_reverse_small(re, log2n, brTable); 
                BR.bit_reverse_small(im, log2n, brTable);
            }
        }
        else                                                            
        {
            //we already know that log2n >= 2 * l here.
            BR.bit_reverse_small(re, log2n, brTable); 
            BR.bit_reverse_small(im, log2n, brTable);
        }   
    }

    static auto v(T* p){ return cast(vec*) p; }

    static void fft_tiny()(T * re, T * im, int log2n, Table tables)
    {
        // assert(log2n > log2(vec_size));
        
        size_t N = (1<<log2n);
        fft_passes(v(re), v(im), N / vec_size, table_ptr(tables, log2n) + 2);
        
        fft_passes_fractional(v(re), v(im), v(re) + N / vec_size, 
            table_ptr(tables, log2n) + 2 * N / vec_size, 0, 2 * N  / vec_size);

        bit_reverse_small_two!(log2(vec_size) + 1)(
            re, im, log2n, br_table_ptr(tables, log2n));
    }

    static void fft_small()(T * re, T * im, int log2n, Table tables)
    {
        // assert(log2n >= 2*log2(vec_size));
        
        size_t N = (1<<log2n);
        fft_passes(v(re), v(im), N / vec_size, table_ptr(tables, log2n) + 2);
        
        bit_reverse_small_two!(2 * log2(vec_size))(
            re, im, log2n, br_table_ptr(tables, log2n));

        static if(vec_size > 1) 
            fft_passes_bit_reversed(
                v(re), v(im) , N / vec_size, 
                cast(vec*) table_ptr(tables, log2n), N/vec_size/vec_size);
    }
    
    static void fft_large()(T * re, T * im, int log2n, Table tables)
    {
        size_t N = (1<<log2n);
        
        fft_passes_recursive(
            v(re), v(im), N / vec_size, 
            table_ptr(tables, log2n) + 2, 0, 2);
        
        BR.bit_reverse_large(re, log2n, br_table_ptr(tables, log2n)); 
        BR.bit_reverse_large(im, log2n, br_table_ptr(tables, log2n));
    }
    
    static void fft()(T * re, T * im, int log2n, Table tables)
    {
        foreach(i; ints_up_to!(log2(vec_size) + 1))
            if(i == log2n)
                return static_size_fft!i(re, im, table_ptr(tables, i) + 2);

        if(log2n < 2 * log2(vec_size))
            return fft_tiny(re, im, log2n, tables);
        else if( log2n < Options.large_limit || disableLarge)
            return fft_small(re, im, log2n, tables);
        else 
            static if(!disableLarge)
                fft_large(re, im, log2n, tables);
    }
  
    alias T* RTable;
 
    static auto rtable_size_bytes()(int log2n)
    {
        return T.sizeof << (log2n - 1);
    }

    enum supportsReal = is(typeof(
    {
        T a;
        vec v = V.unaligned_load(&a);
        v = V.reverse(v);
        V.unaligned_store(&a, v);
    }));

    static RTable rfft_table()(int log2n, void *p) if(supportsReal)
    {
        if(log2n < 2)
            return cast(RTable) p;
        else if(st!1 << log2n < 4 * vec_size)
            return SFFT.rfft_table(log2n, p);

        auto r = (cast(Pair*) p)[0 .. (st!1 << (log2n - 2))];

        auto phi = _asin(1);
        sines_cosines_table!true(r.ptr, r.length, -phi, phi, false);

        /*foreach(size_t i, ref e; r)
        {
            T phi = - (_asin(1.0) * (i + 1)) / r.length;
 
            e[0] = _cos(phi);
            e[1] = _sin(phi);
        }*/
        
        complex_array_to_vector(r.ptr, r.length);

        return cast(RTable) r.ptr;
    }

    static auto rfft_table()(int log2n, void *p) if(!supportsReal)
    {
        return SFFT.rfft_table(log2n, p);
    }

    static void rfft()(
        T* rr, T* ri, int log2n, Table table, RTable rtable) 
    {
        if(log2n == 0)
            return;
        else if(log2n == 1)
        {
            auto rr0 = rr[0], ri0 = ri[0];
            rr[0] = rr0 + ri0;
            ri[0] = rr0 - ri0;
            return;
        }

        fft(rr, ri, log2n - 1, table);
        rfft_last_pass!false(rr, ri, log2n, rtable);
    }

    static void irfft()(
        T* rr, T* ri, int log2n, Table table, RTable rtable) 
    {
        if(log2n == 0)
            return;
        else if(log2n == 1)
        {
            // we don't multiply with 0.5 here because we want the inverse to
            // be scaled by 2.

            auto rr0 = rr[0], ri0 = ri[0];
            rr[0] = (rr0 + ri0);
            ri[0] = (rr0 - ri0);
            return;
        }

        rfft_last_pass!true(rr, ri, log2n, rtable);
        fft(ri, rr, log2n - 1, table);
    }

    static void rfft_last_pass(bool inverse)(T* rr, T* ri, int log2n, RTable rtable) 
    if(supportsReal)
    {
        if(st!1 << log2n < 4 * vec_size)
            return SFFT.rfft_last_pass!inverse(rr, ri, log2n, rtable);       
 
        static vec* v(T* a){ return cast(vec*) a; }

        auto n = st!1 << log2n;

        vec half = V.scalar_to_vector(cast(T) 0.5);

        T middle_r = rr[n / 4];        
        T middle_i = ri[n / 4];        

        for(
            size_t i0 = 1, i1 = n / 2 - vec_size, iw = 0; 
            i0 <= i1; 
            i0 += vec_size, i1 -= vec_size, iw += 2*vec_size)
        {
            vec wr = *v(rtable + iw);
            vec wi = *v(rtable + iw + vec_size);

            vec r0r = V.unaligned_load(&rr[i0]);
            vec r0i = V.unaligned_load(&ri[i0]);
            vec r1r = V.reverse(*v(rr + i1));
            vec r1i = V.reverse(*v(ri + i1));

            vec ar = r0r + r1r;
            vec ai = r1i - r0i;
            vec br = r0r - r1r;
            vec bi = r0i + r1i;

            static if(inverse) 
            {
                // we use -w* instead of w in this case and we do not divide by 2.
                // The reason for that is that we want the inverse to be scaled
                // by n as it is in the complex case and not just by n / 2.

                vec tmp = br * wi - bi * wr;
                br = bi * wi + br * wr;
                bi = tmp;
            }
            else
            {
                ar *= half;
                ai *= half;
                br *= half;
                bi *= half;
                vec tmp = br * wi + bi * wr;
                br = bi * wi - br * wr;
                bi = tmp;
            }

            V.unaligned_store(rr + i0, ar + bi);
            V.unaligned_store(ri + i0, br - ai);

            *v(rr + i1) = V.reverse(ar - bi);
            *v(ri + i1) = V.reverse(ai + br);
        }
        
        // fixes the aliasing bug:
        rr[n / 4] = inverse ? middle_r + middle_r : middle_r; 
        ri[n / 4] = -(inverse ? middle_i + middle_i : middle_i);
        

        {
            // When calculating inverse we would need to multiply with 0.5 here 
            // to get an exact inverse. We don't do that because we actually
            // want the inverse to be scaled by 2.         
    
            auto r0r = rr[0];
            auto r0i = ri[0];
            
            rr[0] = r0r + r0i;
            ri[0] = r0r - r0i;
        }
    }
    
    static void rfft_last_pass(bool inverse)(T* rr, T* ri, int log2n, RTable rtable) 
    if(!supportsReal)
    {
        SFFT.rfft_last_pass!inverse(rr, ri, log2n, rtable); 
    }

    static void interleave_array()(T* even, T* odd, T* interleaved, size_t n)
    {
        static if(is(typeof(V.interleave!vec_size)))
        {
            if(n < vec_size)
                SFFT.interleave_array(even, odd, interleaved, n);
            else
                foreach(i; 0 .. n / vec_size)
                    V.interleave!vec_size(
                        (cast(vec*)even)[i], 
                        (cast(vec*)odd)[i], 
                        (cast(vec*)interleaved)[i * 2], 
                        (cast(vec*)interleaved)[i * 2 + 1]);
        }
        else
            foreach(i; 0 .. n)
            {
                interleaved[i * 2] = even[i];
                interleaved[i * 2 + 1] = odd[i];
            }
    }
    
    static void deinterleave_array()(T* even, T* odd, T* interleaved, size_t n)
    {
        static if(is(typeof(V.deinterleave!vec_size)))
        {
            if(n < vec_size)
                SFFT.deinterleave_array(even, odd, interleaved, n);
            else
                foreach(i; 0 .. n / vec_size)
                    V.deinterleave!vec_size(
                        (cast(vec*)interleaved)[i * 2], 
                        (cast(vec*)interleaved)[i * 2 + 1], 
                        (cast(vec*)even)[i], 
                        (cast(vec*)odd)[i]);
        }
        else
            foreach(i; 0 .. n)
            {
                even[i] = interleaved[i * 2];
                odd[i] = interleaved[i * 2 + 1];
            }
    }

    alias bool* ITable;
    
    alias Interleave!(V, 8, false).itable_size_bytes itable_size_bytes;
    alias Interleave!(V, 8, false).interleave_table interleave_table;
    alias Interleave!(V, 8, false).interleave interleave;
    alias Interleave!(V, 8, true).interleave deinterleave;

    static void scale(T* data, size_t n, T factor)
    {
        auto k  = V.scalar_to_vector(factor);
        
        foreach(ref e; (cast(vec*) data)[0 .. n / vec_size])
            e = e * k;

        foreach(ref e;  data[ n & ~(vec_size - 1) .. n])
            e = e * factor;
    }

    static size_t alignment(size_t n)
    {
        static if(is(typeof(Options.prefered_alignment)) && 
            Options.prefered_alignment > vec.sizeof)
        {
            enum a = Options.prefered_alignment;
        } 
        else
            enum a = vec.sizeof; 
        
        auto bytes = T.sizeof << bsr(n);
        
        bytes = bytes < a ? bytes : a;
        return bytes > (void*).sizeof ? bytes : (void*).sizeof;
    }
}

template instantiate(alias F)
{
    enum instantiate = 
    ` 
        private alias `~F.stringof~` F;
        alias F.T T;
        
        //alias void* Table;
        struct TableValue{};
        alias TableValue* Table;

        void fft(T* re, T* im, uint log2n, Table t)
        {
            F.fft(re, im, log2n, cast(F.Table) t);
        }
        
        auto fft_table(uint log2n, void* p = null)
        {
            return cast(Table) F.fft_table(log2n, p);
        }
        
        auto table_size_bytes(uint log2n)
        {
            return F.table_size_bytes(log2n);
        }

        void scale(T* data, size_t n, T factor)
        {
            F.scale(data, n, factor); 
        }
        
        size_t alignment(size_t n)
        {
            return F.alignment(n);
        }

        struct RTableValue{};
        alias RTableValue* RTable;

        void rfft(T* re, T* im, uint log2n, Table t, RTable rt)
        {
            F.rfft(re, im, log2n, cast(F.Table) t, cast(F.RTable) rt);
        }
        
        void irfft(T* re, T* im, uint log2n, Table t, RTable rt)
        {
            F.irfft(re, im, log2n, cast(F.Table) t, cast(F.RTable) rt);
        }

        auto rfft_table(uint log2n, void* p = null)
        {
            return cast(RTable) F.rfft_table(log2n, p);
        }

        size_t rtable_size_bytes(int log2n)
        {
            return F.rtable_size_bytes(log2n);
        }
        
        void deinterleave_array(T* even, T* odd, T* interleaved, size_t n)
        {
            F.deinterleave_array(even, odd, interleaved, n);
        }

        void interleave_array(T* even, T* odd, T* interleaved, size_t n)
        {
            F.interleave_array(even, odd, interleaved, n);
        }
        
        struct ITableValue{};
        alias ITableValue* ITable;

        auto itable_size_bytes(uint log2n)
        {
            return F.itable_size_bytes(log2n);
        }

        auto interleave_table(uint log2n, void* p)
        {
            return cast(ITable) F.interleave_table(log2n, p);
        }

        void interleave(T* p, uint log2n, ITable table)
        {
            F.interleave(p, log2n, cast(F.ITable) table);  
        }

        void deinterleave(T* p, uint log2n, ITable table)
        {
            F.deinterleave(p, log2n, cast(F.ITable) table);  
        }
    `;
}    
