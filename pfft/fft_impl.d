//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.fft_impl;

import core.sys.posix.stdlib;
import pfft.bitreverse;

size_t _one(){ return cast(size_t) 1; }

enum one = _one();

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

version(Android)
{
    extern (C) void *memalign(size_t boundary, size_t size);
}

auto aligned_alloc(T)(size_t n, size_t alignment)
{
    version(Android)
    {
        return cast(T*) memalign(alignment, n * T.sizeof);
    }
    else
    {
        T * r;
        posix_memalign(cast(void**)&r, alignment, n * T.sizeof);
        return r;
    }
}

auto aligned_array(T)(size_t n, size_t alignment)
{
    return aligned_alloc!T(n, alignment)[0 .. n];
}

template FFT(alias V, Options)
{
    import core.bitop, core.stdc.math, core.stdc.stdlib;
    import pfft.bitreverse;
    
    alias BitReverse!(V, Options) BR;
    
    alias V.vec_size vec_size;
    alias V.T T;
    alias V.vec vec;
    
    alias T[2] Pair;
    
    void complex_array_to_vector()(Pair * pairs, size_t n)
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

    int log2()(int a)
    {
        int r = 0;
        while(a)
        {
            a >>= 1;
            r++;
        }
        return r - 1;
    }
    
    void fft_table_sines_cosines_fast()(int log2n,  Pair * r)
    {
        auto p0 = r;
        auto p1 = p0 + 1;
        auto p1end = p0 + (1<<log2n) - 1;
        
        real dphi = - asin(1.0);
        
        (*p0)[0] = 1;
        (*p0)[1] = 0;
        while(p1 < p1end)
        {
            T cdphi = cos(dphi);
            T sdphi = sin(dphi);
            dphi *= cast(T)0.5;
                        
            auto p0end = p1;
            while(p0 < p0end)
            {
                auto c = (*p0)[0];
                auto s = (*p0)[1];
                p0++;
                (*p1)[0] = c;
                (*p1)[1] = s;
                p1++;
                (*p1)[0] = c * cdphi - s * sdphi;   
                (*p1)[1] = c * sdphi + s * cdphi;
                p1++;
            }
        }
    }
    
    void fft_table_sines_cosines()(int log2n,  Pair * r)
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
            p += m/2;
        }
    }
    
    void fft_table_impl()(int log2n, Pair * r)
    {
        static if(is(typeof(Options.fast_init)))
            fft_table_sines_cosines_fast(log2n, r);
        else 
            fft_table_sines_cosines(log2n, r);
                
        int n_reversed_loops = 
            log2n >= Options.large_limit ? 0 : log2(vec_size);
                
        auto p = r;
        for (int s = 0; s < log2n; ++s)
        {
            size_t m = 1 << (s + 1);
            
            if(s < log2n - n_reversed_loops)
                bit_reverse_simple(p, s);
            else
                complex_array_to_vector(p, m/2);
            
            p += m/2;
        }
        
        p = r;
        
        int start_s = log2n < Options.large_limit ? 0 : 
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
                
                p[i] = a1;
                p[m / 2 + 2 * i] = a2;
                p[m / 2 + 2 * i + 1] = a3;
            }
            
            p += m / 2 + m;
        }
    }
    
    alias _FFTTables!T Table;
    
    size_t table_size_bytes()(int log2n)
    {
        return ((2 * T.sizeof) << log2n) + BR.br_table_size(log2n) * uint.sizeof;
    }
    
    Table fft_table()(int log2n, void * p = null)
    {
        if(log2n < 2*log2(vec_size))
            return FFT!(Scalar!T, Options).fft_table(log2n, p);
        
        if(p == null)
            p = cast(void*)aligned_alloc!byte(table_size_bytes(log2n), 64);
        
        Table tables;
        
        tables.table = cast(T*) p;
        
        fft_table_impl(log2n, cast(Pair *)(tables.table + 2));
        
        if(log2n < 4)
        {
            tables.brTable = null;
        }
        else if(log2n < Options.large_limit)
        {
            tables.brTable = cast(uint*)(p + ((2 * T.sizeof) << log2n));
            BR.init_br_table(tables.brTable, log2n);
        }
        else
        {
            enum log2size = 2*Options.log2_bitreverse_large_chunk_size;
            tables.brTable = aligned_alloc!uint(BR.br_table_size(log2size), 64);
            BR.init_br_table(tables.brTable, log2size);
        }
        
        return tables;
    }
    
    void fft_passes_bit_reversed()(vec* re, vec* im, size_t N , 
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
    
    void first_fft_passes()(vec* pr, vec* pi, size_t n)
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

            pr[i0] = ar0 + ar1;import core.bitop, core.stdc.math, core.stdc.stdlib, core.sys.posix.stdlib;
            pr[i1] = ar0 - ar1;
            pi[i0] = ai0 + ai1;
            pi[i1] = ai0 - ai1;

            pr[i2] = ar2 + ai3;
            pr[i3] = ar2 - ai3;
            pi[i2] = ai2 - ar3;
            pi[i3] = ai2 + ar3;      
        }
    }
        
    void fft_pass()(vec *pr, vec *pi, vec *pend, T *table, const size_t m2)
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
    
    void fft_two_passes()(vec *pr, vec *pi, vec *pend, 
                          T *table0, T *table1,  size_t m2)
    {
        size_t m = m2 + m2;
        size_t m4 = m2 / 2;
        for(; pr < pend ; pr += m, pi += m)
        {
            vec w1r = V.scalar_to_vector(table0[0]);
            vec w1i = V.scalar_to_vector(table0[1]);
            
            vec w2r = V.scalar_to_vector(table1[0]);
            vec w2i = V.scalar_to_vector(table1[1]);
            
            vec w3r = V.scalar_to_vector(table1[2]);
            vec w3i = V.scalar_to_vector(table1[3]);
            
            table0 += 2;
            table1 += 4;
            
            for (size_t k0 = 0, k1 = m4, k2 = m2, k3 = m2 + m4; k0<m4; k0++, k1++, k2++, k3++) 
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
    
    void fft_passes()(vec* re, vec* im, size_t N , T* table)
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
            auto next_table = table + tableRowLen;
            fft_two_passes(re, im, pend, table, next_table, m2);
            table = next_table;
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
    
    void nextTableRow()(ref T*  table, ref size_t tableRowLen, ref size_t tableI)
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
    
    static void fft_passes_fractional()(vec * pr, vec * pi, vec * pend, 
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
            BR.copy_array(pb, pp, chunk_size);
        for(vec* pp = pi, pb = ibuffer; pp < pi + N; pb += chunk_size, pp += stride)
            BR.copy_array(pb, pp, chunk_size);
        
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
            BR.copy_array(pp, pb, chunk_size);
        for(vec* pp = pi, pb = ibuffer; pp < pi + N; pb += chunk_size, pp += stride)
            BR.copy_array(pp, pb, chunk_size);
    }
    
    void fft_passes_recursive()(
        vec * pr, vec *  pi, size_t N , 
        T * table, size_t tableI, size_t tableRowLen)
    {
        if(N == (1<<Options.log2_optimal_n))
        {
            size_t m2 = N >> 1;
            for (; m2 > 1 ; m2 >>= 2)
            {
                auto tmp = table + tableI;
                nextTableRow(table, tableRowLen, tableI); 
                fft_two_passes(pr, pi, pr + N, tmp, table + tableI, m2);
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
        size_t m = one << log2m;
        
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
            size_t nextN = (N>>nPasses);

            for(int i = 0; i<(1<<nPasses); i++)
                fft_passes_recursive(pr + nextN*i, pi  + nextN*i, 
                    nextN, table, tableI + 2*i, tableRowLen);
        }
    }
    
    void fft_small()(T * re, T * im, int log2n, Table tables)
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
    
    void fft_large()(T * re, T * im, int log2n, Table tables)
    {
        size_t N = (1<<log2n);
        auto re_vec = cast(vec*) re;
        auto im_vec = cast(vec*) im;
        
        fft_passes_recursive(re_vec, im_vec, N / vec_size, tables.table + 2, 0, 2);
        
        BR.bit_reverse_large(re, log2n, tables.brTable); 
        BR.bit_reverse_large(im, log2n, tables.brTable);
    }
    
    void fft()(T * re, T * im, int log2n, Table tables)
    {
        if(log2n < 2*log2(vec_size))
            return FFT!(Scalar!T, Options).fft_small(re, im, log2n, tables);
        else if( log2n < Options.large_limit)
            return fft_small(re, im, log2n, tables);
        else 
            return fft_large(re, im, log2n, tables);
    }
    
    void interleaveArray()(T* even, T* odd, T* interleaved, size_t n)
    {
        static if(is(typeof(V.interleave!vec_size)))
        {
            foreach(i; 0 .. n / vec_size)
            {
                V.interleave!vec_size(
                    (cast(vec*)even)[i], 
                    (cast(vec*)odd)[i], 
                    (cast(vec*)interleaved)[i * 2], 
                    (cast(vec*)interleaved)[i * 2 + 1]);
            }
        }
        else
        {
            foreach(i; 0 .. n)
            {
                interleaved[i * 2] = even[i];
                interleaved[i * 2 + 1] = odd[i];
            }
        }
    }
    
    void deinterleaveArray()(T* even, T* odd, T* interleaved, size_t n)
    {
        static if(is(typeof(V.deinterleave!vec_size)))
        {
            foreach(i; 0 .. n / vec_size)
            {
                V.deinterleave!vec_size(
                    (cast(vec*)interleaved)[i * 2], 
                    (cast(vec*)interleaved)[i * 2 + 1], 
                    (cast(vec*)even)[i], 
                    (cast(vec*)odd)[i]);
            }
        }
        else
        {
            foreach(i; 0 .. n)
            {
                even[i] = interleaved[i * 2];
                odd[i] = interleaved[i * 2 + 1];
            }
        }
    }
    
    bool isAligned(T* p)
    {
        return ((cast(size_t)p) & (vec.sizeof - 1)) == 0;
    }
}

template Instantiate(alias F)
{	
	alias F.fft!() fft;
	alias F.fft_table!() fft_table;
	alias F.table_size_bytes!() table_size_bytes;
	alias F.interleaveArray!() interleaveArray;
	alias F.deinterleaveArray!() deinterleaveArray;
	alias F.isAligned isAligned;

	alias F.T T;
	alias F.vec vec;
	alias F.Table Table;
	
	enum vec_size = F.vec_size;
}

