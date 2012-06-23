//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.stdapi;

import core.memory, std.complex, std.traits, core.bitop, std.typetuple, std.range;

// Current GDC branch for android insists on using sinl and friends when
// std.math is imported, so we need to do this:
version(GNU) version(ARM)
{
    auto generateFunctions(string fmt, string[] names)
    {
        auto r = "";
        
        foreach(name; names)
            r ~= std.array.replace(fmt, "%s", name);

        return r; 
    }
  
    enum twoArgMathL =
    q{
        extern(C) auto %sl(real a, real b) 
        { 
            return cast(real) 
                core.stdc.math.%s(cast(double) a, cast(double) b); 
        }
    };
 
    enum oneArgMathL =
    q{
        extern(C) auto %sl(real a) 
        { 
            return cast(real) 
                core.stdc.math.%s(cast(double) a); 
        }
    };
    
    mixin(generateFunctions(oneArgMathL, 
        ["sin", "cos", "asin", "tan", "sqrt", "atan", "logb"]));
    mixin(generateFunctions(twoArgMathL, ["remainder", "fmod", "atan2"]));

    extern(C) auto modfl(real a, real* b) 
    {
        double tmp = *b;
        auto r = cast(real) core.stdc.math.modf(cast(double) a, &tmp);
        *b = tmp;
        return r;
    }

    extern(C) auto llrintl(real a)
    {
        return core.stdc.math.llrint(cast(double) a);
    }

    extern(C) auto remquol(real a, real b, int *i)
    {
       return cast(real) core.stdc.math.remquo(cast(double) a,cast(double) b, i); 
    } 
}

template st(alias a){ enum st = cast(size_t) a; } 

auto isComplexArray(R, T)()
{
    static if(
        ((isArray!R || isPointer!R) &&
        is(typeof(R.init[0].re) == T) && 
        is(typeof(R.init[0].im) == T) &&
        typeof(R.init[0]).sizeof == 2*T.sizeof))
    {
        typeof(R.init[0]) e;
        return 
            cast(typeof(e.re)*)&e == &(e.re) && 
            &(e.re) + 1 == &(e.im);
    }
    else
        return false;
}

private final class TypedFft(TT)
{    
    static if(is(TT == float))
        import impl = pfft.impl_float;
    else static if(is(TT == double))
        import impl = pfft.impl_double;
    else static if(is(TT == real))
        import impl = pfft.impl_real;
    else 
        static assert(0, "Not implemented");
        
    
    uint log2n;
    impl.T* re;
    impl.T* im;
    alias Complex!(impl.T) C;
    impl.Table table;
    impl.RTable rtable;
    
    
    this(size_t n)
    {
        log2n  = bsf(n);
        re = cast(impl.T*)GC.malloc(impl.T.sizeof << log2n);
        im = cast(impl.T*)GC.malloc(impl.T.sizeof << log2n);
        
        auto mem = GC.malloc( impl.table_size_bytes(log2n));
        table = impl.fft_table(log2n, mem);

        mem = GC.malloc( impl.rtable_size_bytes(log2n + 1));
        rtable = impl.rfft_table(log2n + 1, mem);
    }

    private bool isAligned(impl.T* p)
    {
        return ((cast(size_t)p) & (impl.alignment(log2n) - 1)) == 0;
    }    
    
    private bool fastInterleave(R)(R range)
    {
        return isComplexArray!(R, TT)() && isAligned(&(range[0].re));
    }
    
    private void deinterleaveArray(R)(R range)
    {
        static if(is(typeof(range[0].re) == impl.T))
            if(fastInterleave(range))
                return impl.deinterleaveArray(
                    re, im, &(range[0].re), st!1 << log2n);
        
        foreach(i, e; range)
        {
            re[i] = e.re;
            im[i] = e.im;
        }
    }
   
    private void interleaveArray(R)(R range)
    {
        static if(is(typeof(range[0].re) == impl.T))
            if(fastInterleave(range))
                return impl.interleaveArray(
                    re, im, &(range[0].re), st!1 << log2n);
        
        foreach(i, ref e; range)
        {
            e.re = re[i];
            e.im = im[i];
        }
    }

    void fft(bool inverse, Ret, R)(R range, Ret buf)
    {
        deinterleaveArray(range);
        static if(inverse)
        {
            auto n = st!1 << log2n; 
            impl.fft(im, re, log2n, table);
            impl.scale(re, n, (cast(TT) 1) / n);
            impl.scale(im, n, (cast(TT) 1) / n);
        }
        else
            impl.fft(re, im, log2n, table);
        
        interleaveArray(buf);
    }
    
    void rfft(Ret, R)(R range, Ret buf)
    {
        deinterleaveArray(cast(Complex!(ElementType!R)[])range);
        impl.rfft(re, im, log2n + 1, table, rtable);
        interleaveArray(buf);
       
        auto n = st!1 << log2n; 
        buf[n] = Complex!TT(buf[0].im, 0);
        buf[0].im = 0;
        
        foreach(i; 1 .. n)
        {
            buf[2*n - i].re = buf[i].re;
            buf[2*n - i].im = -buf[i].im;
        }
    }
    
