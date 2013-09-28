//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.stdapi;

import  std.complex, std.traits, core.bitop, std.typetuple, std.range,
        std.algorithm;

import core.memory;

private:

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

template impl(T)
{
    static if(is(T == float))
        import impl = pfft.impl_float;
    else static if(is(T == double))
        import impl = pfft.impl_double;
    else static if(is(T == real))
        import impl = pfft.impl_real;
    else 
        static assert(0, "Not implemented");
}

template isComplex(T)
{
    enum isComplex =
        !isNumeric!T &&
        is(typeof(T.init.re)) &&
        is(typeof(T.init.im)) &&
        isFloatingPoint!(typeof(T.init.re)) && 
        isFloatingPoint!(typeof(T.init.im));
}

void saveIfForward(R)(ref R r)
{
    static if(isForwardRange!R)
        r = r.save;
}

bool isAligned(T)(T* p, uint log2n)
{
    //TODO: parameter to alignment() may be wrong here.
    return ((cast(size_t)p) & (impl!(T).alignment(log2n) - 1)) == 0;
}    

T* alignedScalarPtr(T, R)(R r, uint log2n)
{
    static if(!(isArray!R || isPointer!R))
        enum isSupported = false;
    else static if(
        isComplex!(ElementType!R) && 
        is(typeof(R.init[0].re) == T) &&
        typeof(R.init[0]).sizeof == 2 * T.sizeof)
    {
        typeof(R.init[0]) e;
        auto isSupported =  
            cast(typeof(e.re)*)&e == &(e.re) && 
            &(e.re) + 1 == &(e.im);
    }
    else
        enum isSupported = is(T == ElementType!R);

    return isSupported && isAligned(&(r[0].re), log2n) ?  &(r[0].re) : null;
}

void deinterleave_array(R, T)(
    uint log2n, R r, T* re, T* im)
{
    static if(is(typeof(r[0].re) == T))
        if(auto p = alignedScalarPtr!T(r, log2n))
            return impl!(T).deinterleave_array(re, im, p, st!1 << log2n);

    foreach(i; 0 .. st!1 << log2n)
    {
        static if(isComplex!(ElementType!R))
        {
            re[i] = r.front.re;
            im[i] = r.front.im;
            r.popFront();
        }
        else
        {
            re[i] = r.front;
            r.popFront();
            im[i] = r.front;
            r.popFront();
        }
    }
}

void interleave_array(R, T)(
    uint log2n, R r, T* re, T* im)
{
    static if(is(typeof(r[0].re) == T))
        if(auto p = alignedScalarPtr!T(r, log2n))
            return impl!(T).interleave_array(re, im, p, st!1 << log2n);

    foreach(i; 0 .. st!1 << log2n)
    {
        static if(isComplex!(ElementType!R))
        {
            r.front.re = re[i];
            r.front.im = im[i];
            r.popFront();
        }
        else
        {
            r.front = re[i];
            r.popFront();
            r.front = im[i];
            r.popFront();
        }
    }
}

T[] slice(T)(ref T a) { return (&a)[0 .. 1]; }

struct Cached
{
    template typeIndex(T)
    {
        enum typeIndex =
            is(T == float) ? 0 :
            is(T == double) ? 1 : 2;
    }

    struct Entry
    {
        void* table;
        void* rtable;
    }

    struct MemoryBlock
    {
        void[] mem;

        void* get(size_t size)
        {
            if(mem.length < size)
                mem = GC.malloc(size)[0 .. size];

            return mem.ptr;
        }
    }

    enum nsizes = size_t.sizeof * 8;
    Entry[nsizes * 3] entries;
    MemoryBlock _transposeBuffer;
    MemoryBlock _multidimMemory;
    MemoryBlock _re;
    MemoryBlock _im;

    Entry* entry(T)(uint log2n)
    {
        return entries.ptr + nsizes * typeIndex!T + log2n;
    }

    impl!T.MultidimTable table(T)(uint log2n)
    {
        auto e = entry!T(log2n);
        if(!e.table)
        {
            auto mem = GC.malloc(impl!T.multidim_fft_table_size(log2n.slice));
            e.table = cast(void*) impl!T.multidim_fft_table(log2n.slice, mem);
        }

        return cast(typeof(return)) e.table; 
    }

    impl!T.RealMultidimTable rtable(T)(uint log2n)
    {
        auto e = entry!T(log2n);
        if(!e.rtable)
        {
            auto mem = GC.malloc(impl!T.multidim_rfft_table_size(log2n.slice));
            e.rtable = cast(void*) impl!T.multidim_rfft_table(log2n.slice, mem);
        }

        return cast(typeof(return)) e.rtable; 
    }
    
    T* re(T)(size_t n)
    {
        return cast(typeof(return)) _re.get(T.sizeof * n); 
    }
    
    T* im(T)(size_t n)
    {
        return cast(typeof(return)) _im.get(T.sizeof * n); 
    }
}

/**
A class for calculating discrete fourier transforms using fast fourier 
transform. This class mimics std.numeric.Fft, but works a bit differently
internally. The Fft in phobos does all the initialization when the
constructor is called. Because pfft uses different tables for each
combination of type and size, it can't do all the initialization up front.
Instead, it calculates a table for a combination of type $(D T) and size $(I n)
the first time the $(D fft) method is called with a template parameter $(D T)
and a parameter of size $(I n) and then stores this table for later use.   

Example:
---
import std.stdio, std.conv, std.exception, std.complex;
import pfft.stdapi;

void main(string[] args)
{
    auto n = to!int(args[1]);
    
    enforce((n & (n-1)) == 0, "N must be a power of two.");

    auto f = new Fft(n);
    auto data = Fft.allocate!(double)(n);

    foreach(ref e; data)
        readf("%s %s\n", &e.re, &e.im);
    
    auto ft = f.fft!double(data);

    foreach(e; ft)
        writefln("%s %s", e.re, e.im);
}
---
 */

