//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.stdapi;

import core.memory, std.complex, std.traits, core.bitop, std.typetuple;

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

final class TypedFft(TT)
{    
    static if(is(TT == float))
        import impl = pfft.impl_float;
    else static if(is(TT == double))
        import impl = pfft.impl_double;
    else static if(is(TT == real))
        import impl = pfft.scalar_real;
    else    
        static assert(0, "Not implemented");
        
    
    uint log2n;
    impl.T* re;
    impl.T* im;
    Complex!(impl.T)* return_buf = null;
    impl.Table table;
    
    
    this(size_t n)
    {
        log2n  = bsf(n);
        re = cast(impl.T*)GC.malloc(impl.T.sizeof << log2n);
        im = cast(impl.T*)GC.malloc(impl.T.sizeof << log2n);
        auto mem = GC.malloc( impl.table_size_bytes(log2n));
        table = impl.fft_table(log2n, mem);
    }

    private bool isAligned(impl.T* p)
    {
        return ((cast(size_t)p) & (impl.alignment(log2n) - 1)) == 0;
    }    
    
    private auto deinterleaveArray(R)(R range)
    {
        if(isComplexArray!(R, TT)() && isAligned(&(range[0].re)))
        {
            impl.deinterleaveArray(re, im, &(range[0].re), (cast(size_t)1) << log2n);
        }
        else
        {
            foreach(i; 0 .. (cast(size_t)1) << log2n)
            {
                re[i] = range[i].re;
                im[i] = range[i].im;
            }
        }
    }
    
    
    private auto interleaveArray(R)(R range)
    {
        if(isComplexArray!(R, TT)() && isAligned(&(range[0].re)))
        {
            impl.interleaveArray(re, im, &(range[0].re), (cast(size_t)1) << log2n);
        }
        else
        {
            foreach(i; 0 .. (cast(size_t)1) << log2n)
            {
                range[i].re = re[i];
                range[i].im = im[i];
            }
        }
    }
    
    
    void fft(Ret, R)(R range, Ret buf)
    {
        deinterleaveArray(range);
        impl.fft(re, im, log2n, table);
        interleaveArray(buf);
    }
    
    
    auto fft(R)(R range)
    {
        alias Complex!(impl.T) C;
        if(return_buf == null)
            return_buf = cast(C*)GC.malloc(C.sizeof << log2n);
        fft(range, return_buf);
        return return_buf[0 .. (1 << log2n)];
    }
}

final class Fft
{
    import std.variant;

    private void*[string] implDict;

    size_t n;
    
    private @property auto impl(T)()
    {
        auto p = T.stringof in implDict;
        if(p)
            return cast(TypedFft!T)*p;
        else
        {
            auto t = new TypedFft!T(n);
            implDict[T.stringof] = cast(void*)t;
            return t;
        }
    }
    
    this(size_t _n)
    {
        n = _n;
    }
    
    auto fft(T, R)(R r) 
    {
        return impl!T.fft(r);
    }
    
    auto fft(R, Ret)(R r, Ret ret) 
    {
        impl!(typeof(ret[0].re)).fft(r, ret);
    }
}


