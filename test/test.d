//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.conv, std.datetime, std.complex, std.getopt, 
    std.random, std.numeric, std.math, std.algorithm, std.range,
    std.exception, std.typetuple, std.string : toUpper;

template st(alias a){ enum st = cast(size_t) a; }

auto gc_aligned_array(A)(size_t n)
{
    import core.memory;
    return (cast(A*)GC.malloc(A.sizeof*n))[0..n];
}

mixin template ElementAccess()
{
    alias T delegate(size_t) Dg;

    void fill(Dg fRe, Dg fIm) 
    {
        foreach(i, _; a)
        {
            a[i].re = fRe(i);
            a[i].im = fIm(i);
        }
    }

    auto inRe(size_t i){ return a[i].re; }
    auto inIm(size_t i){ return a[i].im; }
    auto outRe(size_t i){ return r[i].re; }
    auto outIm(size_t i){ return r[i].im; }
}

mixin template splitElementAccess()
{
    alias T delegate(size_t) Dg;

    void fill(Dg fRe, Dg fIm) 
    {
        foreach(i; 0 .. st!1 << log2n)
        {
            _re[i] = fRe(i);
            _im[i] = fIm(i);
        }
    }

    auto inRe(size_t i){ return _re[i]; }
    auto inIm(size_t i){ return _im[i]; }
    auto outRe(size_t i){ return _re[i]; }
    auto outIm(size_t i){ return _im[i]; }
}

mixin template realElementAccessImpl()
{
    auto timeRe(size_t i){ return data[i]; }
    auto timeIm(size_t i){ return to!T(0); }

    private @property _n(){ return st!1 << log2n; } 

    auto freqRe(size_t i)
    {
        return re(min(i, _n - i));
    }
    
    auto freqIm(size_t i)
    {
        return i < _n / 2 ? im(i) :  -im(_n - i);
    }

    static if(isInverse)
    {
        alias T delegate(size_t) Dg;

        void fill(Dg fRe, Dg fIm) 
        {
            foreach(i; 0 .. _n / 2 + 1)
            {
                re(i) = fRe(i);
                im(i) = (i == 0 || i == _n / 2) ? 0.0 : fIm(i);
            }             
        }

        alias timeRe outRe;
        alias timeIm outIm;
        alias freqRe inRe;
        alias freqIm inIm; 
    }
    else
    {
        alias T delegate(size_t) Dg;

        void fill(Dg fRe, Dg fIm) 
        {
            foreach(i; 0 .. _n)
                data[i] = fRe(i);     
        }
        
        alias timeRe inRe;
        alias timeIm inIm;
        alias freqRe outRe;
        alias freqIm outIm; 
    }
}

mixin template realSplitElementAccess()
{
    private T _first_im = 0;
    private T _last_im = 0; 
    ref re(size_t i){ return data[i]; }
    
    ref im(size_t i)
    {
        auto n = (st!1 << log2n);
 
        return 
            i == 0 ? _first_im : 
            i == n / 2 ? _last_im : data[n / 2 + i];
    }

    mixin realElementAccessImpl!();
}

version(Real)
    alias real T;
else version(Double)
    alias double T;
else
    alias float T;

template ImportDirect()
{
    static if(is(T == real))
        import pfft.impl_real;
    else static if(is(T == double))
        import pfft.impl_double;
    else
        import pfft.impl_float;
}

struct DirectApi(bool isReal, bool isInverse) if(!isReal)
{
    mixin ImportDirect!();
    import core.memory; 

    T[] _re;
    T[] _im;
    Table table;
    int log2n;
    
    this(int _log2n)
    {
        log2n = _log2n;
        _re = gc_aligned_array!T(1 << log2n);
        _im = gc_aligned_array!T(1 << log2n);
        _re[] = 0;
        _im[] = 0;
        table = fft_table(log2n, GC.malloc(table_size_bytes(log2n))); 
    }
    
    void compute()
    {
        static if(isInverse)
            fft(_im.ptr, _re.ptr, log2n, table);
        else 
            fft(_re.ptr, _im.ptr, log2n, table); 
    }
    
    mixin splitElementAccess!();
}

struct DirectApi(bool isReal, bool isInverse) if(isReal)
{
    mixin ImportDirect!();
    import core.memory; 
   