    C[] fft(bool inverse, R)(R range)
    {
        auto return_buf = cast(C*)GC.malloc(C.sizeof << log2n);
        fft!inverse(range, return_buf);
        return return_buf[0 .. (1 << log2n)];
    }

    C[] rfft(R)(R range)
    {
        auto n = st!1 << log2n;
        auto return_buf = cast(C*)GC.malloc(C.sizeof << (log2n + 1));
        rfft(range, return_buf[0 .. 2 * n]);
        return return_buf[0 .. 2 * n];
    }

    static C[] allocate(size_t n)
    {
        auto r = cast(C*) GC.malloc(n * C.sizeof);
        assert(((impl.alignment(bsr(n)) - 1) & cast(size_t) r) == 0);
        return r[0 .. n];
    }
}


/**
A class for calculating discrete fourier transforms using fast fourier 
transform. This class mimics std.numeric.Fft, but works a bit differently
internally. The Fft in phobos does all the initialization when the
constructor is called. Because pfft uses different tables for each
combination of type and size, it can't do all the initialization up front.
Instead, it calculates a table for a combination of type T and size n the 
first time the fft() method is called with a template parameter T a parameter
of size n and then stores this table for later use.   
 */
final class Fft
{
    import std.variant;

    private struct Key{ TypeInfo ti; size_t n; }
    
    private void*[Key] implDict;

    private auto impl(T)(size_t n)
    {
        auto key = Key(typeid(T), n);
        
        auto p = key in implDict;
        if(p)
            return cast(TypedFft!T)*p;
        else
        {
            auto t = new TypedFft!T(n);
            implDict[key] = cast(void*)t;
            return t;
        }
    }
    
/** 
Fft constructor. $(D_PARAM nmax) is there just for compatibility with std.numeric.Fft.
 */
    this(size_t nmax = size_t.init)
    {
    }
   
    
/**
Computes  the discrete fourier transform of data in r  and returns it. Data in
r isn't changed.  R must be a forward range with complex or floating point 
elements. The number of elements in $(D_PARAM r) must be a power of two.
T must be a floating point type. The length of the returned array is the
same as the number of elements in $(D_PARAM r).
 */
    Complex!(T)[] fftTemplate(bool inverse, T, R)(R r) 
    {
        auto n = walkLength(r);
        assert((n & (n - 1)) == 0);
        return impl!T(n).fft!inverse(r);
    }

    Complex!(T)[] fft(T, R)(R r) if(!isNumeric!(ElementType!R)) 
    {
        return fftTemplate!false(r);
    }

    Complex!(T)[] fft(T, R)(R r) if(isNumeric!(ElementType!R)) 
    {
        auto n = walkLength(r);
        assert((n & (n - 1)) == 0);
        return impl!T(n / 2).rfft(r);
    }
   
/**
Computes the discrete fourier transform of data in r and stores the result in
the user provided buffer ret. Data in r isn't changed. R must be a forward range
with complex or floating point elements.Here a complex type is a type with  
assignable properties .re and .im. Ret must be an input range with complex 
elements. $(D_PARAM r) and $(D_PARAM ret) must have the same number of elements
and that number must be a power of two.
 */ 
    private void fftTemplate(bool inverse, R, Ret)(R r, Ret ret)
    {
        static if(is(typeof(ret.save)))
            ret = ret.save();
        
        r = r.save();

        auto n = walkLength(r);
        assert((n & (n - 1)) == 0);
        impl!(typeof(ret[0].re))(n).fft!inverse(r, ret);
    }

    void fft(R, Ret)(R r, Ret ret) if(!isNumeric!(ElementType!R))
    {
       fftTemplate!false(r, ret); 
    }

    auto fft(R, Ret)(R r, Ret ret) if(isNumeric!(ElementType!R))
    {
        r = r.save();
        auto n = walkLength(r);
        assert((n & (n - 1)) == 0);
        impl!(typeof(ret[0].re))(r.length / 2).rfft(r, ret);
    }


/**
Computes  the inverse discrete fourier transform of data in r  and returns it. 
Data in r isn't changed.  R must be a forward range with complex or floating 
point  elements. The number of elements in $(D_PARAM r) must be a power of two.
T must be a floating point type. The length of the returned array is the
same as the number of elements in $(D_PARAM r).
 */
    Complex!(T)[] inverseFft(T, R)(R r)
    {
        return fftTemplate!true(r);
    }

/**
Computes the inverse discrete fourier transform of data in r and stores the 
result in the user provided buffer ret. Data in r isn't changed. R must be a 
forward range with complex or floating point elements.Here a complex type is 
a type with assignable properties .re and .im. Ret must be an input range with
complex elements. $(D_PARAM r) and $(D_PARAM ret) must have the same number of
elements and that number must be a power of two.
 */ 
    void inverseFft(R, Ret)(R r, Ret ret)
    {
       fftTemplate!true(r, ret); 
    }

/**
Allocates an array of size n aligned appropriately for use as parameters to
fft() methods. Both fft methods will still work correctly even if the 
parameters are not propperly aligned (or even if they aren't arrays at all), 
they will just be a bit slower.
 */
    static T[] allocate(T)(size_t n)
    {
        assert((n & (n - 1)) == 0);
        auto r = cast(T*) GC.malloc(n * T.sizeof);
        return r[0 .. n];
    }
}

