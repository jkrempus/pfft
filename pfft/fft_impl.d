//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.fft_impl;

public import pfft.shuffle;

enum Action
{ 
    passes_first, 
    passes, 
    passes_last, 
    bit_reverse, 
    br_passes,
    fract_passes,
    strided_copy1,
    strided_copy2
}

import pfft.profile;
mixin ProfileMixin!Action;

version(DontUseTwoPasses)
    enum useTwoPasses = false;
else
    enum useTwoPasses = true;

version(Windows)
    enum isWin64 = size_t.sizeof == 8;
else
    enum isWin64 = false;

version(GNU)
    version(Windows)
        version = MinGW_;  

template Scalar(_T, A...)
{
    enum{ isScalar }
    alias _T vec;
    alias _T T;
    alias _T Twiddle;

    enum vec_size = 1;
    enum log2_bitreverse_chunk_size = 1;
    
    vec twiddle_to_vector(T a) { return a; }
   
    void bit_reverse(A...)(ref A arg)
    {
        swap(arg[1], arg[2]);
    }

    T unaligned_load(T* p){ return *p; }
    void unaligned_store(T* p, T a){ *p = a; }
    T reverse(T a){ return a; }           
}

template MultiScalar(alias Vector)
{
    enum{ isScalar }
    alias Vector.vec vec;
    alias Vector.vec T;
    alias Vector.Twiddle Twiddle;

    enum vec_size = 1;
    enum log2_bitreverse_chunk_size = 1;

    vec twiddle_to_vector(Twiddle a)
    {
        return Vector.twiddle_to_vector(a);;
    }

    void bit_reverse(A...)(ref A arg)
    {
        swap(arg[1], arg[2]);
    }
    
    T unaligned_load(T* p){ return *p; }
    void unaligned_store(T* p, T a){ *p = a; }
    vec reverse(T a){ return a; }           
}

template MultiScalarOptions(alias Options, int multi)
{
    enum dl = (log2(multi) + 1) / 2;
    enum log2_bitreverse_large_chunk_size = Options.log2_bitreverse_large_chunk_size - dl;
    enum large_limit = Options.large_limit - log2(multi);
    enum log2_optimal_n = Options.log2_optimal_n;
    enum passes_per_recursive_call = Options.passes_per_recursive_call;
    enum log2_recursive_passes_chunk_size = Options.log2_recursive_passes_chunk_size;
} 

