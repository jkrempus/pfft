//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.stdapi;

import core.memory, std.complex, std.traits, core.bitop;

auto isComplexArray(R, T)()
{
    static if(
        ((isArray!R || isPointer!R) &&
        is(typeof(R.init[0].re) == T) && 
        is(typeof(R.init[0].im) == T) &&
        typeof(R.init[0]).sizeof == 2*T.sizeof))
    {
        typeof(R.init[0]) e;
        return cast(typeof(e.re)*)&e == &(e.re) && 
            &(e.re) + 1 == &(e.im);
    }
    else
        return false;
}

final class Fft(TT)
{
    static if(is(TT == float))
		import impl = pfft.impl_float;
    else static if(is(TT == double))
		import impl = pfft.impl_double;
    else    
        static assert(0, "Not implemented");
        
    
    int log2n;
    impl.T* re;
    impl.T* im;
    Complex!(impl.T)* return_buf = null;
    impl.Table table;
    
    
    this(int n)
    {
        log2n  = bsf(n);
        re = cast(impl.T*)GC.malloc(impl.T.sizeof << log2n);
        im = cast(impl.T*)GC.malloc(impl.T.sizeof << log2n);
        auto mem = GC.malloc( impl.table_size_bytes(log2n));
        table = impl.fft_table(log2n, mem);
    }
    
    
    private auto deinterleaveArray(R)(R range)
    {
        if(isComplexArray!(R, TT)() && impl.isAligned(&(range[0].re)))
        {
            impl.deinterleaveArray(re, im, &(range[0].re), 1UL << log2n);
        }
        else
        {
            foreach(i; 0 .. 1UL << log2n)
            {
                re[i] = range[i].re;
                im[i] = range[i].im;
            }
        }
    }
    
    
    private auto interleaveArray(R)(R range)
    {
        if(isComplexArray!(R, TT)() && impl.isAligned(&(range[0].re)))
        {
            impl.interleaveArray(re, im, &(range[0].re), 1UL << log2n);
        }
        else
        {
            foreach(i; 0 .. 1UL << log2n)
            {
                range[i].re = re[i];
                range[i].im = im[i];
            }
        }
    }
    
    
    void fft(_TT = TT, Ret, R)(R range, Ret buf) if(is( _TT == TT ))
    {
        deinterleaveArray(range);
        impl.fft(re, im, log2n, table);
        interleaveArray(buf);
    }
    
    
    auto fft(_TT = TT, R)(R range) if(is( _TT == TT ))
    {
        alias Complex!(impl.T) C;
        if(return_buf == null)
            return_buf = cast(C*)GC.malloc(C.sizeof << log2n);
        fft(range, return_buf);
        return return_buf[0 .. (1 << log2n)];
    }
}

