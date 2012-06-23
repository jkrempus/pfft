//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.conv, std.datetime, std.complex, std.getopt, 
    std.random, std.numeric, std.math, std.algorithm, std.exception, std.typetuple;

template st(alias a){ enum st = cast(size_t) a; }

auto gc_aligned_array(A)(size_t n)
{
    import core.memory;
    return (cast(A*)GC.malloc(A.sizeof*n))[0..n];
}

template splitElementAccess(alias _re, alias _ri)
{
    ref re(size_t i){ return _re[i]; }
    ref im(size_t i){ return _ri[i]; }
    ref result_re(size_t i){ return _re[i]; }
    ref result_im(size_t i){ return _ri[i]; }
}

template realSplitElementAccess(alias data, alias _re, alias _ri)
{
    ref re(size_t i){ return data[i]; }

    auto result_re(size_t i)
    { 
        return i == _re.length ? _im[0] : _re[i]; 
    }
    
    T result_im(size_t i)
    { 
        return i == 0 ? 0.0 : i >= _im.length ?  0.0 : _im[i]; 
    }
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
        table = fft_table(log2n, GC.malloc(table_size_bytes(log2n))); 
    }
    
    void compute()
    {
        static if(isInverse)
            fft(_im.ptr, _re.ptr, log2n, table);
        else 
            fft(_re.ptr, _im.ptr, log2n, table); 
    }
    
    mixin splitElementAccess!(_re, _im);
}

struct DirectApi(bool isReal, bool isInverse) if(isReal)
{
    mixin ImportDirect!();
    import core.memory; 
   
    T[] data;
    RTable rtable;
    int log2n;
    DirectApi!(false, isInverse) c;
    T[] _re;
    T[] _im;
    
    this(int log2n)
    {
        c = typeof(c)(log2n - 1);
        _re = c._re;
        _im = c._im;

        data = gc_aligned_array!T(1 << log2n);

        this.log2n = log2n;
        rtable = rfft_table(log2n, GC.malloc(table_size_bytes(log2n))); 
    }
    
    void compute()
    {
        static if(isInverse)
            enforce(0, "Direct api does not currently support real inverse transform."); 
        
        deinterleaveArray(data.ptr, _re.ptr, _im.ptr, st!1 << (log2n - 1));
        rfft(_re.ptr, _im.ptr, log2n, c.table, rtable); 
    }
    
    mixin realSplitElementAccess!(data, _re, _im);
}

struct PfftApi(bool isReal, bool isInverse) if(!isReal)
{
    import pfft.pfft;
   
    alias Fft!T F; 
    F f;
    T[] _re;
    T[] _im;
    
    this(int log2n)
    {
        size_t n = 1U << log2n; 
        f = new F(n);
        _re = F.allocate(n);
        _im = F.allocate(n);
    }
    
    void compute()
    {
        static if(isInverse)
            f.fft(_im, _re);
        else
            f.fft(_re, _im); 
    }
    
    mixin splitElementAccess!(_re, _im);
}

struct PfftApi(bool isReal, bool isInverse) if(isReal)
{
    import pfft.pfft;
   
    alias Rfft!T F;
    F f;
    T[] _re;
    T[] _im;
    T[] data;
    
    this(int log2n)
    {
        size_t n = 1U << log2n; 
        f = new F(n);
        _re = F.allocate(n / 2);
        _im = F.allocate(n / 2);
        data = F.allocate(n);
    }
    
    void compute()
    {
        static if(isInverse)
            enforce(0, "Pfft api does not currently support real inverse transform."); 
        
        f.rfft(data, _re, _im);
    }
    
    mixin realSplitElementAccess!(data, _re, _im);
}

template ElementAccess(alias a, alias r)
{
    ref re(size_t i){ return a[i].re; }
    ref im(size_t i){ return a[i].im; }
    ref result_re(size_t i){ return r[i].re; }
    ref result_im(size_t i){ return r[i].im; }
}

enum one = to!size_t(1);

struct SimpleFft(T, bool isInverse)
{    
    Complex!(T)[] a;
    Complex!(T)[] w;
    int log2n;
    enum one = cast(size_t)1;
    
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
        
        a = gc_aligned_array!(Complex!T)(one << log2n);
        a[] = Complex!T(0, 0);
        w = gc_aligned_array!(Complex!T)(one << (log2n - 1));

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