template FFT(alias V, alias Options, bool disable_large = false)
{
    static assert(!(Options.passes_per_recursive_call & 1));

    import core.bitop, core.stdc.stdlib;
   
    alias BitReverse!(V, Options) BR;
    alias Columns!(V) Col;
    
    alias V.vec_size vec_size;
    alias V.T T;
    alias V.vec vec;
    alias V.Twiddle Twiddle;

    enum isScalar = is(typeof(V.isScalar));
    static if(!isScalar)
        alias FFT!(Scalar!(T, V), Options) SFFT;
    else
        alias FFT!(V, Options, disable_large) SFFT;
 
    static if(!isScalar)
        alias FFT!(MultiScalar!(V), MultiScalarOptions!(Options, vec_size)) MSFFT;
    else
        alias FFT!(V, Options, disable_large) MSFFT;

    alias 
        SelectImplementation!(FFT!(V, Options, disable_large), MSFFT).call
        multi; 

    enum static_size_limit = 
        2 * max(log2(vec_size), V.log2_bitreverse_chunk_size);

    import cmath = core.stdc.math;

    static if(is(Twiddle == float))
    {
        alias cmath.sinf _sin;
        alias cmath.cosf _cos;
        alias cmath.asinf _asin;
    }
    else static if(is(Twiddle == double) || isWin64)
    {
        alias cmath.sin _sin;
        alias cmath.cos _cos;
        alias cmath.asin _asin;
    }
    else static if(is(Twiddle == real))
    {
        alias cmath.sinl _sin;
        alias cmath.cosl _cos;
        alias cmath.asinl _asin;
    }
    else
        static assert(0);

    auto v()(T* p){ return cast(vec*) p; }

    vec load_twiddle_vector()(Twiddle *p)
    {
        static if(is(vec == T))
            return V.twiddle_to_vector(*p);
        else
            return *cast(vec*)(p);
    }
    
    alias Tuple!(Twiddle, Twiddle) Pair;
   
    void complex_array_to_vector()(Pair * pairs, size_t n)
    {
        for(size_t i=0; i<n; i += vec_size)
        {
            Twiddle buffer[vec_size*2] = void;
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

    int n_bit_reversed_passes(int log2n)
    {
        enum log2vs = log2(vec_size);
        // assert(log2n >= 2 * log2vs);
        
        return ((log2n > 2 * log2vs) && ((log2vs & 1) & ~(log2n & 1))) ?
            log2vs + 1 : log2vs;
    }
 
    void sines_cosines_refine(bool computeEven)(
        Pair* src, Pair* dest, size_t n_from, Twiddle dphi)
    {
        Twiddle cdphi = _cos(dphi);
        Twiddle sdphi = _sin(dphi);
       
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

    void sines_cosines(bool phi0_is_last)(
        Pair* r, size_t n, Twiddle phi0, Twiddle deltaphi, bool bit_reversed)
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

    void twiddle_table()(int log2n, Pair * r)
    {
        if(log2n >= Options.large_limit || log2n < static_size_limit)
        {
            return sines_cosines!false(
                r, st!1 << (log2n - 1), 0.0, -2 * _asin(1), true);
        }

        for (int s = 0; s < log2n; ++s)
        {
            size_t m2 = 1 << s;
            auto p = r + m2;
            
            if(s < log2n - n_bit_reversed_passes(log2n))
                sines_cosines!false(p, m2, 0.0, -2 * _asin(1), true);
            else
            {
                sines_cosines!false(p, m2, 0.0, -2 * _asin(1), false);
                complex_array_to_vector(p, m2);
            }
        }

        static if(useTwoPasses)
        {
            for (int s = 0; s + 1 < log2n - n_bit_reversed_passes(log2n);  s += 2)
            {
                size_t m2 = 1 << s;
                auto p = r + m2;

                foreach(i; 0 .. m2)
                    // p[i] is p[m2 + 2 * i] ^^ 2. We store it here so that we 
                    // don't need to recompute it below, which improves precision 
                    // slightly.
                    p[m2 + 2 * i + 1] = p[i]; 

                foreach(i; 0 .. m2)
                {
                    Pair a1 = p[m2 + 2 * i];
                    Pair a2 = p[m2 + 2 * i + 1];
                    Pair a3;
                    
                    a3[0] = a2[0] * a1[0] - a2[1] * a1[1];
                    a3[1] = a2[0] * a1[1] + a2[1] * a1[0];
                    
                    p[3 * i] = a1;
                    p[3 * i + 1] = a2;
                    p[3 * i + 2] = a3;
                }
            }

            for(
                int s = log2n - n_bit_reversed_passes(log2n); 
                s + 1 < log2n; 
                s += 2)
            {
                alias Tuple!(vec, vec) VPair;

                size_t m2 = (st!1 << s) / vec_size;
                auto vp = (cast(VPair*) r) + m2;

                foreach(i; 0 .. m2)
                    // move those elements so that we don't overwrite them
                    vp[m2 + m2 + i] = vp[m2 + i];

                foreach(i; 0 .. m2)
                {
                    VPair a1 = vp[m2 + m2 + i];
                    VPair a2, a3;

                    a2[0] = a1[0] * a1[0] - a1[1] * a1[1];
                    a2[1] = a1[0] * a1[1] + a1[1] * a1[0];
                    a3[0] = a2[0] * a1[0] - a2[1] * a1[1];
                    a3[1] = a2[0] * a1[1] + a2[1] * a1[0];

                    vp[3 * i] = a1;
                    vp[3 * i + 1] = a2;
                    vp[3 * i + 2] = a3;
                }
            }
        }
    }

    struct TableValue
    {
        Twiddle* twiddle;
        void* buffer; 
        uint* br;
        uint log2n;
    }

    alias TableValue* Table;
    alias void* TransposeBuffer;
    
    size_t twiddle_table_size()(int log2n)
    {
        auto compact = log2n >= Options.large_limit || 
            log2n < 2 * log2(vec_size);

        return st!2 << (compact ? log2n - 1 : log2n); 
    }
 
    size_t tmp_buffer_size()(int log2n)
    {
        enum rec = vec.sizeof << (
            Options.log2_recursive_passes_chunk_size + 
            Options.passes_per_recursive_call + 1);

        auto br = BR.tmp_buffer_size(log2n) * T.sizeof;

        return 
            disable_large || log2n < Options.large_limit ? 0 :
            rec > br ? rec : 
            br;
    }
 
    uint br_table_log2n()(uint log2n)
    {
        return disable_large || log2n < Options.large_limit ? 
            log2n : 2 * Options.log2_bitreverse_large_chunk_size;
    }

    void fft_table_add_pointers(
        Table table, Table* table_ptr, Allocate!4* alloc, uint log2n)
    {
        alloc.add(&table.twiddle, twiddle_table_size(log2n));
        alloc.add(&table.buffer, tmp_buffer_size(log2n));
        alloc.add(&table.br, BR.table_size(br_table_log2n(log2n)));
        alloc.add(table_ptr, 1);
    }

    size_t fft_table_size()(uint log2n)
    {
        Allocate!4 alloc = void; alloc.initialize();
        TableValue tv;
        fft_table_add_pointers(&tv, null, &alloc, log2n);
        return alloc.size(); 
    }
  
    void init_fft_table(uint log2n, Table t)
    {
        t.log2n = log2n;
        if(log2n > 0)
        {
            twiddle_table(log2n, cast(Pair *) t.twiddle);

            if(log2n >= V.log2_bitreverse_chunk_size * 2)
                BR.init_table(br_table_log2n(log2n), t.br);
        }
    }

    Table fft_table()(uint log2n, void * p)
    {   
        Allocate!4 alloc = void; alloc.initialize();
        TableValue tv;
        Table t;
        fft_table_add_pointers(&tv, &t, &alloc, log2n);
        alloc.allocate(p);
        *t = tv;
        init_fft_table(log2n, t); 
        return t;
    }

    uint fft_table_log2n(Table table){ return table.log2n; }

    void* fft_table_memory(Table table){ return cast(void*) table.twiddle; }

    /*static void two_passes_inner(
        vec* pr, vec* pi, size_t k0, size_t k1, size_t k2, size_t k3,
        vec w1r, vec w1i, vec w2r, vec w2i, vec w3r, vec w3i)
    {*/

    enum two_passes_inner = q{
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
    };
 
    void fft_pass_bit_reversed()(
        vec* pr, vec* pi, vec* pend, vec* table, size_t m2)
    {
        size_t m = m2 + m2;
        for(; pr < pend; pr += m, pi += m)
        {
            for(size_t k1 = 0, k2 = m2; k1<m2; k1++, k2 ++) 
            {  
                vec wr = table[2 * k1], wi = table[2 * k1 + 1];                       

                vec tmpr = pr[k2], ti = pi[k2];
                vec ur = pr[k1], ui = pi[k1];
                vec tr = tmpr * wr - ti * wi;
                ti = tmpr * wi + ti * wr;
                pr[k2] = ur - tr;
                pr[k1] = ur + tr;                                                    
                pi[k2] = ui - ti;                                                    
                pi[k1] = ui + ti;
            }
        }
    }
 
    void fft_two_passes_bit_reversed()(
        vec* pr, vec* pi, vec* pend, vec* table, size_t m2)
    {
        size_t m = m2 + m2;
        size_t m4 = m2 / 2;

        for(; pr < pend ; pr += m, pi += m)
        {
            for (
                size_t k0 = 0, k2 = m4, k1 = m2, k3 = m2 + m4; 
                k0 < m4; 
                k0++, k1++, k2++, k3++) 
            {
                auto t = table + 6 * k0;
                auto 
                    w1r = t[0], w1i = t[1], 
                    w2r = t[2], w2i = t[3], 
                    w3r = t[4], w3i = t[5];
                mixin(two_passes_inner);
                // bit reversed order of indices!
                //two_passes_inner(
                    //pr, pi, k0, k2, k1, k3, t[0], t[1], t[2], t[3], t[4], t[5]);
            }
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
        
    void fft_pass()(
        vec *pr, vec *pi, vec *pend, Twiddle *table, size_t m2)
    {
        size_t m = m2 + m2;
        for(; pr < pend ; pr += m, pi += m)
        {
            vec wr = V.twiddle_to_vector(table[0]);
            vec wi = V.twiddle_to_vector(table[1]);
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

    void fft_two_passes(Tab...)(
        vec *pr, vec *pi, vec *pend, size_t m2, Tab tab)
    {
        // When this function is called with tab.length == 2 on DMD, it 
        // sometimes gives an incorrect result (for example when building with 
        // SSE on 64 bit Linux and runnitg test_float  pfft "14".), so lets's 
        // use fft_pass instead.
    
        version(DigitalMars)
            static if(tab.length == 2)
            {
               fft_pass(pr, pi, pend, tab[0], m2);
               fft_pass(pr, pi, pend, tab[1], m2 / 2);
               return;
            }

        size_t m = m2 + m2;
        size_t m4 = m2 / 2;
        for(; pr < pend ; pr += m, pi += m)
        {
            static if(tab.length == 2)
            {
                vec w1r = V.twiddle_to_vector(tab[1][0]);
                vec w1i = V.twiddle_to_vector(tab[1][1]);

                vec w2r = V.twiddle_to_vector(tab[0][0]);
                vec w2i = V.twiddle_to_vector(tab[0][1]);

                vec w3r = w1r * w2r - w1i * w2i;
                vec w3i = w1r * w2i + w1i * w2r;

                tab[0] += 2;
                tab[1] += 4;
            }
            else
            {
                vec w1r = V.twiddle_to_vector(tab[0][0]);
                vec w1i = V.twiddle_to_vector(tab[0][1]);

                vec w2r = V.twiddle_to_vector(tab[0][2]);
                vec w2i = V.twiddle_to_vector(tab[0][3]);

                vec w3r = V.twiddle_to_vector(tab[0][4]);
                vec w3i = V.twiddle_to_vector(tab[0][5]);

                tab[0] += 6;
            }

            for (
                size_t k0 = 0, k1 = m4, k2 = m2, k3 = m2 + m4; 
                k0 < m4; 
                k0++, k1++, k2++, k3++) 
            {
                /*two_passes_inner(
                    pr, pi, k0, k1, k2, k3, w1r, w1i, w2r, w2i, w3r, w3i);*/
                mixin(two_passes_inner);
            }
        }
    }

    void fft_passes_bit_reversed()(
        vec* re, vec* im, size_t N, vec* table, size_t start_stride)
    {
        //version(DigitalMars)
            // prevent inlining of this function to avoid stack alignment
            // bug with latest DMD 2.061 from git
            //asm{ nop; }

        table += start_stride + start_stride;
        vec* re_end = re + N;
        size_t m2 = start_stride;

        static if(useTwoPasses)
            for(; m2 < N / 2; m2 <<= 2)
            {
                fft_two_passes_bit_reversed(re, im, re_end, table, m2 * 2);
                table += 6 * m2;
            }

        for(; m2 < N; m2 <<= 1)
        {
            fft_pass_bit_reversed(re, im, re_end, table, m2);
            table += m2 + m2;
        }
    }
    
    void fft_passes(bool compact_table)(
        vec* re, vec* im, size_t N, size_t end_stride, Twiddle* table)
    {
        vec * pend = re + N;

        size_t tableRowLen = 2;
        size_t m2 = N/2;

        static nextRow(ref Twiddle* table, ref size_t len)
        {
            static if(!compact_table)
            {
                table += len;
                len += len;
            }
        }

        profStart(Action.passes_first);

        if(m2 >= end_stride * 2)
        {
            first_fft_passes(re, im, N);
            
            m2 >>= 2;

            nextRow(table, tableRowLen);
            nextRow(table, tableRowLen);
        }

        profStopStart(Action.passes_first, Action.passes);

        static if(useTwoPasses)
            for (; m2 >= end_stride * 2; m2 >>= 2)
            {
                static if(compact_table)
                    fft_two_passes(re, im, pend, m2, table, table);
                else
                    fft_two_passes(re, im, pend, m2, table);

                nextRow(table, tableRowLen);
                nextRow(table, tableRowLen);
            }

        profStopStart(Action.passes, Action.passes_last);

        for (; m2 >= end_stride; m2 >>= 1)
        {
            fft_pass(re, im, pend, table, m2);
            nextRow(table, tableRowLen);
        }

        profStop(Action.passes_last);
    }
  
    void fractional_inner(bool do_prefetch)(
        ref vec ar,
        ref vec ai,
        ref vec br,
        ref vec bi,
        Twiddle* table,
        size_t tableI)
    {
        foreach(i; ints_up_to!(log2(vec_size)))
        {
            vec wr, wi, ur, ui;

            static if(do_prefetch && i < log2(vec_size))
                prefetch!(true, false)(table + ((tableI + 4) << i));

            V.complex_array_to_real_imag_vec!(2 << i)(
                table + (tableI << i), wr, wi);

            V.transpose!(2 << i)(ar, br, ur, br);
            V.transpose!(2 << i)(ai, bi, ui, bi);

            auto tr = br * wr - bi * wi;
            auto ti = bi * wr + br * wi;

            ar = ur + tr;
            br = ur - tr;
            ai = ui + ti;
            bi = ui - ti;
        }  

        V.interleave(ar, br, ar, br); 
        V.interleave(ai, bi, ai, bi);
    }

    void fft_passes_fractional()(
        vec * pr, vec * pi, vec * pend, Twiddle * table, size_t tableI)
    {
        static if(is(typeof(V.transpose!2)))
        {
            for(; pr < pend; pr += 2, pi += 2, tableI += 4)
            {
                auto ar = pr[0];
                auto ai = pi[0];
                auto br = pr[1];
                auto bi = pi[1];
                
                fractional_inner!true(ar, ai, br, bi, table, tableI);
                            
                pr[0] = ar;
                pi[0] = ai;
                pr[1] = br;
                pi[1] = bi;
            }
        }
        else
            for (size_t m2 = vec_size >> 1; m2 > 0 ; m2 >>= 1)
            {
                SFFT.fft_pass(
                    cast(T*) pr, cast(T*) pi, cast(T*)pend, table + tableI, m2);
                
                tableI *= 2;
            }
    }

    void fft_passes_strided(int l, int chunk_size)(
        vec * pr,
        vec * pi, 
        size_t N , 
        ref Twiddle * table, 
        ref size_t tableI, 
        void* tmp_buffer,
        size_t stride,
        int nPasses)
    {
        auto rbuf = cast(vec*) tmp_buffer;
        auto ibuf = rbuf + l * chunk_size;

        profStart(Action.strided_copy1);
        foreach(i; 0 .. 2)
            BR.strided_copy!(chunk_size, true)(
                i ? ibuf : rbuf, i ? pi : pr, chunk_size, stride, l);

        profStopStart(Action.strided_copy1, Action.passes);

        size_t m2 = l*chunk_size/2;
        size_t m2_limit = m2>>nPasses;

        if(tableI  == 0 && nPasses >= 2)
        {
            first_fft_passes(rbuf, ibuf, l*chunk_size);
            m2 >>= 1;
            tableI *= 2;
            m2 >>= 1;
            tableI *= 2;
        }

        static if(useTwoPasses)
            for(; m2 > 2 * m2_limit; m2 >>= 2)
            {
                fft_two_passes(rbuf, ibuf, rbuf + l*chunk_size, m2, 
                    table + tableI, table + 2 * tableI);

                tableI *= 4;
            }
        else 
            for(; m2 > m2_limit; m2 >>= 1)
            {
                fft_pass(rbuf, ibuf, rbuf + l*chunk_size, table + tableI, m2);
                tableI *= 2;
            }
        
        profStopStart(Action.passes, Action.strided_copy2);
        foreach(i; 0 .. 2)
            BR.strided_copy!(chunk_size, false)(
                i ? pi : pr, i ? ibuf : rbuf, stride, chunk_size, l);

        profStop(Action.strided_copy2);
    }

    void fft_passes_recursive_last()(
        vec* pr, vec*  pi, size_t N, Twiddle* table, size_t tableI)
    {
        profStart(Action.passes_last);
        size_t m2 = N >> 1;
       
        static if(useTwoPasses)
            for (; m2 > 1 ; m2 >>= 2, tableI *= 4)
                fft_two_passes(pr, pi, pr + N, m2, table + tableI, 
                    table + 2 * tableI);

        for (; m2 > 0 ; m2 >>= 1, tableI *= 2)
            fft_pass(pr, pi, pr + N, table + tableI, m2);
       
        static if(!isScalar) 
            fft_passes_fractional(pr, pi, pr + N, table, tableI);

        profStop(Action.passes_last);
    }

    void fft_passes_recursive()(
        vec* pr,
        vec*  pi,
        size_t N,
        Twiddle* table,
        size_t tableI,
        void* tmp_buffer)
    {
        enum log2l =  Options.passes_per_recursive_call, l = 1 << log2l;
        enum chunk_size = st!1 << Options.log2_recursive_passes_chunk_size;

        int log2n = bsf(N);

        int nPasses = log2n > log2l + Options.log2_optimal_n ?
            log2l : log2n - Options.log2_optimal_n;

        nPasses = (nPasses & 1) ? nPasses + 1 : nPasses;

        int log2m = log2n - log2l;
        size_t m = st!1 << log2m;
        
        size_t tableIOld = tableI;

        for(size_t i=0; i < m; i += chunk_size)
        {
            tableI = tableIOld;

            fft_passes_strided!(l, chunk_size)(
                pr + i, pi + i, N, table, tableI, tmp_buffer, m, nPasses);
        }

        size_t nextN = N >> nPasses;

        for(int i = 0; i < (1 << nPasses); i++)
            if(nextN > (1<<Options.log2_optimal_n))
                fft_passes_recursive(
                    pr + nextN * i, pi  + nextN * i, nextN, 
                    table, tableI + 2 * i, tmp_buffer);
            else
                fft_passes_recursive_last(
                    pr + nextN * i, pi  + nextN * i, nextN, 
                    table, tableI + 2 * i);

    }

    void static_size_fft(int log2n_elem)(vec* pr, vec* pi, Twiddle* table)
    {
        enum log2n = log2n_elem - log2(vec_size);  
        enum n = 1 << log2n;
        RepeatType!(vec, n) ar, ai;

        foreach(i; ints_up_to!n)
        {
            ar[i] = pr[i];
            ai[i] = pi[i];
        }
       
        foreach(i; powers_up_to!n)
        {
            enum m = n / i;

            foreach(j; ints_up_to!(n / m))
            {
                enum offset = m * j;
                static if (j >= 2)
                {
                    vec wr = table[2 * j];
                    vec wi = table[2 * j + 1];
                }

                foreach(k1; ints_up_to!(m / 2))
                {
                    enum k2 = k1 + m / 2;
                    static if(j == 0)
                    {
                        vec tr = ar[offset + k2], ti = ai[offset + k2];
                        vec ur = ar[offset + k1], ui = ai[offset + k1];
                    }
                    else static if(j == 1)
                    {
                        vec tr = ai[offset + k2], ti = -ar[offset + k2];
                        vec ur = ar[offset + k1], ui = ai[offset + k1];
                    }
                    else
                    {
                        vec tmpr = ar[offset + k2], ti = ai[offset + k2];
                        vec ur = ar[offset + k1], ui = ai[offset + k1];
                        vec tr = tmpr*wr - ti*wi;
                        ti = tmpr*wi + ti*wr;
                    }
                    ar[offset + k2] = ur - tr;
                    ar[offset + k1] = ur + tr;
                    ai[offset + k2] = ui - ti;
                    ai[offset + k1] = ui + ti;
                }
            }
        }

        static if(!isScalar)
        {
            foreach(i; ints_up_to!(0, n, 2))
                fractional_inner!false(
                    ar[i], ai[i], ar[i + 1], ai[i + 1], table, i * 2);
        
            enum fastBR = is(typeof(BR.bit_reverse_static_size(ar)));
            static if(fastBR)
            {
                BR.bit_reverse_static_size(ar);
                BR.bit_reverse_static_size(ai);
            }

            foreach(i; ints_up_to!(n))
            {
                pr[i] = ar[i];
                pi[i] = ai[i];
            }

            static if(!fastBR)
                foreach(j; 0 .. 2)            
                {
                    auto sp = cast(T*) (j == 0 ? pr : pi);
                    RepeatType!(T, n * vec_size) s;
                    
                    foreach(i; ints_up_to!(n * vec_size))
                        s[i] = sp[i];
                    foreach(i; ints_up_to!(n * vec_size))
                        sp[i] = s[reverse_bits!(i, log2n_elem)];
                }
        }
        else
            foreach(i; ints_up_to!n)
            {
                pr[i] = ar[reverse_bits!(i, log2n)];
                pi[i] = ai[reverse_bits!(i, log2n)];
            }
    }

    void fft_small()(T * re, T * im, uint log2n, Table table)
    {
        // assert(log2n >= 2*log2(vec_size));

        size_t N = (1<<log2n);
        size_t n_br = n_bit_reversed_passes(log2n);       
 
        fft_passes!false(
            v(re), v(im), N / vec_size, 
            1 << (n_br - log2(vec_size)),
            table.twiddle + 2);

        profStart(Action.bit_reverse);
 
        foreach(i; 0 .. 2)
            BR.bit_reverse_small(i ? im : re, log2n, table.br); 

        profStopStart(Action.bit_reverse, Action.br_passes);

        static if(vec_size > 1) 
            fft_passes_bit_reversed(
                v(re), v(im) , N / vec_size, 
                cast(vec*) table.twiddle, 
                (N / vec_size) >> n_br);

        profStop(Action.br_passes);
    }

    void fft_large()(T * re, T * im, uint log2n, Table table)
    {
        size_t N = (1<<log2n);
 
        fft_passes_recursive(
            v(re), v(im), N / vec_size, table.twiddle, 0, table.buffer);

        profStart(Action.bit_reverse);
        BR.bit_reverse_large(re, log2n, table.br, table.buffer); 
        BR.bit_reverse_large(im, log2n, table.br, table.buffer); 
        
        profStop(Action.bit_reverse);
    }

    void fft()(T * re, T * im, Table table)
    {
        uint log2n = table.log2n;
        switch(log2n)
        {
            case 0: return;

            foreach(i; ints_up_to!(1, log2(vec_size) + 1, 1))
	    {
                case i: return SFFT.static_size_fft!i(re, im, table.twiddle);
	    }

            foreach(i; ints_up_to!(log2(vec_size) + 1, static_size_limit, 1))
	    {
                case i: return static_size_fft!i(
                    cast(vec*) re, cast(vec*) im, table.twiddle);
	    }
            
            default:
        }

        if( log2n < Options.large_limit || disable_large)
            return fft_small(re, im, log2n, table);
        else 
            static if(!disable_large)
                fft_large(re, im, log2n, table);
    }

    size_t log2_multi()()
    {
        return log2(T.sizeof / Twiddle.sizeof);
    }

    alias Twiddle* RTable;
 
    auto rtable_size()(int log2n)
    {
        return T.sizeof << (log2n - 1);
    }

    enum supports_real = is(typeof(
    {
        T a;
        vec v = V.unaligned_load(&a);
        v = V.reverse(v);
        V.unaligned_store(&a, v);
    }));

    RTable rfft_table()(int log2n, void *p) if(supports_real)
    {
        if(log2n < 2)
            return cast(RTable) p;
        else if(st!1 << log2n < 4 * vec_size)
        {
            static if(!isScalar)
                return SFFT.rfft_table(log2n, p);
        }

        auto r = (cast(Pair*) p)[0 .. (st!1 << (log2n - 2))];

        auto phi = _asin(1);
        sines_cosines!true(r.ptr, r.length, -phi, phi, false);

        complex_array_to_vector(r.ptr, r.length);

        return cast(RTable) r.ptr;
    }

    auto rfft_table()(int log2n, void *p) if(!supports_real)
    {
        return SFFT.rfft_table(log2n, p);
    }

    void rfft()(T* rr, T* ri, Table table, RTable rtable) 
    {
        auto log2n = table.log2n + 1;
        if(log2n == 0)
            return;
        else if(log2n == 1)
        {
            auto rr0 = rr[0], ri0 = ri[0];
            rr[0] = rr0 + ri0;
            ri[0] = rr0 - ri0;
            return;
        }

        fft(rr, ri, table);
        rfft_last_pass!false(rr, ri, log2n, rtable);
    }

    void irfft()(
        T* rr, T* ri, Table table, RTable rtable) 
    {
        auto log2n = table.log2n + 1;
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
        fft(ri, rr, table);
    }

    void rfft_last_pass(bool inverse)(T* rr, T* ri, int log2n, RTable rtable) 
    if(supports_real)
    {
        static if(!isScalar)
            if(st!1 << log2n < 4 * vec_size)
                return SFFT.rfft_last_pass!inverse(rr, ri, log2n, rtable);       
 
        static vec* v(T* a){ return cast(vec*) a; }

        auto n = st!1 << log2n;

        vec half = V.twiddle_to_vector(cast(Twiddle) 0.5);

        T middle_r = rr[n / 4];        
        T middle_i = ri[n / 4];        

        for(
            size_t i0 = 1, i1 = n / 2 - vec_size, iw = 0; 
            i0 <= i1; 
            i0 += vec_size, i1 -= vec_size, iw += 2*vec_size)
        {
            vec wr = load_twiddle_vector(rtable + iw);
            vec wi = load_twiddle_vector(rtable + iw + vec_size);

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
    
    void rfft_last_pass(bool inverse)(T* rr, T* ri, int log2n, RTable rtable) 
    if(!supports_real)
    {
        SFFT.rfft_last_pass!inverse(rr, ri, log2n, rtable); 
    }

    alias bool* ITable;
  
    version(MinGW)
        enum interleaveChunkSize = 4;
    else
        enum interleaveChunkSize = 8;

    alias Interleave!(V, interleaveChunkSize, false).itable_size itable_size;
    alias Interleave!(V, interleaveChunkSize, false).interleave_table interleave_table;
    alias Interleave!(V, interleaveChunkSize, false).interleave interleave;
    alias Interleave!(V, interleaveChunkSize, true).interleave deinterleave;

    alias Interleave!(V, interleaveChunkSize, false, true).interleave interleave_swap;
    alias Interleave!(V, interleaveChunkSize, true, true).interleave deinterleave_swap;
  
    alias Interleave!(V, interleaveChunkSize, false).interleaved_copy interleave_array;
    alias Interleave!(V, interleaveChunkSize, true).interleaved_copy deinterleave_array;

    struct MultidimTableValue
    {
        TableValue[] tables;
        TransposeBuffer buffer;
        void* memory;
    }

    alias MultidimTableValue* MultidimTable;

    struct RealMultidimTableValue
    {
        MultidimTable multidim_table;
        RTable rtable;
        ITable itable;
    }

    alias RealMultidimTableValue* RealMultidimTable;

    uint multidim_log2ncolumns(Range)(Range log2n, size_t dim_index)
    {
        return log2n.dropExactly(dim_index + 1).sum;
    }

    bool multidim_use_multiscalar(uint log2ncolumns)
    {
        return log2ncolumns >= log2(vec_size);
    }

    uint multidim_multi_selection(Range)(
        Range log2n, size_t dim_index)
    {
        return multidim_log2ncolumns(log2n, dim_index) >= log2(vec_size) ?
            1 : 0;
    }

    template MultidimTableImpl()
    {
        enum max_ndim = size_t.sizeof * 8;
        alias Allocate!(3 * max_ndim + 3) Alloc;
        alias TableValue[max_ndim] TableMap; 

        struct TableCreator
        {
            TableMap table_map;
            Table tables;
            MultidimTable mt;
            TransposeBuffer buf;

            void add_to(Alloc* alloc, uint[] log2n)
            {
                size_t last = log2n.length - 1;
                foreach(i; 0 .. last)
                {
                    auto l = log2n[i];
                    auto s = multidim_multi_selection(log2n, i);
                    alloc.add(&table_map[i].twiddle, 
                        multi!("twiddle_table_size")(s, l));

                    alloc.add(&table_map[i].buffer,
                        multi!("tmp_buffer_size")(s, l));

                    auto br_log2n = multi!("br_table_log2n")(s, l);
                    alloc.add(&table_map[i].br,
                        multi!("BR.table_size")(s, br_log2n));
                }

                alloc.add(&table_map[last].twiddle, twiddle_table_size(log2n[last]));
                alloc.add(&table_map[last].buffer, tmp_buffer_size(log2n[last]));
                alloc.add(&table_map[last].br, BR.table_size(br_table_log2n(log2n[last])));

                alloc.add(&buf, transpose_buffer_size(log2n));
                alloc.add(&tables, log2n.length);
                alloc.add(&mt, 1);
            }

            auto create(uint[] log2n, void* ptr)
            {
                size_t last = log2n.length - 1;
                foreach(i; 0 .. last)
                {
                    tables[i] = table_map[i];
                    auto s = multidim_multi_selection(log2n, i);
                    multi!("init_fft_table")(s, log2n[i], &tables[i]);
                }
                    
                tables[last] = table_map[last];
                init_fft_table(log2n[last], &tables[last]);

                mt.tables = tables[0 .. log2n.length];
                mt.buffer = buf;
                mt.memory = ptr;
                return mt;
            }
        }

        struct RealTableCreator
        {
            void* itable_memory;
            void* rtable_memory;
            RealMultidimTable rmt;
            TableCreator tc;

            void add_to(Alloc* alloc, uint log2n[])
            {
                auto s = multidim_multi_selection(log2n, 0);
                tc.add_to(alloc, log2n);
                alloc.add(&itable_memory, multi!"itable_size"(s, log2n[0] + 1));
                alloc.add(&rtable_memory, multi!"rtable_size"(s, log2n[0] + 1));
                alloc.add(&rmt, 1);
            }

            auto create(uint[] log2n, void* ptr)
            {
                rmt.multidim_table = tc.create(log2n, ptr);
                auto s = multidim_multi_selection(log2n, 0);
                rmt.rtable = multi!"rfft_table"(s, log2n[0] + 1, rtable_memory);
                rmt.itable = multi!"interleave_table"(
                    s, log2n[0] + 1, itable_memory);

                return rmt; 
            }
        }

        template TC(bool is_real)
        {
            alias select!(is_real, RealTableCreator, TableCreator) TC;
        }

        size_t size(bool is_real)(uint[] log2n)
        {
            Alloc alloc = void; alloc.initialize();
            TC!is_real tc = void;
            tc.add_to(&alloc, log2n);
            return alloc.size();
        }

        template table(bool is_real)
        {
            typeof(TC!is_real.create(null, null))
            table(uint[] log2n, void* ptr)
            {
                Alloc alloc = void; alloc.initialize();
                TC!is_real tc = void;
                tc.add_to(&alloc, log2n);
                alloc.allocate(ptr);
                return tc.create(log2n, ptr);
            }
        }

        void* memory(MultidimTable table) { return table.memory; }
        void* real_memory(RealMultidimTable table)
        {
            return table.multidim_table.memory;
        }
    }

    alias MultidimTableImpl!().table!false multidim_fft_table;
    alias MultidimTableImpl!().size!false multidim_fft_table_size;
    alias MultidimTableImpl!().memory multidim_fft_table_memory;

    alias MultidimTableImpl!().table!true multidim_rfft_table;
    alias MultidimTableImpl!().size!true multidim_rfft_table_size;
    alias MultidimTableImpl!().real_memory multidim_rfft_table_memory;

    void fft_transposed()(
        T* re,
        T* im,
        int log2stride, 
        int log2m,
        Table table,
        TransposeBuffer buffer)
    {
        auto n = st!1 << table.log2n;
        auto m = st!1 << log2m;
        auto stride = st!1 << log2stride;
        auto nbuf = Col.buffer_size(n, m);

        Col[2] col = void; 
        col[0] = Col.create(re, stride, n, m, cast(T*) buffer);
        col[1] = Col.create(im, stride, n, m, cast(T*) buffer + nbuf);

        foreach(j; 0 .. m)
        {
            foreach(i; 0 .. 2)
                col[i].load();

            fft(col[0].column, col[1].column, table);

            foreach(i; 0 .. 2)
                col[i].save();
        }
    }

    //TODO: use multi-scalar
    void rfft_transposed_impl(bool inverse)(
        T* p,
        int log2stride, 
        int log2m,
        Table table,
        TransposeBuffer buffer,
        RTable rtable,
        ITable itable)
    {
        auto n = st!1 << table.log2n;
        auto m = st!1 << log2m;
        auto stride = st!1 << log2stride;
        auto col = Col.create(p, stride, 2 * n, m, cast(T*) buffer);

        foreach(j; 0 .. m)
        {
            col.load();
            static if(inverse)
            {
                irfft(col.column, col.column + n, table, rtable);
                interleave(col.column, table.log2n + 1, itable);
            }
            else
            {
                deinterleave(col.column, table.log2n + 1, itable);
                rfft(col.column, col.column + n, table, rtable);
            }
            col.save();
        }
    }

    alias rfft_transposed_impl!false rfft_transposed;
    alias rfft_transposed_impl!true irfft_transposed;

    size_t column_buffer_size(size_t log2n, size_t log2m)
    {
        return Col.buffer_size(st!1 << log2n, st!1 << log2m) * 2 * T.sizeof;
    }

    size_t transpose_buffer_size()(uint[] log2n)
    {
        size_t maxsz = 0;
        foreach(i; 0 .. log2n.length - 1)
        {
            auto lm = multidim_log2ncolumns(log2n, i);
            auto ln = log2n[i];
            auto s = multidim_multi_selection(log2n, i);
            maxsz = max(
                maxsz, 
                // for first dimension, make the buffer two times as large,
                // so that a real transform can use the same buffer as 
                // a complex transform that is half its size.
                (i == 0 ? 2 : 1) * multi!"column_buffer_size"(
                    s,
                    log2n[i], 
                    multidim_log2ncolumns(log2n, i) - multi!"log2_multi"(s)));
        }

        return maxsz;
    }

    void multidim_fft()(T* re, T* im, MultidimTable multidim_table)
    {
        auto tables = multidim_table.tables;
        if(tables.length == 0)
            return;
        else if(tables.length == 1)
            return fft(re, im, &tables[0]);

        auto buf = multidim_table.buffer;
        auto log2ns = tables.map!(a => a.log2n);
        auto len = st!1 << log2ns.sum;
        int log2m = log2ns.dropExactly(1).sum;
        auto m = log2m.exp2;
        auto next_table = MultidimTableValue(tables[1 .. $], buf, null);
        foreach(i; 0 .. tables[0].log2n.exp2)
            multidim_fft(re + i * m, im + i * m, &next_table);

        auto selection = multidim_multi_selection(log2ns, 0);
        auto l2m = multi!("log2_multi")(selection);
        multi!("fft_transposed")(
            selection, re, im, log2m - l2m, log2m - l2m, &tables[0], buf);
    }

    void rfft_complete()(
        T* p, Table table, RTable rtable, ITable itable)
    {
        deinterleave(p, table.log2n + 1, itable);
        auto n = table.log2n.exp2;
        rfft(p, p + n, table, rtable);
        memmove(p + n + 2, p + n + 1, n * T.sizeof);
        p[n + 1] = 0;
        p[2 * n + 1] = 0;
    }

    void irfft_complete()(
        T* p, Table table, RTable rtable, ITable itable)
    {
        auto n = table.log2n.exp2;
        memmove(p + n + 1, p + n + 2, n * T.sizeof);
        p[2 * n] = 0;
        p[2 * n + 1] = 0;
        irfft(p, p + n, table, rtable);
        interleave(p, table.log2n + 1, itable);
    }

    void raw_rfft()(T* re, T* im, RealMultidimTable rmt)
    {
        rfft(re, im, &rmt.multidim_table.tables[0], rmt.rtable);
    }

    void multidim_rfft()(T* p, RealMultidimTable rmt)
    {
        auto multidim_table = rmt.multidim_table;
        auto tables = multidim_table.tables;
        if(tables.length == 0)
            return;
        else if(tables.length == 1)
            return rfft_complete(p, &tables[0], rmt.rtable, rmt.itable);

        auto n = tables[0].log2n.exp2;
        auto log2ns = tables.map!(a => a.log2n);
        int log2m = log2ns.dropExactly(1).sum;
        auto m = log2m.exp2;
        auto im = p + m * (n + 1);
        auto im_end = im + m * (n + 1);
        auto buf = multidim_table.buffer;

        auto selection = multidim_multi_selection(log2ns, 0);
        auto l2m = multi!("log2_multi")(selection);
        multi!("rfft_transposed")(
            selection, p,
            log2m - l2m, log2m - l2m,
            &tables[0], buf, rmt.rtable, rmt.itable);

        foreach(i; 2 .. n + 1)
            memcpy(im_end  - i * m, im_end - (i + 1) * m, m * T.sizeof);

        memset(im_end - m, 0, m * T.sizeof);
        memset(im, 0, m * T.sizeof);

        auto next_table = MultidimTableValue(tables[1 .. $], buf, null);
        foreach(i; 0 .. n + 1)
            multidim_fft(p + i * m, im + i * m, &next_table);
    }

    void multidim_irfft()(T* p, RealMultidimTable rmt)
    {
        auto multidim_table = rmt.multidim_table;
        auto tables = multidim_table.tables;
        if(tables.length == 0)
            return;
        else if(tables.length == 1)
            return irfft_complete(p, &tables[0], rmt.rtable, rmt.itable);

        auto n = tables[0].log2n.exp2;
        auto log2ns = tables.map!(a => a.log2n);
        int log2m = log2ns.dropExactly(1).sum;
        auto m = log2m.exp2;
        auto im = p + m * (n + 1);
        auto im_end = im + m * (n + 1);
        auto buf = multidim_table.buffer;

        auto next_table = MultidimTableValue(tables[1 .. $], buf, null);
        foreach(i; 0 .. n + 1)
            multidim_fft(im + i * m, p + i * m, &next_table);

        foreach(i; 0 .. n - 1)
            memcpy(im + i * m, im + (i + 1) * m, m * T.sizeof);
        
        memset(im_end - 2 * m, 0, 2 * m * T.sizeof);

        auto selection = multidim_multi_selection(log2ns, 0);
        auto l2m = multi!("log2_multi")(selection);
        multi!("irfft_transposed")(
            selection, p,
            log2m - l2m, log2m - l2m,
            &tables[0], buf, rmt.rtable, rmt.itable);
    }

    static void scale()(T* data, size_t n, Twiddle factor)
    {
        auto k = V.twiddle_to_vector(factor);
        
        foreach(ref e; (cast(vec*) data)[0 .. n / vec_size])
            e = e * k;

        foreach(ref e;  data[ n & ~(vec_size - 1) .. n])
            e = e * factor;
    }

    static void cmul(T* dr, T* di, T* sr, T* si, size_t n)
    {
        foreach(i; 0 .. n / vec_size)
        {
            auto _dr = (cast(vec*) dr)[i]; 
            auto _di = (cast(vec*) di)[i]; 
            auto _sr = (cast(vec*) sr)[i]; 
            auto _si = (cast(vec*) si)[i];
            (cast(vec*) dr)[i] = _dr * _sr - _di * _si;
            (cast(vec*) di)[i] = _dr * _si + _di * _sr;
        }
        foreach(i; n / vec_size * vec_size .. n)
        {
            auto _dr = dr[i]; 
            auto _di = di[i]; 
            auto _sr = sr[i]; 
            auto _si = si[i];
            dr[i] = _dr * _sr - _di * _si;
            di[i] = _dr * _si + _di * _sr;
        }
    }

    size_t alignment(size_t n)
    {
        return max(
            min(next_pow2(vec.sizeof), next_pow2(T.sizeof * n)), 
            (void*).sizeof);
    }
    
    alias MSFFT.Table MultiTable;
    alias MSFFT.fft_table_size multi_fft_table_size;
    alias MSFFT.fft_table multi_fft_table;
    
    void multi_fft()(T* re, T* im, MultiTable table)
    {
        MSFFT.fft(
            cast(MSFFT.T*) re,
            cast(MSFFT.T*) im,
            cast(MSFFT.Table) table);
    }

    size_t multi_fft_ntransforms()()
    {
        return MSFFT.T.sizeof / T.sizeof;
    }

    alias MSFFT.RTable MultiRTable;
    alias MSFFT.rtable_size multi_rtable_size;
    alias MSFFT.rfft_table multi_rfft_table;
    alias MSFFT.ITable MultiITable;
    alias MSFFT.itable_size multi_itable_size;
    alias MSFFT.interleave_table multi_interleave_table;
    
    void multi_rfft_complete()(
        T* data, MultiTable table, MultiRTable rtable, MultiITable itable)
    {
        MSFFT.rfft_complete(
            cast(MSFFT.T*) data,
            cast(MSFFT.Table) table,
            cast(MSFFT.RTable) rtable,
            cast(MSFFT.ITable) itable);
    }

    size_t multi_rfft_ntransforms()(){ return MSFFT.T.sizeof / T.sizeof; }
}

mixin template Instantiate()
{
    static if(is(typeof(implementation)))
        alias implementation.get impl;
    else
        enum impl = 0;

    void set_implementation(int i)
    {
        static if(is(typeof(implementation.set)))
            implementation.set(i);
    }

    alias FFTs[0] FFT0;
    alias FFT0.T T;

    template Api()
    {
        import decl = pfft.instantiate_declarations;
        mixin decl.Instantiate!();
    }

    template code(names ...)
    {
        static if(names.length == 0)
            enum code = "";
        else
        {
            enum name = names[0];
            alias get_member!(Api!(), name) member;

            static if(is(member E : E*))
                enum current = 
                    "struct "~name~"Value{}\n" ~
                    "alias "~name~"Value* "~name~";\n";
            else static if(
                is(typeof(member) == function) && 
                __traits(hasMember, FFT0, name))
            {
                enum current = 
                    "auto "~name~"("~generate_arg_list!(member, true)~
                    "){ return cast("~ ReturnType!member.stringof~
                    ") SelectImplementation!FFTs.call!(\""~name~"\")(impl, "~
                    generate_arg_list!(member, false)~"); }\n";
            }
            else 
                enum current = "";

            enum code = current ~ code!(names[1 .. $]);
        }
    }

    mixin(code!(__traits(allMembers, Api!())));
}
