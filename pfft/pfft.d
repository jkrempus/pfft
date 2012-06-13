//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.pfft;

import core.memory, core.bitop;

///
final class Pfft(TT)
{
    static if(is(TT == float))
        import impl = pfft.impl_float;
    else static if(is(TT == double))
        import impl = pfft.impl_double;
    else static if(is(TT == real))
        import impl = pfft.impl_real;
    else    
        static assert(0, "Not implemented");

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
        assert(
            re.length == im.length && 
            re.length == (1UL << log2n) &&
            ((impl.alignment(log2n) - 1) & cast(size_t) re.ptr) == 0 &&
            ((impl.alignment(log2n) - 1) & cast(size_t) im.ptr) == 0);
        
        impl.fft(re.ptr, im.ptr, log2n, table);
    }

    static TT[] allocate(size_t n)
    {
        auto r = cast(TT*) GC.malloc(n * TT.sizeof);
        assert(((impl.alignment(bsr(n)) - 1) & cast(size_t) r) == 0);
        return r[0 .. n];
    }
}
