//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.splitapi;

import core.memory, core.bitop;

final class SplitFft(TT)
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
        assert(re.length == im.length && re.length >> log2n == 1U);
        
        impl.fft(re.ptr, im.ptr, log2n, table);
    }
}
