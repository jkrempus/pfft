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
use split format for complex data. This means that a complex data set is 
represented as two arrays - one for the real part and one for the imaginary
part. An instance of this class can only be used for transforms of one 
particular size. The template parameter is the floating point type that the 
methods of the class will operate on.

Example:
---
import std.stdio, std.conv, std.exception;
import pfft.pfft;

void main(string[] args)
{
    auto n = to!int(args[1]);
    enforce((n & (n-1)) == 0, "N must be a power of two.");
    
    alias Fft!float F;

    auto f = new F(n);

    auto re = F.Array(n);
    auto im = F.Array(n);

    foreach(i, _; re)
        readf("%s %s\n", &re[i], &im[i]);

    f.fft(re, im);

    foreach(i, _; re)
        writefln("%s\t%s", re[i], im[i]);
}
--- 
 */
final class Fft(T)
{
    mixin Import!T;

    uint log2size;
    impl.MultidimTable table;

/**
A struct that wraps an array of T. The reason behind this struct is
to ensure that the array will always be aligned properly for use with 
other functions in this class. The memory layout of this struct is 
identical to T[].
 */
    struct Array
    {
        private T[] _data;

        ///
        @property data(){ return _data; }
        /// 
        alias data this;
    
        @disable this(); 

        ///
        auto this(size_t n)
        {
            auto p = cast(T*) GC.malloc(n * T.sizeof);
            assert(((impl.alignment(n) - 1) & cast(size_t) p) == 0);
            _data = p[0 .. n];
        }
    }

/**
The Fft constructor. The parameter is the size of data sets that $(D fft) and
$(D ifft) will operate on. I will refer to this number as n in the rest of the 
documentation for this class.Tables used in fft and ifft are calculated in the 
constructor.
 */
    this(size_t[] n...)
    {
        auto log2n = new uint[n.length];
        log2size = 0;
        foreach(i; 0 .. log2n.length)
        {
            assert((n[i] & (n[i] - 1)) == 0);
            log2n[i] = bsf(n[i]);
            log2size += log2n[i];
        }

        auto size = impl.multidim_fft_table_size(log2n);
        table = impl.multidim_fft_table(log2n, GC.malloc(size));
    }

/**
Calculates discrete fourier transform. $(D_PARAM re) should contain the real
part of the data and $(D_PARAM im) the imaginary part of the data. The method
operates in place - the result is saved back to $(D_PARAM re) and $(D_PARAM im).
 */  
    void fft(Array re, Array im)
    {
        assert(re.length == im.length); 
        assert(re.length == (st!1 << log2size));
       
        impl.multidim_fft(re.ptr, im.ptr, table); 
    }

/**
Calculates inverse discrete fourier transform scaled by n. The arguments have
the same role as they do in $(D fft).
 */  
    void ifft(Array re, Array im)
    {
        fft(im, re); 
    }

/**
Scales an array data by factor k.
 */
    static void scale(Array data, T k)
    {
        impl.scale(data.ptr, data.length, k);
    }

}

/**
A class for calculating real discrete fourier transform. The methods of this 
class use split format for complex data. This means that complex data set is 
represented as two arrays - one for the real part and one for the imaginary
part. An instance of this class can only be used for transforms of one 
particular size. The template parameter is the floating point type that the 
methods of the class will operate on.

Example:
---
import std.stdio, std.conv, std.exception;
import pfft.pfft;

void main(string[] args)
{
    auto n = to!int(args[1]);
    enforce((n & (n-1)) == 0, "N must be a power of two.");
    
    alias Rfft!float F;

    auto f = new F(n);

    auto data = F.Array(n);

    foreach(ref e; data)
        readf("%s\n", &e);

    f.rfft(data);

    foreach(i; 0 .. n / 2 + 1)
        writefln("%s\t%s", data[i], (i == 0 || i == n / 2) ? 0 : data[i]);
}
---
 */
final class Rfft(T)
{
    mixin Import!T;

    size_t array_size;
    impl.RealMultidimTable table;
//    impl.RTable rtable;
//    impl.ITable itable;

/// An alias for Fft!T.Array
    alias Fft!(T).Array Array;

/**
The Rfft constructor. The parameter is the size of data sets that $(D rfft) will 
operate on. I will refer to this number as n in the rest of the documentation
for this class. All tables used in rfft are calculated in the constructor.
 */
    this(size_t[] n ...)
    {
        auto log2n = new uint[n.length];
        size_t log2size = 0;
        foreach(i; 0 .. log2n.length)
        {
            assert((n[i] & (n[i] - 1)) == 0);
            log2n[i] = bsf(n[i]);
            log2size += log2n[i];
        }

        array_size = (st!1 << log2size) + (st!2 << (log2size - log2n[0]));

        log2n[0]--;

        auto size = impl.multidim_rfft_table_size(log2n);
        table = impl.multidim_rfft_table(log2n, GC.malloc(size));
    }

/**
Calculates discrete fourier transform of the real valued sequence in data. 
The method operates in place. When the method completes, data contains the
result. First $(I n / 2 + 1) elements contain the real part of the result and 
the rest contains the imaginary part. Imaginary parts at position 0 and 
$(I n / 2) are known to be equal to 0 and are not stored, so the content of 
data looks like this: 

 $(D r(0), r(1), ... r(n / 2), i(1), i(2), ... i(n / 2 - 1))  


The elements of the result at position greater than n / 2 can be trivially 
calculated from the relation $(I DFT(f)[i] = DFT(f)[n - i]*) that holds 
because the input sequence is real. 


The length of the array must be equal to n.
 */  
    void rfft(Array data)
    {
        assert(data.length == array_size);
        impl.multidim_rfft(data.ptr, table);
    }

/**
Calculates the inverse of $(D rfft), scaled by n (You can use $(D scale)
to normalize the result). Before the method is called, data should contain a 
complex sequence in the same format as the result of $(D rfft). It is 
assumed that the input sequence is a discrete fourier transform of a real 
valued sequence, so the elements of the input sequence not stored in data 
can be calculated from $(I DFT(f)[i] = DFT(f)[n - i]*). When the method
completes, the array contains the real part of the inverse discrete fourier 
transform. The imaginary part is known to be equal to 0.

The length of the array must be equal to n.
 */
    void irfft(Array data)
    {
        assert(data.length == array_size);
        impl.multidim_irfft(data.ptr, table);
    }

/// An alias for Fft!T.scale
    alias Fft!(T).scale scale;
     
//    @property complex(){ return _complex; }
}
