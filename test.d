//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.conv, std.datetime, std.complex, std.getopt, 
    std.random, std.numeric, std.math, std.algorithm;

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

version(Double)
    alias double T;
else
    alias float T;

struct DirectApi
{
    static if(is(T == double))
        import pfft.impl_double;
    else
        import pfft.impl_float;
        
    T[] _re;
    T[] _ri;
    Table table;
    int log2n;
    
    this(int _log2n)
    {
        log2n = _log2n;
        _re = gc_aligned_array!T(1 << log2n);
        _ri = gc_aligned_array!T(1 << log2n);
        table = fft_table(log2n);  // will leak memory but we don't care
    }
    
    void compute(){ fft(_re.ptr, _ri.ptr, log2n, table); }
    
    mixin splitElementAccess!(_re, _ri);
}

struct SplitApi
{
    import pfft.splitapi;
    
    SplitFft!T f;
    T[] _re;
    T[] _im;
    
    this(int log2n)
    {
        size_t n = 1U << log2n; 
        f = new SplitFft!T(n);
        _re = gc_aligned_array!T(n);
        _im = gc_aligned_array!T(n);
    }
    
    void compute(){ f.fft(_re, _im); }
    
    mixin splitElementAccess!(_re, _im);
}

template ElementAccess(alias a, alias r)
{
    ref re(size_t i){ return a[i].re; }
    ref im(size_t i){ return a[i].im; }
    ref result_re(size_t i){ return r[i].re; }
    ref result_im(size_t i){ return r[i].im; }
}

enum one = to!size_t(1);

struct SimpleFft(T)
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
        w = gc_aligned_array!(Complex!T)(one << log2n);

        auto p = w;
        for (int s = 1; s <= log2n; ++s)
        {
            size_t m = 1 << s;
            T dphi = 4.0 * asin(to!T(1.0)) / m;
            for(size_t i=0; i< m/2; i++)
            {
                p[i].re = cos(dphi * i);
                p[i].im = -sin(dphi * i);
            }
            bit_reverse(s - 1, p[0 .. m / 2]);
            p = p[m / 2 .. $];
        }
    }
    
    void compute()
    {
        auto table = w.ptr;
        for (size_t m2 = (one << log2n) / 2; m2; m2 >>= 1)
        {
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
    }
    
    ref re(size_t i){ return a[i].re; }
    ref im(size_t i){ return a[i].im; }
    ref result_re(size_t i){ return a[i].re; }
    ref result_im(size_t i){ return a[i].im; }
}

struct StdApi(bool usePhobos = false)
{
    static if(usePhobos)
        import std.numeric;
    else
        import pfft.stdapi;
    
    Complex!(T)[] a;
    Complex!(T)[] r;
    Fft fft;
    
    this(int log2n)
    {
        a = gc_aligned_array!(Complex!T)(one << log2n);
        r = gc_aligned_array!(Complex!T)(one << log2n);
        fft = new Fft(one << log2n);
    }
    
    void compute(){ fft.fft(a, r); }

    mixin ElementAccess!(a, r);
}

version(BenchFftw)
{
    static if(is(T == float))
    {
        pragma (msg, "Using FFTW - you should link to libfftw3f.a. Note that the resulting binary will be covered by GPL (see FFTW license).");
        
        extern(C) void* fftwf_malloc(size_t);
        extern(C) void* fftwf_plan_dft_1d(int, Complex!(float)*, Complex!(float)*, int, uint);
        extern(C) void fftwf_execute(void *);
        
        alias fftwf_malloc fftw_malloc;
        alias fftwf_plan_dft_1d fftw_plan_dft_1d;
        alias fftwf_execute fftw_execute;
    }
    else
    {
        pragma (msg, "Using FFTW - you should link to libfftw3.a. Note that the resulting binary will be covered by GPL (see FFTW license).");
        
        extern(C) void* fftw_malloc(size_t);
        extern(C) void* fftw_plan_dft_1d(int, Complex!(double)*, Complex!(double)*, int, uint);
        extern(C) void fftw_execute(void *);
    }

    enum FFTW_FORWARD = -1;
    enum FFTW_ESTIMATE = 1U << 6;
    enum FFTW_MEASURE = 0U;
    enum FFTW_PATIENT = 1U << 5;

    struct FFTW
    {        
        Complex!(T)* a;
        Complex!(T)* r;
        
        void* p;
        
        this(int log2n)
        {
            a = cast(Complex!(T)*) fftw_malloc(Complex!(T).sizeof * 1L << log2n);
            r = cast(Complex!(T)*) fftw_malloc(Complex!(T).sizeof * 1L << log2n);
            p = fftw_plan_dft_1d(1 << log2n, a, r, FFTW_FORWARD, FFTW_MEASURE);
        }
        
        void compute(){ fftw_execute(p); }
        
        mixin ElementAccess!(a, r);
    }
}

void bench(F)(int log2n, long flops)
{    
    auto f = F(log2n);

    foreach(i; 0 .. one << log2n)
        f.re(i) = 0.0, f.im(i) = 0.0;

    ulong flopsPerIter = 5UL * log2n * (1UL << log2n); 
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

void precision(F)(int log2n, long flops)
{
    auto tested = F(log2n);
    auto simple = SimpleFft!real(log2n);
    
    rndGen.seed(1);
    foreach(i; 0 .. 1 << log2n)
    {
        auto re = uniform(0.0,1.0);
        auto im = uniform(0.0,1.0);
        simple.re(i) = re;
        simple.im(i) = im;
        tested.re(i) = re;
        tested.im(i) = im;
    }
    
    simple.compute();
    tested.compute();
    
    
    real sumSqDiff = 0.0;
    real sumSqAvg = 0.0;
    
    foreach(i; 0 .. 1 << log2n)
    {
        auto tre = tested.result_re(i);
        auto tim = tested.result_im(i);
        auto sre = simple.result_re(i);
        auto sim = simple.result_im(i);
        sumSqDiff += sq(sre - tre) + sq(sim - tim); 
        sumSqAvg += 0.5 * (sre + tre) + sq(sim + tim); 
    }
    writeln(std.math.sqrt(sumSqDiff / sumSqAvg));
}

bool runTest(alias f)(string[] args, long mflops)
{
    int log2n = to!int(args[2]);
    long flops = mflops * 1000_000;
    
    if(args[1] == "simple")
        f!(SimpleFft!T)(log2n, flops);
    else if(args[1] == "direct")
        f!DirectApi(log2n, flops);
    else if(args[1] == "std")
        f!(StdApi!false)(log2n, flops);
    else if(args[1] == "phobos")
        f!(StdApi!(true))(log2n, flops);
    else if(args[1] == "split")
        f!SplitApi(log2n, flops);
    else
    {
        version(BenchFftw)
        {
            if(args[1] == "fftw")
                f!FFTW(log2n, flops);
            else 
                return false;
        }
        else
            return false;
    }
    
    return true;
}

void main(string[] args)
{
    bool s = false;
    bool p = false;
    int mflops = 10_000;
    
    getopt(args, "s", &s, "p", &p, "m", &mflops);
    
    if(args.length == 3)
    {
        if(s && runTest!bench(args, mflops))
            return;

        if(p && runTest!precision(args, mflops))
            return;
    }
    
    writeln("You're using it wrong.");
}