    T[] data;
    ITable itable;
    RTable rtable;
    Table table;
    int log2n;
    
    this(int log2n)
    {
        auto n = st!1 << log2n;
        data = gc_aligned_array!T(n);
        data[] = 0;
    
        this.log2n = log2n;
        itable = interleave_table(log2n, GC.malloc(itable_size_bytes(log2n))); 
        rtable = rfft_table(log2n, GC.malloc(table_size_bytes(log2n))); 
        table = fft_table(log2n - 1, GC.malloc(table_size_bytes(log2n - 1)));
        writeln((cast(T*) rtable)[0 .. n / 2]);
    }
    
    void compute()
    {
        static if(isInverse)
        {
            irfft(data.ptr, data[$ / 2 .. $].ptr, log2n, table, rtable); 
            interleave(data.ptr, log2n, itable);    
        }
        else
        {
            deinterleave(data.ptr, log2n, itable);    
            rfft(data.ptr, data[$ / 2 .. $].ptr, log2n, table, rtable); 
        }
    }
    
    mixin realSplitElementAccess!();
}

struct CApi(bool isReal, bool isInverse)  if(!isReal)
{
    enum suffix = is(T == float) ? "f" : is(T == double) ? "d" : "l";

    import pfft.clib;

    T* _re;
    T* _im;
    mixin("PfftTable" ~ toUpper(suffix) ~ " table;");
    int log2n;
    
    this(int _log2n)
    {
        log2n = _log2n;
        _re = mixin("pfft_allocate_"~suffix)(1 << log2n);
        _im = mixin("pfft_allocate_"~suffix)(1 << log2n);
        _re[0 .. 1 << log2n] = 0;
        _im[0 .. 1 << log2n] = 0;
        table = mixin("pfft_table_"~suffix)(1 << log2n, null); 
    }

    ~this()
    {
        mixin("pfft_table_free_"~suffix)(table);
        mixin("pfft_free_"~suffix)(_re);
        mixin("pfft_free_"~suffix)(_im);
    }
    
    void compute()
    {
        static if(isInverse)
            mixin("pfft_ifft_"~suffix)(_re, _im, table);
        else 
            mixin("pfft_fft_"~suffix)(_re, _im, table);
    }
    
    mixin splitElementAccess!();
}

struct CApi(bool isReal, bool isInverse) if(isReal)
{
    enum suffix = is(T == float) ? "f" : is(T == double) ? "d" : "l";
    
    import pfft.clib;
   
    int log2n;
    mixin("PfftRTable" ~ toUpper(suffix) ~ " table;");
    T* data;
    
    this(int log2n)
    {
        this.log2n = log2n;
        data = mixin("pfft_allocate_"~suffix)(1 << log2n);
        data[0 .. 1 << log2n] = 0;
        table = mixin("pfft_rtable_"~suffix)(1 << log2n, null); 
    }
    
    ~this()
    {
        mixin("pfft_rtable_free_"~suffix)(table);
        mixin("pfft_free_"~suffix)(data);
    }
    
    void compute()
    {
        static if(isInverse)
            mixin("pfft_irfft_"~suffix)(data, table);
        else 
            mixin("pfft_rfft_"~suffix)(data, table);
    }
    
    mixin realSplitElementAccess!();
}


struct PfftApi(bool isReal, bool isInverse) if(!isReal)
{
    import pfft.pfft;
   
    alias Fft!T F; 
    F f;
    T[] _re;
    T[] _im;
    int log2n;
    
    this(int log2n)
    {
        this.log2n = log2n;
        size_t n = 1U << log2n; 
        f = new F(n);
        _re = F.allocate(n);
        _im = F.allocate(n);
        _re[] = 0;
        _im[] = 0;
    }
    
    void compute()
    {
        static if(isInverse)
            f.fft(_im, _re);
        else
            f.fft(_re, _im); 
    }
    
    mixin splitElementAccess!();
}

struct PfftApi(bool isReal, bool isInverse) if(isReal)
{
    import pfft.pfft;
   
    alias Rfft!(T) F;
    int log2n;
    F f;
    T[] data;
    
    this(int log2n)
    {
        this.log2n = log2n;
        size_t n = 1U << log2n; 
        f = new F(n);
        data = F.allocate(n);
        data[] = 0;
    }
    
