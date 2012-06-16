//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.conv, std.datetime, std.complex, std.getopt, 
    std.random, std.numeric, std.math, std.algorithm, std.exception;

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

struct DirectApi(bool isReal) if(!isReal)
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
    
    void compute(){ fft(_re.ptr, _im.ptr, log2n, table); }
    
    mixin splitElementAccess!(_re, _im);
}

struct DirectApi(bool isReal) if(isReal)
{
    mixin ImportDirect!();
    import core.memory; 
   
    T[] data;
    RTable rtable;
    int log2n;
    DirectApi!false c;
    T[] _re;
    T[] _im;
    
    this(int log2n)
    {
        c = DirectApi!false(log2n - 1);
        _re = c._re;
        _im = c._im;

        data = gc_aligned_array!T(1 << log2n);

        this.log2n = log2n;
        rtable = rfft_table(log2n, GC.malloc(table_size_bytes(log2n))); 
    }
    
    void compute()
    { 
        deinterleaveArray(data.ptr, _re.ptr, _im.ptr, st!1 << (log2n - 1));
        rfft(_re.ptr, _im.ptr, log2n, c.table, rtable); 
    }
    
    mixin realSplitElementAccess!(data, _re, _im);
}

struct PfftApi(bool isReal) if(!isReal)
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
    
    void compute(){ f.fft(_re, _im); }
    
    mixin splitElementAccess!(_re, _im);
}

struct PfftApi(bool isReal) if(isReal)
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
    
    void compute(){ f.rfft(data, _re, _im); }
    
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
        a[] = Complex!T(0, 0);
        r = gc_aligned_array!(Complex!T)(one << log2n);
        fft = new Fft(one << log2n);
    }
    
    void compute(){ fft.fft(a, r); }

    mixin ElementAccess!(a, r);
}

struct InterleavedTypedApi
{
    import pfft.stdapi;
    
    Complex!(T)[] a;
    Complex!(T)[] r;
    alias TypedFft!T F;
    F fft;
    
    this(int log2n)
    {
        a = F.allocate(one << log2n);
        a[] = Complex!T(0, 0);
        r = F.allocate(one << log2n);
        fft = new TypedFft!T(one << log2n);
    }
    
    void compute(){ fft.fft(a, r); }

    mixin ElementAccess!(a, r);
}

version(BenchFftw)
{
    static if(is(T == float))
    {
        pragma (msg, "Using FFTW - you should link to libfftw3f.a. Note that the resulting binary will be covered by the GPL (see FFTW license).");
        
        extern(C) void* fftwf_malloc(size_t);
        extern(C) void* fftwf_plan_dft_1d(int, Complex!(float)*, Complex!(float)*, int, uint);
        extern(C) void fftwf_execute(void *);
        
        alias fftwf_malloc fftw_malloc;
        alias fftwf_plan_dft_1d fftw_plan_dft_1d;
        alias fftwf_execute fftw_execute;
    }
    else static if(is(T == double))
    {
        pragma (msg, "Using FFTW - you should link to libfftw3.a. Note that the resulting binary will be covered by the GPL (see FFTW license).");
        
        extern(C) void* fftw_malloc(size_t);
        extern(C) void* fftw_plan_dft_1d(int, Complex!(double)*, Complex!(double)*, int, uint);
        extern(C) void fftw_execute(void *);
    }
    else
    {
        pragma (msg, "Using FFTW - you should link to libfftw3q.a. Note that the resulting binary will be covered by the GPL (see FFTW license).");
        
        extern(C) void* fftwl_malloc(size_t);
        extern(C) void* fftwl_plan_dft_1d(int, Complex!(real)*, Complex!(real)*, int, uint);
        extern(C) void fftwl_execute(void *);
        
        alias fftwl_malloc fftw_malloc;
        alias fftwl_plan_dft_1d fftw_plan_dft_1d;
        alias fftwl_execute fftw_execute;
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
            a[] = Complex!T(0, 0);
            r = cast(Complex!(T)*) fftw_malloc(Complex!(T).sizeof * 1L << log2n);
            p = fftw_plan_dft_1d(1 << log2n, a, r, FFTW_FORWARD, FFTW_PATIENT);
        }
        
        void compute(){ fftw_execute(p); }
        
        mixin ElementAccess!(a, r);
    }
}

void bench(F, bool isReal)(int log2n, long flops)
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

void precision(F, bool isReal)(int log2n, long flops)
{
    auto tested = F(log2n);
    auto simple = SimpleFft!real(log2n);
    
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
    
    foreach(i; 0 .. (1 << log2n) / 2)
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

void runTest(alias f, bool isReal)(string[] args, long mflops)
{
    int log2n = to!int(args[2]);
    long flops = mflops * 1000_000;
   
    auto a = args[1];
 
    if(a == "simple")
        f!(SimpleFft!T, isReal)(log2n, flops);
    else if(a == "direct")
        f!(DirectApi!(isReal), isReal)(log2n, flops);
    else if(a == "std")
        f!(StdApi!false, isReal)(log2n, flops);
    else if(a == "phobos")
        f!(StdApi!true, isReal)(log2n, flops);
    else if(a == "interleaved-typed")
        f!(InterleavedTypedApi, isReal)(log2n, flops);
    else if(a == "pfft")
        f!(PfftApi!isReal, isReal)(log2n, flops);
    else
    {
        version(BenchFftw)
        {
            if(a == "fftw")
                f!(FFTW, isReal)(log2n, flops);
            else 
                throw new Exception(
                    "Implementation \"" ~ a ~ "\" is not supported" );
        }
        throw new Exception(
            "Implementation \"" ~ a ~ "\" is not supported" );
    }
}

void main(string[] args)
{
    bool s;
    bool r;
    int mflops = 10_000;
    
    getopt(args, "s", &s, "r", &r, "m", &mflops);
    
    enforce(args.length == 3, "There must be exactly two non option arguments.");

    if(r)
    {
        if(s)
            runTest!(bench, true)(args, mflops);
        else 
            runTest!(precision, true)(args, mflops);
    }
    else
    {
        if(s)
            runTest!(bench, false)(args, mflops);
        else 
            runTest!(precision, false)(args, mflops);
    }
}
