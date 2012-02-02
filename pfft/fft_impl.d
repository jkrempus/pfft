//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.fft_impl;


import std.typecons, std.math, std.c.string, std.traits, std.parallelism;
import core.bitop, core.memory;

import pfft.bitreverse;

struct Scalar(_T)
{
    alias _T vec;
    alias _T T;
    
    enum vec_size = 1;
    
    static vec scalar_to_vector(T a)
    {
        return a;
    }
    
    static void bit_reverse_swap_16(T * p0, T * p1, T * p2, T * p3, size_t i1, size_t i2)
    {
        _swap(p0[0+i1],p0[0+i2]);
        _swap(p0[1+i1],p2[0+i2]);
        _swap(p0[2+i1],p1[0+i2]);
        _swap(p0[3+i1],p3[0+i2]);
        _swap(p1[0+i1],p0[2+i2]);
        _swap(p1[1+i1],p2[2+i2]);
        _swap(p1[2+i1],p1[2+i2]);
        _swap(p1[3+i1],p3[2+i2]);
        _swap(p2[0+i1],p0[1+i2]);
        _swap(p2[1+i1],p2[1+i2]);
        _swap(p2[2+i1],p1[1+i2]);
        _swap(p2[3+i1],p3[1+i2]);
        _swap(p3[0+i1],p0[3+i2]);
        _swap(p3[1+i1],p2[3+i2]);
        _swap(p3[2+i1],p1[3+i2]);
        _swap(p3[3+i1],p3[3+i2]);
    }

    static void bit_reverse_16(T * p0, T * p1, T * p2, T * p3, size_t i)
    {
        _swap(p0[1+i],p2[0+i]);
        _swap(p0[2+i],p1[0+i]);
        _swap(p0[3+i],p3[0+i]);
        _swap(p1[1+i],p2[2+i]);
        _swap(p1[3+i],p3[2+i]);
        _swap(p2[3+i],p3[1+i]);
    }            
}

struct _FFTTables(T)
{
    T * table;
    uint * brTable;
}