    void compute()
    {
        static if(isInverse)
            f.irfft(data);
        else 
            f.rfft(data);
    }
    
    mixin realSplitElementAccess!();
}

struct SimpleFft(T, bool isInverse)
{    
    Complex!(T)[] a;
    Complex!(T)[] w;
    int log2n;
    
    static void bit_reverse(int log2n, Complex!(T)[] a)
    {
        import core.bitop;

        int mask = (0xffffffff<<(log2n));
        uint i2 = ~mask; 

        for(auto i1 = i2; i1 != (0U - 1U); i1--)
        {
            if(i1 < i2)
                swap(a[i1], a[i2]);
            i2 = mask ^ (i2 ^ (mask>>(bsf(i1)+1)));
        }
    }

    this(int _log2n)
    {
        log2n = _log2n;
        
        a = gc_aligned_array!(Complex!T)(st!1 << log2n);
        a[] = Complex!T(0, 0);
        w = gc_aligned_array!(Complex!T)(st!1 << (log2n - 1));

        size_t n = 1 << log2n;
        T dphi = 4.0 * asin(to!T(1.0)) / n;
        for(size_t i=0; i< n/2; i++)
        {
            w[i].re = cos(dphi * i);
            w[i].im = -sin(dphi * i);
        }

        if(log2n != 0)
            bit_reverse(log2n - 1, w[0 .. n / 2]);
    }
    
    void compute()
    {
        static if(isInverse)
            foreach(ref e; a)
                swap(e.re, e.im);

        for (size_t m2 = (st!1 << log2n) / 2; m2; m2 >>= 1)
        {
            auto table = w.ptr;
            size_t m = m2 + m2;
            for(auto p = a.ptr; p < a.ptr + (st!1 << log2n); p += m )
            {
                T wr = table[0].re;
                T wi = table[0].im;
                table++;
                for (size_t k1 = 0, k2 = m2; k1<m2; k1++, k2++) 
                { 
                    T tmpr = p[k2].re, ti = p[k2].im;
                    T ur = p[k1].re, ui = p[k1].im;
                    T tr = tmpr*wr - ti*wi;
                    ti = tmpr*wi + ti*wr;
                    p[k2].re = ur - tr;
                    p[k1].re = ur + tr;                                                    
                    p[k2].im = ui - ti;                                                    
                    p[k1].im = ui + ti;
                }
            }
        }
        bit_reverse(log2n, a);

        
        static if(isInverse)
            foreach(ref e; a)
                swap(e.re, e.im);
    }
    
    alias T delegate(size_t) Dg;

    void fill(Dg fRe, Dg fIm) 
    {
        foreach(i, _; a)
        {
            a[i].re = fRe(i);
            a[i].im = fIm(i);
        }
    }

    auto inRe(size_t i){ return a[i].re; }
    auto inIm(size_t i){ return a[i].im; }
    auto outRe(size_t i){ return a[i].re; }
    auto outIm(size_t i){ return a[i].im; }
}

auto toComplex(T a){ return complex(a, cast(T) 0); }

struct StdApi(bool usePhobos = false, bool isReal, bool isInverse)
{
    static if(usePhobos)
        import std.numeric;
    else
        import pfft.stdapi;
       
    enum{ normalizedInverse };
 
    static if(isReal)
        T[] a;
    else
        Complex!(T)[] a;
        
    Complex!(T)[] r;
    
    Fft fft;
    
    this(int log2n)
    {
        a = gc_aligned_array!(typeof(a[0]))(st!1 << log2n);
        r = gc_aligned_array!(Complex!T)(st!1 << log2n);

        static if(isReal)
            a[] = cast(T) 0;
        else
            a[] = Complex!T(0, 0);
        
        fft = new Fft(st!1 << log2n);
    }
    
    void compute()
    { 
        static if(isInverse)
        {
            static if(usePhobos && isReal)
            {
                fft.inverseFft(map!toComplex(a), r);
            }
            else 
                fft.inverseFft(a, r); 
        }
        else 
            fft.fft(a, r); 
    }
    