public final class Fft
{
    import std.variant;

    private enum nSizes = 8 * size_t.sizeof;

    Cached cached;

    auto numberOfElements(R)(R r)
    {
        static if(hasLength!R)
            return r.length;
        else static if(isForwardRange!R)
            return walkLength(r.save);
        else
            static assert(false, 
                "Can't get the length of the range without consumming it.");
    }

/** 
Fft constructor. nmax is there just for compatibility with std.numeric.Fft.
 */
    this(size_t nmax = size_t.init) { }

    private void fftTemplate(bool inverse, R, Ret)(R r, Ret ret)
    {
        saveIfForward(r);
        saveIfForward(ret); 

        alias typeof(ret[0].re) T;

        auto n = numberOfElements(r);
        assert((n & (n - 1)) == 0);
        uint log2n = bsr(n);

        auto re = cached.re!T(n);
        auto im = cached.im!T(n);
        auto multidim_table = cached.table!T(log2n);


        static if(isComplex!(ElementType!R))
            deinterleave_array(log2n, r, re, im);
        else
        {
            im[0 .. n] = 0;
            static if(is(ElementType!R == T) && (isPointer!R || isArray!R))
                re[0 .. n] = r[0 .. n];
            else
                for(T* p = re; !r.empty; re++, r.popFront())
                    *p = r.front;
        }

        static if(inverse)
        {
            impl!(T).multidim_fft(im, re, multidim_table);
            impl!(T).scale(re, n, cast(T) 1 / n);
            impl!(T).scale(im, n, cast(T) 1 / n);
        }
        else
        {
            impl!(T).multidim_fft(re, im, multidim_table);
        }

        interleave_array(log2n, ret, re, im);
    }

/**
Computes the discrete fourier transform of data in r and stores the result in
the user provided buffer ret. Data in r isn't changed. $(D R) must be a forward 
range or a range with a length property. It must have complex or floating point 
elements. Here a complex type is a type with assignable floating point properties
$(D re) and $(D im). Ret must be an input range with complex elements. r and ret must
have the same number of elements and that number must be a power of two.
 */ 
    void fft(R, Ret)(R r, Ret ret) if(isComplex!(ElementType!R))
    {
       fftTemplate!false(r, ret); 
    }

    auto fft(R, Ret)(R r, Ret ret) if(isFloatingPoint!(ElementType!R))
    {
        saveIfForward(r);
        saveIfForward(ret); 

        alias typeof(ret[0].re) T;

        auto n = numberOfElements(r);
        assert((n & (n - 1)) == 0);
        n /= 2;
        auto log2n = bsr(n);

        auto re = cached.re!T(n);
        auto im = cached.im!T(n);
        auto rtable = cached.rtable!T(log2n);

        deinterleave_array(log2n, r, re, im);
        impl!(T).raw_rfft(re, im, rtable);
        interleave_array(log2n, ret, re, im);

        ret[0].im = 0;
        ret[n] = complex(im[0], 0); 

        foreach(i; 1 .. n)
        {
            ret[2 * n - i].re = ret[i].re;
            ret[2 * n - i].im = -ret[i].im;
        }
    }

    private Complex!(T)[] fftTemplate(bool inverse, T, R)(R r) 
    {
        auto ret = allocate!(Complex!T)(numberOfElements(r));
        fftTemplate!inverse(r, ret);
        return ret;
    }

/**
Computes  the discrete fourier transform of data in r  and returns it. Data in
r isn't changed. $(D R) must be a forward range or a range with a length property.
It must have complex or floating point elements. Here a complex type is a type
with assignable floating point properties $(D re) and $(D im). The number of elements
in r must be a power of two. $(D T) must be a floating point type. The length
of the returned array is the same as the number of elements in r.
 */
    Complex!(T)[] fft(T, R)(R r) if(isComplex!(ElementType!R)) 
    {
        return fftTemplate!(false, T)(r);
    }

    Complex!(T)[] fft(T, R)(R r) if(isFloatingPoint!(ElementType!R)) 
    {
        auto ret = allocate!(Complex!T)(numberOfElements(r));
        fft(r, ret);
        return ret;
    }

/**
Computes  the inverse discrete fourier transform of data in r  and returns it. 
Data in r isn't changed.  $(D R) must be a forward range or a range with a
length property. It must have complex or floating point elements. Here a complex
type is a type with assignable floating point properties $(D re) and $(D im). The number
of elements in r must be a power of two. T must be a floating point
type. The length of the returned array is the same as the number of elements in
r.
 */
    Complex!(T)[] inverseFft(T, R)(R r)
    {
        return fftTemplate!true(r);
    }

/**
Computes the inverse discrete fourier transform of data in r and stores the 
result in the user provided buffer ret. Data in r isn't changed. R must be a 
forward range with complex or floating point elements.Here a complex type is 
a type with assignable properties $(D re) and $(D im). Ret must be an input range with
complex elements. r and ret must have the same number of elements and that
number must be a power of two.
 */ 
    void inverseFft(R, Ret)(R r, Ret ret)
    {
       fftTemplate!true(r, ret); 
    }

/**
Allocates an array of size n aligned appropriately for use as parameters to
$(D fft) methods. Both fft methods will still work correctly even if the 
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
