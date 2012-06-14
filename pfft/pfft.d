//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.pfft;

import core.memory, core.bitop;

template Import(TT)
{
    static if(is(TT == float))
        import impl = pfft.impl_float;
    else static if(is(TT == double))
        import impl = pfft.impl_double;
    else static if(is(TT == real))
        import impl = pfft.impl_real;
    else    
        static assert(0, "Not implemented");
}

template st(alias a){ enum st = cast(size_t) a; }

///
final class Fft(TT)
{
    mixin Import!TT;

    int log2n;
    impl.Table table;
    
    this(size_t n)
    {
        assert((n & (n - 1)) == 0);
        log2n  = bsf(n);
        auto mem = GC.malloc( impl.table_size_bytes(log2n));
        table = impl.fft_table(log2n, mem);
    }
    
    void fft(impl.T[] re, impl.T[] im)
    {
        assert(re.length == im.length); 
        assert(re.length == (st!1 << log2n));
        assert(((impl.alignment(log2n) - 1) & cast(size_t) re.ptr) == 0);
        assert(((impl.alignment(log2n) - 1) & cast(size_t) im.ptr) == 0);
        
        impl.fft(re.ptr, im.ptr, log2n, table);
    }

    static TT[] allocate(size_t n)
    {
        auto r = cast(TT*) GC.malloc(n * TT.sizeof);
        assert(((impl.alignment(bsr(n)) - 1) & cast(size_t) r) == 0);
        return r[0 .. n];
    }
}

final class Rfft(TT)
{
    mixin Import!TT;

    int log2n;
    Fft!TT _complex;
    impl.RTable rtable;

    this(size_t n)
    {
        assert((n & (n - 1)) == 0);
        log2n  = bsf(n);
    
        _complex = new Fft!TT(n / 2);

        auto mem = GC.malloc( impl.rtable_size_bytes(log2n));
        rtable = impl.rfft_table(log2n, mem);
    }

    void rfft(TT[] data, TT[] re, TT[] im)
    {
        assert(re.length == im.length);
        assert(2 * re.length == data.length);
        assert(data.length == (st!1 << log2n));
        assert(((impl.alignment(log2n - 1) - 1) & cast(size_t) re.ptr) == 0);
        assert(((impl.alignment(log2n - 1) - 1) & cast(size_t) re.ptr) == 0);
        assert(((impl.alignment(log2n) - 1) & cast(size_t) data.ptr) == 0);

        impl.rfft(data.ptr, re.ptr, im.ptr, log2n, _complex.table, rtable);   
    }

    alias Fft!(TT).allocate allocate;
    
    @property auto complex(){ return _complex; }
}