    static if(isReal)
    {
        alias T delegate(size_t) Dg;

        void fill(Dg fRe, Dg fIm) 
        {
            foreach(i, _; a)
                a[i] = fRe(i);
        }

        auto inRe(size_t i){ return a[i]; }
        auto inIm(size_t i){ return to!T(0); }
        auto outRe(size_t i){ return r[i].re; }
        auto outIm(size_t i){ return r[i].im; }
    }
    else
        mixin ElementAccess!();
}

version(BenchFftw)
{
    static if(is(T == float))
    {
        pragma (msg, "Using FFTW - you should link to libfftw3f.a. Note that the resulting binary will be covered by the GPL (see FFTW license).");
        
        extern(C) void* fftwf_malloc(size_t);
        extern(C) void* fftwf_plan_dft_1d(int, Complex!(float)*, Complex!(float)*, int, uint);
        extern(C) void* fftwf_plan_dft_r2c_1d(int, float*, Complex!(float)*, uint);
        extern(C) void* fftwf_plan_dft_c2r_1d(int, Complex!(float)*, float*, uint);
        extern(C) void fftwf_execute(void *);
        
        alias fftwf_malloc fftw_malloc;
        alias fftwf_plan_dft_1d fftw_plan_dft_1d;
        alias fftwf_plan_dft_r2c_1d fftw_plan_dft_r2c_1d;
        alias fftwf_plan_dft_c2r_1d fftw_plan_dft_c2r_1d;
        alias fftwf_execute fftw_execute;
    }
    else static if(is(T == double))
    {
        pragma (msg, "Using FFTW - you should link to libfftw3.a. Note that the resulting binary will be covered by the GPL (see FFTW license).");
        
        extern(C) void* fftw_malloc(size_t);
        extern(C) void* fftw_plan_dft_1d(int, Complex!(double)*, Complex!(double)*, int, uint);
        extern(C) void* fftw_plan_dft_r2c_1d(int, double*, Complex!(double)*, uint);
        extern(C) void* fftw_plan_dft_c2r_1d(int, Complex!(double)*, double*, uint);
        extern(C) void fftw_execute(void *);
    }
    else
    {
        pragma (msg, "Using FFTW - you should link to libfftw3q.a. Note that the resulting binary will be covered by the GPL (see FFTW license).");
        
        extern(C) void* fftwl_malloc(size_t);
        extern(C) void* fftwl_plan_dft_1d(int, Complex!(real)*, Complex!(real)*, int, uint);
        extern(C) void* fftwl_plan_dft_r2c_1d(int, real*, Complex!(real)*, uint);
        extern(C) void* fftwl_plan_dft_c2r_1d(int, Complex!(real)*, real*, uint);
        extern(C) void fftwl_execute(void *);
        
        alias fftwl_malloc fftw_malloc;
        alias fftwl_plan_dft_1d fftw_plan_dft_1d;
        alias fftwl_plan_dft_r2c_1d fftw_plan_dft_r2c_1d;
        alias fftwl_plan_dft_c2r_1d fftw_plan_dft_c2r_1d;
        alias fftwl_execute fftw_execute;
    }

    
    auto fftw_array(A)(size_t n)
    {
        import core.memory;
        return (cast(A*)fftw_malloc(A.sizeof*n))[0..n];
    }

    enum FFTW_FORWARD = -1;
    enum FFTW_BACKWARD = 1;
    enum FFTW_ESTIMATE = 1U << 6;
    enum FFTW_MEASURE = 0U;
    enum FFTW_PATIENT = 1U << 5;

    struct FFTW(bool isReal, bool isInverse, int flags) if(!isReal)
    {        
        Complex!(T)[] a;
        Complex!(T)[] r;
        
        void* p;
        
        this(int log2n)
        {
            auto n = st!1 << log2n;
            a = fftw_array!(Complex!T)(n);
            a[] = Complex!T(0, 0);
            r = fftw_array!(Complex!T)(n);
            auto dir = isInverse ? FFTW_BACKWARD : FFTW_FORWARD;
            p = fftw_plan_dft_1d(1 << log2n, a.ptr, r.ptr, dir, flags);
        }
        
        void compute(){ fftw_execute(p); }
        
        mixin ElementAccess!();
    }

    struct FFTW(bool isReal, bool isInverse, int flags) if(isReal)
    {        
        T[] a;
        Complex!(T)[] r;
        void* p;
        int log2n;
        
        this(int log2n)
        {
            this.log2n = log2n;
            auto n = st!1 << log2n;
            a = fftw_array!T(n);
            a[] = 0;
            r = fftw_array!(Complex!T)(n / 2 + 1);
            
            static if(isInverse)
                p = fftw_plan_dft_c2r_1d(to!int(n), r.ptr, a.ptr, flags);
            else
                p = fftw_plan_dft_r2c_1d(to!int(n), a.ptr, r.ptr, flags);
        }
        
        void compute(){ fftw_execute(p); }
        
        ref re(size_t i){ return r[i].re; }
        ref im(size_t i){ return r[i].im; }
        
        alias a data;
        mixin realElementAccessImpl!();
    }
}