        for (size_t m2 = (one << log2n) / 2; m2; m2 >>= 1)
        {
            auto table = w.ptr;
            size_t m = m2 + m2;
            for(auto p = a.ptr; p < a.ptr + (one << log2n); p += m )
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
    
    ref re(size_t i){ return a[i].re; }
    ref im(size_t i){ return a[i].im; }
    ref result_re(size_t i){ return a[i].re; }
    ref result_im(size_t i){ return a[i].im; }
}

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
        a = gc_aligned_array!(typeof(a[0]))(one << log2n);
        r = gc_aligned_array!(Complex!T)(one << log2n);

        static if(isReal)
            a[] = cast(T) 0;
        else
            a[] = Complex!T(0, 0);
        
        fft = new Fft(one << log2n);
    }
    
    void compute()
    { 
        static if(isInverse)
        {
            static if(usePhobos && isReal)
                enforce(0, "TODO");
            else 
                fft.inverseFft(a, r); 
        }
        else 
            fft.fft(a, r); 
    }
    
    static if(isReal)
    {
        @property ref re(size_t i){ return a[i]; }
        @property ref result_re(size_t i){ return r[i].re; }
        @property ref result_im(size_t i){ return r[i].im; }
    }
    else
        mixin ElementAccess!(a, r);
}

version(BenchFftw)
{
    static if(is(T == float))
    {
        pragma (msg, "Using FFTW - you should link to libfftw3f.a. Note that the resulting binary will be covered by the GPL (see FFTW license).");
        
        extern(C) void* fftwf_malloc(size_t);
        extern(C) void* fftwf_plan_dft_1d(int, Complex!(float)*, Complex!(float)*, int, uint);
        extern(C) void* fftwf_plan_dft_r2c_1d(int, float*, Complex!(float)*, uint);
        extern(C) void fftwf_execute(void *);
        
        alias fftwf_malloc fftw_malloc;
        alias fftwf_plan_dft_1d fftw_plan_dft_1d;
        alias fftwf_plan_dft_r2c_1d fftw_plan_dft_r2c_1d;
        alias fftwf_execute fftw_execute;
    }
    else static if(is(T == double))
    {
        pragma (msg, "Using FFTW - you should link to libfftw3.a. Note that the resulting binary will be covered by the GPL (see FFTW license).");
        
        extern(C) void* fftw_malloc(size_t);
        extern(C) void* fftw_plan_dft_1d(int, Complex!(double)*, Complex!(double)*, int, uint);
        extern(C) void* fftw_plan_dft_r2c_1d(int, double*, Complex!(double)*, uint);
        extern(C) void fftw_execute(void *);
    }
    else
    {
        pragma (msg, "Using FFTW - you should link to libfftw3q.a. Note that the resulting binary will be covered by the GPL (see FFTW license).");
        
        extern(C) void* fftwl_malloc(size_t);
        extern(C) void* fftwl_plan_dft_1d(int, Complex!(real)*, Complex!(real)*, int, uint);
        extern(C) void* fftwl_plan_dft_r2c_1d(int, real*, Complex!(real)*, uint);
        extern(C) void fftwl_execute(void *);
        
        alias fftwl_malloc fftw_malloc;
        alias fftwl_plan_dft_1d fftw_plan_dft_1d;
        alias fftwl_plan_dft_r2c_1d fftw_plan_dft_r2c_1d;
        alias fftwl_execute fftw_execute;
    }

    enum FFTW_FORWARD = -1;
    enum FFTW_BACKWARD = 1;
    enum FFTW_ESTIMATE = 1U << 6;
    enum FFTW_MEASURE = 0U;
    enum FFTW_PATIENT = 1U << 5;

    struct FFTW(bool isReal, bool isInverse) if(!isReal)
    {        
        Complex!(T)* a;
        Complex!(T)* r;
        
        void* p;
        
        this(int log2n)
        {
            a = cast(Complex!(T)*) fftw_malloc(Complex!(T).sizeof * 1L << log2n);
            a[0 .. st!1 << log2n] = Complex!T(0, 0);
            r = cast(Complex!(T)*) fftw_malloc(Complex!(T).sizeof * 1L << log2n);
            auto dir = isInverse ? FFTW_BACKWARD : FFTW_FORWARD;
            p = fftw_plan_dft_1d(1 << log2n, a, r, dir, FFTW_PATIENT);
        }
        
        void compute(){ fftw_execute(p); }
        
        mixin ElementAccess!(a, r);
    }

    struct FFTW(bool isReal, bool isInverse) if(isReal)
    {        
        T* a;
        Complex!(T)* r;
        
        void* p;
        
        this(int log2n)
        {
            auto n = st!1 << log2n;
            a = cast(T*) fftw_malloc(T.sizeof *n);
            a[0 .. n] = 0;
            r = cast(Complex!(T)*) fftw_malloc(Complex!(T).sizeof * (n / 2 + 1));
            
            static if(isInverse)
                enforce(0,"Benchmarking inverse real transform for fftw is not supported");                

            p = fftw_plan_dft_r2c_1d(to!int(n), a, r, FFTW_PATIENT);
        }
        
        void compute(){ fftw_execute(p); }
        
        ref re(size_t i){ return a[i]; }
        ref result_re(size_t i){ return r[i].re; }
        ref result_im(size_t i){ return r[i].im; }
    }
}

