//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.pfft;
import core.memory, core.bitop, std.array;

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

/**
A class for calculating discrete fourier transform. The methods of this class
use split format for complex data. This means that complex data set is 
represented as two arrays - one for the real part and one for the imaginary
part. An instance of this class can only be used for transforms of one 
particular size. The template parameter is the floating point type that the 
methods of the class will operate on.

Example:
---
alias Fft!float F;

auto n = to!int(args[1]);

enforce((n & (n-1)) == 0, "N must be a power of two.");

auto f = new F(n);

auto re = F.allocate(n);
auto im = F.allocate(n);

foreach(i, _; re)
    readf("%s %s\n", &re[i], &im[i]);

f.fft(re, im);

foreach(i, _; re)
    writefln("%s %s", re[i], im[i]);
--- 
 */
final class Fft(TT)
{
    mixin Import!TT;

    int log2n;
    impl.Table table;
    
/**
The Fft constructor. The parameter is the size of data sets that the fft() and
ifft() will operate on. Tables used in fft and ifft are calculated in the 
constructor.
 */
    this(size_t n)
    {
        assert((n & (n - 1)) == 0);
        log2n  = bsf(n);
        auto mem = GC.malloc( impl.table_size_bytes(log2n));
        table = impl.fft_table(log2n, mem);
    }

/**
Calculates discrete fourier transform. $(D_PARAM re) should contain the real
part of the data and $(D_PARAM im) the imaginary part of the data. The method
operates in place - the result is saved back to $(D_PARAM re) and $(D_PARAM im).
Both arrays must be propperly aligned - to get a properly aligned array you can
use allocate().
 */  
    void fft(impl.T[] re, impl.T[] im)
    {
        assert(re.length == im.length); 
        assert(re.length == (st!1 << log2n));
        assert(((impl.alignment(log2n) - 1) & cast(size_t) re.ptr) == 0);
        assert(((impl.alignment(log2n) - 1) & cast(size_t) im.ptr) == 0);
        
        impl.fft(re.ptr, im.ptr, log2n, table);
    }

/**
Calculates inverse discrete fourier transform scaled by n (where n is the 
length of argument array). The arguments have the same role as they do in fft().
 */  
    void ifft(impl.T[] re, impl.T[] im)
    {
        fft(im, re); 
    }

/**
Allocates an array that is aligned properly for use with fft() and ifft()
methods.
 */
    static TT[] allocate(size_t n)
    {
        auto r = cast(TT*) GC.malloc(n * TT.sizeof);
        assert(((impl.alignment(bsr(n)) - 1) & cast(size_t) r) == 0);
        return r[0 .. n];
    }
}

///
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
        assert(2 * (re.length - 1) == data.length);
        assert(data.length == (st!1 << log2n));
        assert(((impl.alignment(log2n - 1) - 1) & cast(size_t) re.ptr) == 0);
        assert(((impl.alignment(log2n - 1) - 1) & cast(size_t) re.ptr) == 0);
        assert(((impl.alignment(log2n) - 1) & cast(size_t) data.ptr) == 0);
        
        impl.deinterleaveArray(re.ptr, im.ptr, data.ptr, st!1 << (log2n - 1));
        impl.rfft(re.ptr, im.ptr, log2n, _complex.table, rtable);
       
        re.back = im[0];
        im.back = 0;   
        im[0] = 0;
    }

    alias Fft!(TT).allocate allocate;
    
    @property auto complex(){ return _complex; }
}