void speed(F, bool isReal, bool isInverse)(int log2n, long flops)
{    
    auto f = F(log2n);
   
    auto zero = delegate(size_t i){ return to!(typeof(F.init.inRe(0)))(0); };
 
    f.fill(zero, zero);

    ulong flopsPerIter = 5UL * log2n * (1UL << log2n) / (isReal ? 2 : 1); 
    ulong niter = flops / flopsPerIter;
    niter = niter ? niter : 1;
        
    StopWatch sw;
    sw.start();
    
    foreach(i; 0 .. niter)
        f.compute();
    
    sw.stop();
    writefln("%f", to!double(niter * flopsPerIter) / sw.peek().nsecs());
}

void initialization(F, bool isReal, bool isInverse)(int log2n, long flops)
{    
    auto niter = 100_000_000 / (1 << log2n);
    niter = niter ? niter : 1;

    StopWatch sw;
    sw.start();
    
    foreach(i; 0 .. niter)
    {
        auto f = F(log2n);
        f.compute();
    }
    
    sw.stop();
    writefln("%.3e", sw.peek().nsecs() * 1e-9 / niter);
}

void precision(F, bool isReal, bool isInverse)(int log2n, long flops)
{
    alias SimpleFft!(real, isInverse) S;
    alias typeof(S.init.inRe(0)) ST;
    alias typeof(F.init.inRe(0)) FT;

    auto n = st!1 << log2n;
    auto tested = F(log2n);
    auto simple = S(log2n);
    
    rndGen.seed(1);
    auto rnd = delegate(size_t i){ return to!FT(uniform(0.0, 1.0)); };
    tested.fill(rnd, rnd);
    auto re = (size_t a){ return cast(ST) tested.inRe(a); };
    auto im = (size_t a){ return cast(ST) tested.inIm(a); };
    simple.fill(re, im);
    
    writeln();

    simple.compute();
    tested.compute();
    
    
    real sumSqDiff = 0.0;
    real sumSqAvg = 0.0;
    
    foreach(i; 0 .. n)
    {
        auto tre = tested.outRe(i);
        auto tim = tested.outIm(i);

        auto sre = simple.outRe(i);
        auto sim = simple.outIm(i);

        static if(isInverse &&  is(typeof(F.normalizedInverse)))
        {
            sre /= n;
            sim /= n;
        }        

        //writefln("%.2e\t%.2e\t%.2e\t%.2e\t%.2e\t%.2e", sre, tre, sim, tim, 0.0, sim - tim);
        
        sumSqDiff += (sre - tre) ^^ 2 + (sim - tim) ^^ 2; 
        sumSqAvg += (0.5 * (sre + tre)) ^^ 2 + (0.5 * (sim + tim)) ^^ 2; 
    }
    writeln(std.math.sqrt(sumSqDiff / sumSqAvg));
}

