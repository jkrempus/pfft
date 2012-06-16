//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.stdapi;

import core.memory, std.complex, std.traits, core.bitop, std.typetuple;

// Current GDC branch for android insists on using sinl and friends when
// std.math is imported, so we need to do this:
version(GNU) version(ARM)
{
    template staticReduce(alias r, alias accumulate, args...)
    {
        static if(args.length == 0)
            enum staticReduce = r;
        else
            enum staticReduce = 
                staticReduce!(accumulate!(r, args[0]), accumulate, args[1..$]);
    }

    template mathLfunc(alias r, alias name)
    {
        enum mathLfunc = "
            extern(C) auto "~name~"l(real a) 
            { 
                return cast(real) 
                    core.stdc.math."~name~"(cast(double) a); 
            }
            " ~ r; 
    }
    
    template twoArgMathLfunc(alias r, alias name) 
    {
        enum twoArgMathLfunc = "
            extern(C) auto "~name~"l(real a, real b) 
            { 
                return cast(real) 
                    core.stdc.math."~name~"(cast(double) a, cast(double) b); 
            }
            " ~ r; 
    }
      
    mixin(staticReduce!("", mathLfunc, 
        "sin", "cos", "asin", "tan", "sqrt", "atan", "logb"));
    mixin(staticReduce!("", twoArgMathLfunc,"remainder", "fmod", "atan2"));

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

final class TypedFft(TT)
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
    C* return_buf = null;
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
                    re, im, &(range[0].re), (cast(size_t)1) << log2n);
        
        foreach(i; 0 .. (cast(size_t)1) << log2n)
        {
            re[i] = range[i].re;
            im[i] = range[i].im;
        }
    }
   
    private auto interleaveArray(R)(R range)
    {

        static if(is(typeof(range[0].re) == impl.T))
            if(fastInterleave(range))
                return impl.interleaveArray(
                    re, im, &(range[0].re), (cast(size_t)1) << log2n);
        
        foreach(i; 0 .. (cast(size_t)1) << log2n)
        {
            range[i].re = re[i];
            range[i].im = im[i];
        }
    }

    private auto copyArray(R)(R range)
    {

        static if(is(typeof(range[0].re) == impl.T))
            if(isComplexArray!(R, TT)())
            {
                memcpy(
                    cast(void*)re.ptr, 
                    cast(void*) &range[0].re,
                    TT.sizeof * (st!1 << log2n)); 
            }
        
        foreach(i; 0 .. (cast(size_t)1) << log2n)
        {
            range[i].re = re[i];
            range[i].im = im[i];
        }
    }
    
    
    void fft(Ret, R)(R range, Ret buf)
    {
        deinterleaveArray(range);
        impl.fft(re, im, log2n, table);
        interleaveArray(buf);
    }
    
    
    const(C[]) fft(R)(R range)
    {
        if(return_buf == null)
            return_buf = cast(C*)GC.malloc(C.sizeof << log2n);
        fft(range, return_buf);
        return return_buf[0 .. (1 << log2n)];
    }

    static C[] allocate(size_t n)
    {
        auto r = cast(C*) GC.malloc(n * C.sizeof);
        assert((n & (n - 1)) == 0);
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

    size_t nmax;
    
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
Fft constructor. $(D_PARAM nmax) is the maximal fft size this instance of Fft will be 
able to perform and should be a power of two.
 */
    this(size_t nmax)
    {
        assert((nmax & (nmax - 1)) == 0);
        this.nmax = nmax;
    }
   
    
/**
This computes the table for type $(D_PARAM T) and size r.length if it hasn't already been
computed and stores it. Then it computes the fourier transform of data in r 
and returns it. Data in r isn't changed. The length of r should be less than or 
equal to the size passed to the constructor. 
 */
    auto fft(T, R)(R r) 
    {
        auto n = r.length;
        assert(n <= nmax);
        assert((n & (n - 1)) == 0);
        return impl!T(n).fft(r);
    }
   
/**
Does the same as the method above, but stores the results in a user provided 
buffer ret instead of returning it. Ret must be a random access range of complex
numbers with length defined.  
 */ 
    auto fft(R, Ret)(R r, Ret ret) 
    {
        auto n = r.length;
        assert(n <= nmax);
        assert((n & (n - 1)) == 0);
        impl!(typeof(ret[0].re))(r.length).fft(r, ret);
    }
/**
Allocates an array of size n aligned appropriately for use as parameters to
fft() methods. Both fft methods will still work correctly even if the 
parameters are not propperly aligned, they will just be a bit slower.
 */
    static auto allocate(T)(size_t n)
    {
        assert((n & (n - 1)) == 0);
        return TypedFft!(typeof(T.init.re)).allocate(n);
    }
}