void bench(F, bool isReal, bool isInverse)(int log2n, long flops)
{    
    auto f = F(log2n);
    
    foreach(i; 0 .. one << log2n)
    {
        f.re(i) = 0.0;
        static if(!isReal)
            f.im(i) = 0.0;
    }

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

auto sq(T)(T a){ return a * a; }

void precision(F, bool isReal, bool isInverse)(int log2n, long flops)
{
    auto tested = F(log2n);
    auto simple = SimpleFft!(real, isInverse)(log2n);
    
    rndGen.seed(1);
    foreach(i; 0 .. 1 << log2n)
    {
        auto re = uniform(0.0,1.0);
        simple.re(i) = re;
        tested.re(i) = re;
        
        static if(!isReal)
        {
            auto im = uniform(0.0,1.0);
            simple.im(i) = im;
            tested.im(i) = im;
        }
    }
    
    simple.compute();
    tested.compute();
    
    
    real sumSqDiff = 0.0;
    real sumSqAvg = 0.0;
    
    foreach(i; 0 .. (1 << log2n) / 2 + 1)
    {
        auto tre = tested.result_re(i);
        auto tim = tested.result_im(i);
        auto sre = simple.result_re(i);
        auto sim = simple.result_im(i);
        
        static if(is(typeof(F.normalizedInverse)))
        {
            sre /= (st!1 << log2n);
            sim /= (st!1 << log2n);
        }        

        sumSqDiff += sq(sre - tre) + sq(sim - tim); 
        sumSqAvg += sq(0.5 * (sre + tre)) + sq(0.5 * (sim + tim)); 
    }
    writeln(std.math.sqrt(sumSqDiff / sumSqAvg));
}

void runTest(bool testSpeed, bool isReal, bool isInverse)(string[] args, long mflops)
{
    static if(testSpeed)
        alias bench f;
    else
        alias precision f;

    int log2n = to!int(args[2]);
    long flops = mflops * 1000_000;
   
    auto a = args[1];
 
    if(a == "simple")
        f!(SimpleFft!(T, isInverse), isReal, isInverse)(log2n, flops);
    else if(a == "direct")
        f!(DirectApi!(isReal, isInverse), isReal, isInverse)(log2n, flops);
    else if(a == "std")
        f!(StdApi!(false, isReal, isInverse), isReal, isInverse)(log2n, flops);
    else if(a == "phobos")
        f!(StdApi!(true, isReal, isInverse), isReal, isInverse)(log2n, flops);
    else if(a == "pfft")
        f!(PfftApi!(isReal, isInverse), isReal, isInverse)(log2n, flops);
    else
    {
        version(BenchFftw)
        {
            if(a == "fftw")
                f!(FFTW!(isReal, isInverse), isReal, isInverse)(log2n, flops);
            else 
                throw new Exception(
                    "Implementation \"" ~ a ~ "\" is not supported" );
        }
        else
            throw new Exception(
                "Implementation \"" ~ a ~ "\" is not supported" );
    }
}

template Group(A...){ alias A Members; }

auto callInstance(alias f, int n, alias FParams = Group!(), Params...)(Params params)
{
    static if(n == 0)
        return f!(FParams.Members)(params);
    else
    {
        foreach(e; TypeTuple!(true, false))
            if(e == params[0])
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
  phobos            Phobos implementation of fft (std.numeric.Fft).
  fftw              FFTW implementation. This one is only available
                    if the test program was compiled with -version=BenchFftw.

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

        getopt(args, 
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

        callInstance!(runTest, 3)(s, r, i, args, mflops);
    }
    catch(Exception e)
    {
        auto s = findSplit(to!string(e), "---")[0];
        stderr.writefln("Exception was thrown: %s", s);
        stderr.writefln(usage, args[0]); 
    }
}