void runTest(bool testSpeed, bool isReal, bool isInverse)(int log2n, string impl, long mflops)
{
    static if(testSpeed)
        alias speed f;
    else
        alias precision f;

    long flops = mflops * 1000_000;
   
    if(impl == "simple")
        return f!(SimpleFft!(T, isInverse), isReal, isInverse)(log2n, flops);
    if(impl == "direct")
        return f!(DirectApi!(isReal, isInverse), isReal, isInverse)(log2n, flops);
    if(impl == "std")
        return f!(StdApi!(false, isReal, isInverse), isReal, isInverse)(log2n, flops);
    if(impl == "phobos")
        return f!(StdApi!(true, isReal, isInverse), isReal, isInverse)(log2n, flops);
    if(impl == "pfft")
        return f!(PfftApi!(isReal, isInverse), isReal, isInverse)(log2n, flops);
    
    version(BenchFftw)
    {
        if(impl == "fftw")
            return f!(FFTW!(isReal, isInverse, FFTW_PATIENT), isReal, isInverse)(
                    log2n, flops);
        if(impl == "fftw-measure")
            return f!(FFTW!(isReal, isInverse, FFTW_MEASURE), isReal, isInverse)(
                    log2n, flops);
    }

    version(BenchClib)
        if(impl == "c")
            return f!(CApi!(isReal, isInverse), isReal, isInverse)(log2n, flops);
    
    throw new Exception(
            "Implementation \"" ~ impl ~ "\" is not supported" );
}

template Group(A...){ alias A Members; }

auto callInstance(alias f, int n, alias FParams = Group!(), Params...)(Params params)
{
    foreach(e; TypeTuple!(true, false))
        if(e == params[0])
        {
            static if(n == 1)
                return f!(FParams.Members, e)(params[1 .. $]);
            else
                return callInstance!
                    (f, n - 1, Group!(FParams.Members, e))
                    (params[1 .. $]);
        }
}

enum usage =
"
Usage: %s [options] implementation log2n.
Test program for pfft. It tests precision or, if -s option is used, speed of
different interfaces to pfft and a few other fft implementations. log2n is
the base 2 logarithm of the number of data points the fft will be tested on.
implementation is a fft implementation that will be tested. Valid values
of this parameter are listed below. 

If the -s option is not used, the program will choose some random data and 
perform fft on it twice - once using the chosen implementation and once using 
a simple Cooley Tukey implementation that operates on extended precision 
floating point numbers. It will then compute the sum of squares of the 
difference of the two results and the sum of squares of the average of the 
two results and print the square root of the quotient of the two sums.

If the -s option is used the program will compute fft a number of times, time 
it and report the speed in billions of floating point operations per second. 
This is not the number of actual floating point operations performed by the 
implementation - instead it is defined as the number of operations a basic
Cooley Tukey implementation would need to perform to calculate the fft of
the given size. For complex transforms that is:

Nop = 5 * N * log2(N)

and for real transforms it is:

Nop = 2.5 * N * log2(N)


Implementations:
  simple            A simple Cooley Tukey implementation that is used 
                    internally for testing the precision of other 
                    implementations.
  direct            A direct interface to pfft (modules pfft.*_impl).
  pfft              The recommended interface to pfft (module pfft.pfft).
  std               An interface to pfft that mimics the API of 
                    std.numeric.Fft.(module pfft.stdapi).
  c                 An interface to pfft usable from c.
  phobos            Phobos implementation of fft (std.numeric.Fft).
  fftw              FFTW implementation. This one is only available
                    if the test program was compiled with -version=BenchFftw.
  fftw-measure      Same as the above, but using FFTW_MEASURE flag instead
                    of FFTW_PATIENT.

Options:
  -s                Test speed instead of precision.
  -r                Test real fft instead of a complex one
  -i                Test inverse fft.
  -m M              Choose the number of times to run fft so that the total
                    number of floating point operations (as defined above)
                    will be as close to M * 10e6 as possible. If the number
                    of floating point operations taken by one execution of fft
                    is larger than M * 10e6, do one fft. The default value of 
                    this parameter is 10000.
  -h, --help        Print this message to stdout and exit.
";
 
void main(string[] args)
{
    try
    {
        bool s;
        bool r;
        bool i;
        bool h;
        int mflops = 10_000;

        getopt(
            args, 
            "s", &s, 
            "r", &r, 
            "i", &i, 
            "m", &mflops,
            "h|help", &h);

        if(h)
        {
            writefln(usage, args[0]);
            return;
        }

        enforce(args.length == 3, "There must be exactly two non option arguments.");

        callInstance!(runTest, 3)(s, r, i, to!int(args[2]), args[1], mflops);
        //runTest!(true, false, false)(args, mflops);
    }
    catch(Exception e)
    {
        auto s = findSplit(to!string(e), "---")[0];
        stderr.writefln("Exception was thrown: %s", s);
        stderr.writefln(usage, args[0]); 
    }
}