template FFT(alias V, Options)
{
    alias BitReverse!(V, Options) BR;
    
    alias V.vec_size vec_size;
    alias V.T T;
    alias V.vec vec;
    
    void complex_array_to_vector(Tuple!(T,T) * pairs, size_t n)
    {
        for(size_t i=0; i<n; i += vec_size)
        {
          T buffer[vec_size*2];
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

    int log2(int a)
    {
        int r = 0;
        while(a)
        {
            a >>= 1;
            r++;
        }
        return r - 1;
    }
    
    void fft_table_impl(int log2n, int n_reversed_loops, Tuple!(T,T) * r)
    {
        auto p = r;
        for (int s = 1; s <= log2n; ++s)
        {
            size_t m = 1 << s;
            double dphi = 4.0*asin(1.0) / m;
            for(size_t i=0; i< m/2; i++)
            {
                p[i][0] = cos(dphi*i);
                p[i][1] = -sin(dphi*i);
            }
            if(s <= log2n - n_reversed_loops)
                bit_reverse_simple(p, s - 1);
            else
                complex_array_to_vector(p, m/2);
            p += m/2;
        }
    }
    
    alias _FFTTables!T Tables;
    
    Tables tables(int log2n)
    {
        if(log2n < 2*log2(vec_size))
            return FFT!(Scalar!T, Options).tables(log2n);
        
        Tables tables;
        
        tables.table = cast(T*) GC.malloc(T.sizeof * 2 * (1 << log2n));
        
        int n_reversed_loops = log2n >= Options.large_limit ? 
            0 : log2(vec_size);
        
        fft_table_impl(log2n, n_reversed_loops, 
            cast(Tuple!(T,T) *)(tables.table + 2));
        
        if(log2n < 4)
        {
            tables.brTable = null;
        }
        else if(log2n < Options.large_limit)
        {
            tables.brTable = cast(uint*) 
                GC.malloc(uint.sizeof * BR.br_table_size(log2n));
            BR.init_br_table(tables.brTable, log2n);
        }
        else
        {
            enum log2size = 2*Options.log2_bitreverse_large_chunk_size;
            tables.brTable = cast(uint*) 
                GC.malloc(uint.sizeof * BR.br_table_size(log2size));
            BR.init_br_table(tables.brTable, log2size);
        }
        
        return tables;
    }
    
    void fft_passes_bit_reversed(vec* re, vec* im, size_t N , 
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
    
    void first_fft_passes(vec* pr, vec* pi, size_t n)
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

            pr[i2] = ar2 + ai3;     // needed to swap add and sub in these four lines
            pr[i3] = ar2 - ai3;
            pi[i2] = ai2 - ar3;
            pi[i3] = ai2 + ar3;      
        }
    }
    
    void fft_pass(vec *pr, vec *pi, vec *pend, T *table, const size_t m2)
    {
        size_t m = m2 + m2;
        for(; pr < pend ;
          pr += m, pi += m)
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
    
    void fft_passes(vec* re, vec* im, size_t N , T* table)
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
            
        for (; m2 > 0 ; m2 >>= 1)
        {
            fft_pass(re, im, pend, table, m2);
            table += tableRowLen;
            tableRowLen += tableRowLen;
        }
    }
    
    void nextTableRow(ref T*  table, ref size_t tableRowLen, ref size_t tableI)
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
    
    static void fft_passes_fractional(vec * pr, vec * pi, vec * pend, 
        T * table, size_t tableI, size_t tableRowLen)
    {
        static if(is(typeof(V.interleave!2)))
        {
            foreach(i; ints_up_to!(log2(vec_size)))
            {
                fft_pass_interleaved!(1 << (1 + i))(pr, pi, pend, table + tableI);
                nextTableRow(table, tableRowLen, tableI);
            }
        }
        else
            for (size_t m2 = vec_size >> 1; m2 > 0 ; m2 >>= 1)
            {
                FFT!(Scalar!T, Options).fft_pass(
                    cast(T*) pr, cast(T*) pi, cast(T*)pend, table + tableI, m2);
                nextTableRow(table, tableRowLen, tableI);  
            }
    }
    
    void fft_passes_strided(int l, int chunk_size)(
        vec * pr, vec * pi, size_t N , 
        ref T * table, ref size_t tableI, ref size_t tableRowLen, 
        size_t stride, int nPasses)
    {
        ubyte[aligned_size!vec(l * chunk_size, 64)] rmem = void;
        ubyte[aligned_size!vec(l * chunk_size, 64)] imem = void;
        
        auto rbuffer = aligned_ptr!vec(rmem.ptr, 64);
        auto ibuffer = aligned_ptr!vec(imem.ptr, 64);
      
        for(vec* pp = pr, pb = rbuffer; pp < pr + N; pb += chunk_size, pp += stride)
            BR.copy_some!(chunk_size)(pb, pp);
        for(vec* pp = pi, pb = ibuffer; pp < pi + N; pb += chunk_size, pp += stride)
            BR.copy_some!(chunk_size)(pb, pp);
        
        size_t m2 = l*chunk_size/2;
        size_t m2_limit = m2>>nPasses;

        if(tableRowLen == 2 && nPasses >= 2)
        {
            first_fft_passes(rbuffer, ibuffer, l*chunk_size);
            m2 >>= 1;
            nextTableRow(table, tableRowLen, tableI);
            m2 >>= 1;
            nextTableRow(table, tableRowLen, tableI);
        }
        
        for(; m2 > m2_limit; m2 >>= 1)
        {
            fft_pass(rbuffer, ibuffer, rbuffer + l*chunk_size, table + tableI, m2);
            nextTableRow(table, tableRowLen, tableI);  
        }
      
        for(vec* pp = pr, pb = rbuffer; pp < pr + N; pb += chunk_size, pp += stride)
            BR.copy_some!(chunk_size)(pp, pb);
        for(vec* pp = pi, pb = ibuffer; pp < pi + N; pb += chunk_size, pp += stride)
            BR.copy_some!(chunk_size)(pp, pb);
    }
    
    void fft_passes_recursive(
        vec * pr, vec *  pi, size_t N , 
        T * table, size_t tableI, size_t tableRowLen)
    {
        if(N <= (1<<Options.log2_optimal_n))
        {
            for (size_t m2 = N >> 1; m2 > 0 ; m2 >>= 1)
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
        size_t m = 1L<<log2m;
        
        T *  tableOld = table;
        size_t tableIOld = tableI;
        size_t tableRowLenOld = tableRowLen;

        for(size_t i=0; i < m; i += chunk_size)
        {
            table = tableOld;
            tableI = tableIOld;
            tableRowLen = tableRowLenOld;

            fft_passes_strided!(l, chunk_size)(pr + i, pi + i, N, table, 
                tableI, tableRowLen, m, nPasses);
        }

        {
            ulong nextN = (N>>nPasses);
            
            if(tableRowLen == 2 << nPasses)
                foreach(i; taskPool.parallel(std.range.iota(1<<nPasses)))
                    fft_passes_recursive(pr + nextN*i, pi  + nextN*i, 
                        nextN, table, tableI + 2*i, tableRowLen);
            else
                foreach(i; 0 .. (1<<nPasses))
                    fft_passes_recursive(pr + nextN*i, pi  + nextN*i, 
                        nextN, table, tableI + 2*i, tableRowLen);
        }
    }
    
    void fft_small(T * re, T * im, int log2n, Tables tables)
    {
        assert(log2n >= 2*log2(vec_size));
        
        size_t N = (1<<log2n);
        auto re_vec = cast(vec*) re;
        auto im_vec = cast(vec*) im;
        fft_passes(re_vec, im_vec, N / vec_size, tables.table + 2);
        
        static if(2*log2(vec_size) < 4)
        {
            if(log2n < 4)
            {
                bit_reverse_step!1(re, 1 << log2n);                     // only works for log2n < 4
                bit_reverse_step!1(im, 1 << log2n); 
            }
            else
            {
                BR.bit_reverse_small(re, log2n, tables.brTable); 
                BR.bit_reverse_small(im, log2n, tables.brTable);
            }
        }
        else                                                            //we already know that log2n >= 4 here.
        {
            BR.bit_reverse_small(re, log2n, tables.brTable); 
            BR.bit_reverse_small(im, log2n, tables.brTable);
        }
        fft_passes_bit_reversed( re_vec, im_vec , N / vec_size, cast(vec*) tables.table, N/vec_size/vec_size); 
    }
    
    void fft_large(T * re, T * im, int log2n, Tables tables)
    {
        size_t N = (1<<log2n);
        auto re_vec = cast(vec*) re;
        auto im_vec = cast(vec*) im;
        
        fft_passes_recursive(re_vec, im_vec, N / vec_size, tables.table + 2, 0, 2);
        
        BR.bit_reverse_large(re, log2n, tables.brTable); 
        BR.bit_reverse_large(im, log2n, tables.brTable);
    }
    
    void fft(T * re, T * im, int log2n, Tables tables)
    {
        if(log2n < 2*log2(vec_size))
            return FFT!(Scalar!T, Options).fft_small(re, im, log2n, tables);
        else if( log2n < Options.large_limit)
            return fft_small(re, im, log2n, tables);
        else 
            return fft_large(re, im, log2n, tables);
    }
}
