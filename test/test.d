// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.range, std.stdio, std.conv, std.complex, std.getopt, 
    std.random, std.numeric, std.math, std.algorithm,
    std.exception, std.typetuple, std.traits, std.string : toUpper, toStringz;

import core.bitop, core.stdc.string;

import core.time;

int global;

void bloat(int n, int m = 0)()
{
    global += m;
    static if(n != 0)
    {
        bloat!(n - 1, m);
        bloat!(n - 1, m | (1 << n));
    }
}

//alias bloat!12 B_L_O_A_T;

auto sum(A, B)(A a, B b){ return a + b; }
auto prod(A, B)(A a, B b){ return a * b; }
auto len(A)(A a){ return a.length; }

template st(alias a){ enum st = cast(size_t) a; }

enum Transform { fft, rfft /*, fst*/ }

version(JustDirect)
    enum justDirect = true;
else
    enum justDirect = false;

version(DynamicC)
    enum dynamicC = true;
else
    enum dynamicC = false;
    
version(BenchFftw)
    enum benchFftw = true;
else
    enum benchFftw = false;
    
version(BenchClib)
    enum benchClib = true;
else
    enum benchClib = false;

auto gc_aligned_array(A = void)(size_t n)
{
    A[] r;
    version(NoGC)
    {
        r = (cast(A*)PfftC!().allocate(A.sizeof*n / T.sizeof))[0..n];
    }
    else
    {
        import core.memory;
        r = (cast(A*)GC.malloc(A.sizeof*n))[0 .. n];
    }
    //writefln("Allocated memory between %s and %s", r.ptr, r.ptr + n);
    return r;
}

bool isIn(A, B...)(A a, B b)
{
    foreach(e; b)
        if(e == a)
            return true;
    
    return false;
}

template ntransforms(Api)
{
    static if(is(typeof({ Api.multi; })))
        alias Api.multi ntransforms;
    else
        enum ntransforms = 1;
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
        foreach(i; 0 .. ntransforms!(typeof(this)) << log2n)
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
    size_t _n;
    size_t[] _log2n_cumulative;

    void initRealElementAccessImpl(uint[] log2n)
    {
        _log2n_cumulative = new size_t[log2n.length + 1];
        _log2n_cumulative[$ - 1] = 0;
        
        foreach(i; 0 .. log2n.length)
            _log2n_cumulative[$ - 2 - i] = 
                _log2n_cumulative[$ - 1 - i] + log2n.retro[i];

        _n = st!1 << _log2n_cumulative[0];
    }

    size_t _dim_size(size_t dim)
    {
        return st!1 << (_log2n_cumulative[dim] - _log2n_cumulative[dim + 1]);
    }

    size_t _index(size_t i, size_t dim)
    {
        return (i & ((st!1 << _log2n_cumulative[dim]) - 1)) >>
            _log2n_cumulative[dim + 1];
    }

    private bool _mirrored(size_t i)
    {
        return _index(i, half_dim) > _dim_size(half_dim) / 2;
    }

    private auto _mirror(size_t i, size_t dim)
    {
        return (_dim_size(dim) - i) & (_dim_size(dim) - 1);
    }

    private bool _is_real(size_t i)
    {
        foreach(dim; 0 .. _log2n_cumulative.length - 1)
        {
            auto idx = _index(i, dim);
            if(_mirror(idx, dim) != idx)
                return false;
        }

        return true;
    }

    private auto _icomplex(size_t i)
    {
        size_t r = 0;
    
        foreach(dim; 0 .. _log2n_cumulative.length - 1)
        {
            r *= (dim == half_dim) ? _dim_size(dim) / 2 + 1  : _dim_size(dim);
            auto idx = _index(i, dim);
            r += _mirrored(i) ? _mirror(idx, dim) : idx;
        }
        return r;
    }

    auto timeRe(size_t i){ return data[i]; }
    auto timeIm(size_t i){ return to!T(0); }
    auto freqRe(size_t i) { return re(_icomplex(i)); }
    auto freqIm(size_t i)
    {
        return im(_icomplex(i)) * (_mirrored(i) ? -1 : 1);
    }

    alias T delegate(size_t) Dg;
    static if(isInverse)
    {
        void fill(Dg fRe, Dg fIm) 
        {
            foreach(i; 0 .. _n)
            {
                if(!_mirrored(i))
                {
                    re(_icomplex(i)) = fRe(i);                   
                    im(_icomplex(i)) = fIm(i);
                }
            }
        }

        alias timeRe outRe;
        alias timeIm outIm;
        alias freqRe inRe;
        alias freqIm inIm; 
    }
    else
    {
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
    enum half_dim= 0;
    ref re(size_t i){ return data[i]; }
    ref im(size_t i){ return data[$ / 2 + i]; }
    mixin realElementAccessImpl!();
}

mixin template GenericFst(F)
{
    F f;
    size_t n;

    this(int log2n)
    {
        f = F(log2n + 1);
        n = st!1 << log2n; 
    }

    void compute()
    {
        f.compute(); 
    } 

    alias T delegate(size_t) Dg;
    
    void fill(Dg fRe, Dg fIm) 
    {
        /*f.fill(
            (size_t i) => 
                i == 0 ? 0 :
                i == n ? 0 :
                i > n ? -fRe(2 * n - i) : fRe(i),
            (size_t i) => to!T(0)); TODO*/
    }

    T inRe(size_t i){ return f.inRe(i); }
    T outRe(size_t i){ return -0.5 * f.outIm(i); }
    
    T inIm(size_t  i){ return 0; }
    alias inIm outIm; 
}

version(Real)
    alias real T;
else version(Double)
    alias double T;
else
    alias float T;

static if(!dynamicC)
{
    static if(is(T == real))
        import direct = pfft.impl_real;
    else static if(is(T == double))
        import direct = pfft.impl_double;
    else
        import direct = pfft.impl_float;
}

struct DirectApi(Transform transform, bool isInverse, bool isMulti)
if(transform == Transform.fft && !isMulti)
{
    import core.memory; 
    alias direct d; 

    T[] _re;
    T[] _im;
    d.Table[] tables;
    d.TransposeBuffer tbuf;
    d.MultidimTable table2;
    int log2n;

    this(uint[] log2ns)
    {
        log2n = log2ns.reduce!sum;
        _re = gc_aligned_array!T(1 << log2n);
        _im = gc_aligned_array!T(1 << log2n);
        _re[] = 0;
        _im[] = 0;
        auto size = d.multidim_fft_table_size(log2ns);
        table2 = d.multidim_fft_table(log2ns, GC.malloc(size));
    }
    
    void compute()
    {
        static if(isInverse)
            d.multidim_fft(_im.ptr, _re.ptr, table2);
        else 
            d.multidim_fft(_re.ptr, _im.ptr, table2);
    }

    mixin splitElementAccess!();
}

struct DirectApi(Transform transform, bool isInverse, bool isMulti)
if(transform == Transform.fft && isMulti)
{
    import core.memory; 
    alias direct d; 

    T[] _re;
    T[] _im;
    d.MultiTable table;
    int log2n;

    static @property multi(){ return d.multi_fft_ntransforms(); }

    this(uint[] log2ns)
    {
        enforce(log2ns.length == 1);
        log2n = log2ns.front;
        _re = gc_aligned_array!T(multi << log2n);
        _im = gc_aligned_array!T(multi << log2n);
        _re[] = 0;
        _im[] = 0;
        auto size = d.multi_fft_table_size(log2n);
        table = d.multi_fft_table(log2n, GC.malloc(size));
    }
    
    void compute()
    {
        static if(isInverse)
            d.multi_fft(_im.ptr, _re.ptr, table);
        else 
            d.multi_fft(_re.ptr, _im.ptr, table);
    }

    mixin splitElementAccess!();
}

struct DirectApi(Transform transform, bool isInverse, bool isMulti)
if(transform == Transform.rfft && !isMulti)
{
    import core.memory; 
    alias direct d; 

    T[] data;
    d.RealMultidimTable table;

    this(uint[] log2ns)
    {
        initRealElementAccessImpl(log2ns); 
        log2ns = log2ns.dup;
        auto log2m = 0.reduce!sum(log2ns[1 .. $]);
        auto log2n = log2m + log2ns.front;
        log2ns.front -= 1;
        data = gc_aligned_array!T((st!1 << log2n) + (st!2 << log2m));
        data[] = 0;

        auto size = d.multidim_rfft_table_size(log2ns);
        table = d.multidim_rfft_table(log2ns, gc_aligned_array(size).ptr);
    }

    void compute()
    {
        static if(isInverse)
            d.multidim_irfft(data.ptr, table);
        else
            d.multidim_rfft(data.ptr, table);
    }

    mixin realSplitElementAccess!();
}

struct DirectApi(Transform transform, bool isInverse, bool isMulti)
if(transform == Transform.rfft && isMulti)
{
    import core.memory; 
    alias direct d; 

    T[] data;
    d.MultiTable table;
    d.MultiRTable rtable;
    d.MultiITable itable;
    uint log2multi;
    uint log2n;

    static @property multi(){ return d.multi_rfft_ntransforms(); }

    this(uint[] log2ns)
    {
        enforce(log2ns.length == 1);
        log2multi = bsr(multi);
        log2n = log2ns.front;
        data = gc_aligned_array!T(multi * ((st!1 << log2n) + 2));
        data[] = 0;
        auto size = d.multi_fft_table_size(log2n - 1);
        table = d.multi_fft_table(log2n - 1, GC.malloc(size));
        auto rsize = d.multi_rtable_size(log2n);
        rtable = d.multi_rfft_table(log2n, GC.malloc(rsize));
        auto isize = d.multi_itable_size(log2n);
        itable = d.multi_interleave_table(log2n, GC.malloc(isize));
    }
    
    void compute()
    {
        static if(isInverse)
        {
//            d.multi_fft(_im.ptr, _re.ptr, table);
        }
        else 
        {
            d.multi_rfft_complete(data.ptr, table, rtable, itable);
        }
    }

    alias T delegate(size_t) Dg;
    void fill(Dg fRe, Dg fIm) 
    {
        foreach(i; 0 .. multi << log2n)
            data[i] = fRe(i);
    }

    T inRe(size_t i){ return data[i]; }
    T inIm(size_t i){ return 0; }
    T outRe(size_t i)
    {
        size_t n = st!1 << log2n;
        size_t j = i >> log2multi;
        size_t k = i & ((1 << log2multi) - 1);

        if(j > n / 2)
            j = n - j;

        return data[(j << log2multi) | k]; 
    }

    T outIm(size_t i)
    {
        size_t n = st!1 << log2n;
        size_t j = i >> log2multi;
        size_t k = i & ((1 << log2multi) - 1);

        T sign = 1;
        if(j > n / 2)
        {
            j = n - j;
            sign = -1;
        }

        return sign * data[((n / 2 + 1 + j) << log2multi) | k]; 
    }
}

template PfftC()
{
    extern(C):
    __gshared:

    enum suffix = is(T == float) ? "f" : is(T == double) ? "d" : "l";
       
    version(Windows)
    {
        import core.sys.windows.windows;

        void* loadLib(const(char)* name) { return LoadLibraryA(name); }
        void* getFunc(void* lib, const(char)* name)
        { 
            return GetProcAddress(lib, name); 
        }
    }
    else
    {
        import core.sys.posix.dlfcn;

        void* loadLib(const(char)* name){ return dlopen(name, RTLD_NOW); }
        void* getFunc(void* lib, const(char)* name) { return dlsym(lib, name); }
    }

    static if(dynamicC)
    {
        struct Table {}
        struct RTable {}

        T* function(size_t) allocate;
        Table* function(size_t*, size_t, void*) table;
        RTable* function(size_t, void*) rtable;
        void function(Table*) table_free;
        void function(RTable*) rtable_free;
        void function(T*) free;
        void function(T*, T*, Table*) fft; 
        void function(T*, RTable*) rfft; 
        void function(T*, T*, Table*) ifft; 
        void function(T*, RTable*) irfft; 

        void load(string[] args)
        {
            import std.path;
            
            version(linux)
                auto libname = "libpfft-c.so";
            else version(OSX)
                auto libname = "libpfft-c.dylib";
            else version(Windows)
                auto libname = "pfft-c.dll";

            auto lib = buildPath(
                absolutePath(dirName(args[0])), 
                "..", "generated-c", "lib", libname);

            auto dl = loadLib(toStringz(lib));

            allocate = cast(typeof(allocate)) getFunc(dl, toStringz("pfft_allocate_"~suffix));
            table = cast(typeof(table)) getFunc(dl, toStringz("pfft_table_"~suffix));
            rtable = cast(typeof(rtable)) getFunc(dl, toStringz("pfft_rtable_"~suffix));
            table_free = cast(typeof(table_free)) getFunc(dl, toStringz("pfft_table_free_"~suffix));
            rtable_free = cast(typeof(rtable_free)) getFunc(dl, toStringz("pfft_rtable_free_"~suffix));
            free = cast(typeof(free)) getFunc(dl, toStringz("pfft_free_"~suffix));
            fft = cast(typeof(fft)) getFunc(dl, toStringz("pfft_fft_"~suffix));
            rfft = cast(typeof(rfft)) getFunc(dl, toStringz("pfft_rfft_"~suffix));
            ifft = cast(typeof(ifft)) getFunc(dl, toStringz("pfft_ifft_"~suffix));
            irfft = cast(typeof(irfft)) getFunc(dl, toStringz("pfft_irfft_"~suffix));
        }
    }
    else
    {
        import pfft.clib;

        mixin("alias PfftTable"~toUpper(suffix)~" Table;");
        mixin("alias PfftRTable"~toUpper(suffix)~" RTable;");

        mixin("alias pfft_allocate_"~suffix~" allocate;");
        mixin("alias pfft_table_"~suffix~" table;");
        mixin("alias pfft_rtable_"~suffix~" rtable;");
        mixin("alias pfft_table_free_"~suffix~" table_free;");
        mixin("alias pfft_rtable_free_"~suffix~" rtable_free;");
        mixin("alias pfft_free_"~suffix~" free;");
        mixin("alias pfft_fft_"~suffix~" fft;");
        mixin("alias pfft_rfft_"~suffix~" rfft;");
        mixin("alias pfft_ifft_"~suffix~" ifft;"); 
        mixin("alias pfft_irfft_"~suffix~" irfft;"); 

        void load(string[] args) { }
    }
}

struct CApi(Transform transform, bool isInverse) 
if(transform == Transform.fft)
{
    alias PfftC!() Impl;

    T* _re;
    T* _im;
    Impl.Table* table;
    int log2n;
    
    this(uint[] log2ns)
    {
        auto ns = new size_t[](log2ns.length);
        log2n = 0;
        foreach(i; 0 .. log2ns.length)
        {
            ns[i] = st!1 << log2ns[i];
            log2n += log2ns[i]; 
        }
        auto n = st!1 << log2n;
        table = Impl.table(ns.ptr, ns.length, null);
        _re = Impl.allocate(n);
        _im = Impl.allocate(n);
        _re[0 .. n] = 0;
        _im[0 .. n] = 0;
    }

    ~this()
    {
        Impl.table_free(table);
        Impl.free(_re);
        Impl.free(_im);
    }
    
    void compute()
    {
        static if(isInverse)
            Impl.ifft(_re, _im, table);
        else 
            Impl.fft(_re, _im, table);
    }
    
    mixin splitElementAccess!();
}

struct CApi(Transform transform, bool isInverse) 
if(transform == Transform.rfft)
{
    alias PfftC!() Impl;
   
    int log2n;
    Impl.RTable* table;
    T[] data;
    
    this(uint[] log2ns)
    {
        initRealElementAccessImpl(log2ns);
        auto ns = new size_t[](log2ns.length);
        log2n = 0;
        foreach(i; 0 .. log2ns.length)
        {
            ns[i] = st!1 << log2ns[i];
            log2n += log2ns[i]; 
        }
        auto n = st!1 << log2n;
        table = Impl.rtable(ns.ptr, ns.length, null);
        auto len = (st!1 << log2n) + (st!2 << (log2n - log2ns[0]));
        data = Impl.allocate(len)[0 .. len];
        data[] = 0;
    }
    
    ~this()
    {
        Impl.rtable_free(table);
        Impl.free(data.ptr);
    }
    
    void compute()
    {
        static if(isInverse)
            Impl.irfft(data.ptr, table);
        else 
            Impl.rfft(data.ptr, table);
    }
    
    mixin realSplitElementAccess!();
}


struct PfftApi(Transform transform, bool isInverse) if(transform == Transform.fft)
{
    import pfft.pfft;
   
    alias Fft!T F; 
    F f;
    F.Array _re;
    F.Array _im;
    uint log2n;
    
    this(uint[] log2ns)
    {
        auto ns = new size_t[](log2ns.length);
        log2n = 0;
        foreach(i; 0 .. log2ns.length)
        {
            ns[i] = st!1 << log2ns[i];
            log2n += log2ns[i]; 
        }
        auto n = st!1 << log2n;
        f = new F(ns);
        _re = F.Array(n);
        _im = F.Array(n);
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

struct PfftApi(Transform transform, bool isInverse) if(transform == Transform.rfft)
{
    import pfft.pfft;
   
    alias Rfft!(T) F;
    F f;
    F.Array data;
    
    this(uint[] log2ns)
    {
        initRealElementAccessImpl(log2ns);
        auto ns = new size_t[](log2ns.length);
        size_t log2n = 0;
        foreach(i; 0 .. log2ns.length)
        {
            ns[i] = st!1 << log2ns[i];
            log2n += log2ns[i]; 
        }
        auto n = st!1 << log2n;
        f = new F(ns);
        auto len = (st!1 << log2n) + (st!2 << (log2n - log2ns[0]));
        data = F.Array(len);
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

struct SimpleFft(T, Transform transform, bool isInverse)
if(isIn(transform, Transform.rfft, Transform.fft))
{
    Complex!(T)[] a;
    Complex!(T)[] w;
    int log2n;
    uint[] log2ns;
    size_t multi;

    private static void bit_reverse(A)(int log2n, A a)
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

    private static auto table(int log2n)
    {
        auto w = gc_aligned_array!(Complex!T)(st!1 << (log2n - 1));

        size_t n = 1 << log2n;
        T dphi = 4.0 * asin(to!T(1.0)) / n;
        for(size_t i=0; i< n/2; i++)
        {
            w[i].re = cos(dphi * i);
            w[i].im = -sin(dphi * i);
        }

        if(log2n != 0)
            bit_reverse(log2n - 1, w[0 .. n / 2]);

        return w;
    }

    private static void fft(A, W)(A a, W w)
    {
        static if(isInverse)
            foreach(ref e; a)
                swap(e.re, e.im);

        for (size_t m2 = a.length / 2; m2; m2 >>= 1)
        {
            auto table = w.save;
            size_t m = m2 + m2;
            for(auto p = a.save; !p.empty; p = p[m .. $])
            {
                T wr = table.front.re;
                T wi = table.front.im;
                table.popFront;
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
        bit_reverse(bsr(a.length), a);
        
        static if(isInverse)
            foreach(ref e; a)
                swap(e.re, e.im);
    }

    private static void multidim(A, W)(A a, W w, uint[] log2ns)
    {
        if(log2ns.length == 1)
            return fft(a, w);

        size_t m = st!1 << log2ns[1 .. $].reduce!sum;
        foreach(i; 0 .. st!1 << log2ns.front)
            multidim(a[i * m .. (i + 1) * m], w, log2ns[1 .. $]);

        foreach(i; 0 .. m)
            fft(a[i .. $].stride(m), w);
    }

    this(uint[] log2ns, size_t multi = 1)
    {
        this.multi = multi;
        this.log2ns = log2ns;
        log2n = log2ns.reduce!sum;
        
        a = gc_aligned_array!(Complex!T)(multi << log2n);
        a[] = Complex!T(0, 0);

        w = table(log2ns.reduce!max);
    }
   
    void compute()
    {
        if (multi == 1)
            multidim(a, w, log2ns);
        else 
            foreach(i; 0 .. multi)
                multidim(a[i .. $].stride(multi), w, log2ns);
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

struct SimpleFft(T, Transform transform, bool isInverse)
if(false)
{
    mixin GenericFst!(SimpleFft!(T, Transform.fft, false));
}

auto toComplex(T a){ return complex(a, cast(T) 0); }

struct StdApi(bool usePhobos = false, Transform transform, bool isInverse)
{
    static if(usePhobos)
        import std.numeric;
    else
        import pfft.stdapi;
       
    enum{ normalizedInverse };

    static if(transform == Transform.rfft)
        T[] a;
    else static if(transform == Transform.fft)
        Complex!(T)[] a;
    else
        static assert(0);
        
    Complex!(T)[] r;
    
    Fft fft;
    
    this(uint[] log2ns)
    {
        enforce(log2ns.length == 1);
        auto log2n = log2ns.front;
        a = gc_aligned_array!(typeof(a[0]))(st!1 << log2n);
        r = gc_aligned_array!(Complex!T)(st!1 << log2n);

        static if(transform == Transform.rfft)
            a[] = cast(T) 0;
        else static if(transform == Transform.fft)
            (cast(T[])a)[] = cast(T) 0; // work around a dmd bug
        else
            static assert(0);
        
        fft = new Fft(st!1 << log2n);
    }
    
    void compute()
    { 
        static if(isInverse)
        {
            static if(usePhobos && transform == Transform.rfft)
            {
                fft.inverseFft(map!toComplex(a), r);
            }
            else
                fft.inverseFft(a, r);
        }
        else 
            fft.fft(a, r); 
    }
    
    static if(transform == Transform.rfft)
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
    else static if(transform == Transform.fft)
        mixin ElementAccess!();
    else
        static assert(0);
}

static if(benchFftw)
{
    static if(is(T == float))
    {
        pragma (msg, "Using FFTW - you should link to libfftw3f.a. Note that the resulting binary will be covered by the GPL (see FFTW license).");
        
        extern(C) void* fftwf_malloc(size_t);
        extern(C) void* fftwf_plan_dft_1d(int, Complex!(float)*, Complex!(float)*, int, uint);
        extern(C) void* fftwf_plan_dft(int, int*, Complex!(float)*, Complex!(float)*, int, uint);
        extern(C) void* fftwf_plan_dft_r2c(int, int*, float*, Complex!(float)*, uint);
        extern(C) void* fftwf_plan_dft_c2r(int, int*, Complex!(float)*, float*, uint);
        extern(C) void fftwf_execute(void *);
        
        alias fftwf_malloc fftw_malloc;
        alias fftwf_plan_dft_1d fftw_plan_dft_1d;
        alias fftwf_plan_dft fftw_plan_dft;
        alias fftwf_plan_dft_r2c fftw_plan_dft_r2c;
        alias fftwf_plan_dft_c2r fftw_plan_dft_c2r;
        alias fftwf_execute fftw_execute;
    }
    else static if(is(T == double))
    {
        pragma (msg, "Using FFTW - you should link to libfftw3.a. Note that the resulting binary will be covered by the GPL (see FFTW license).");
        
        extern(C) void* fftw_malloc(size_t);
        extern(C) void* fftw_plan_dft_1d(int, Complex!(double)*, Complex!(double)*, int, uint);
        extern(C) void* fftw_plan_dft(int, int*, Complex!(double)*, Complex!(double)*, int, uint);
        extern(C) void* fftw_plan_dft_r2c(int, int*, double*, Complex!(double)*, uint);
        extern(C) void* fftw_plan_dft_c2r(int, int*, Complex!(double)*, double*, uint);
        extern(C) void fftw_execute(void *);
    }
    else
    {
        pragma (msg, "Using FFTW - you should link to libfftw3q.a. Note that the resulting binary will be covered by the GPL (see FFTW license).");
        
        extern(C) void* fftwl_malloc(size_t);
        extern(C) void* fftwl_plan_dft_1d(int, Complex!(real)*, Complex!(real)*, int, uint);
        extern(C) void* fftwl_plan_dft(int, int*, Complex!(real)*, Complex!(real)*, int, uint);
        extern(C) void* fftwl_plan_dft_r2c(int, int*, real*, Complex!(real)*, uint);
        extern(C) void* fftwl_plan_dft_c2r(int, int*, Complex!(real)*, real*, uint);
        extern(C) void fftwl_execute(void *);
        
        alias fftwl_malloc fftw_malloc;
        alias fftwl_plan_dft_1d fftw_plan_dft_1d;
        alias fftwl_plan_dft fftw_plan_dft;
        alias fftwl_plan_dft_r2c fftw_plan_dft_r2c;
        alias fftwl_plan_dft_c2r fftw_plan_dft_c2r;
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

    struct FFTW(Transform transform, bool isInverse, int flags) 
        if(transform == Transform.fft)
    {        
        Complex!(T)[] a;
        Complex!(T)[] r;
        
        void* p;
        
        this(uint[] log2ns)
        {
            auto n = st!1 << log2ns.reduce!sum;
            a = fftw_array!(Complex!T)(n);
            a[] = Complex!T(0, 0);
            r = fftw_array!(Complex!T)(n);
            auto dir = isInverse ? FFTW_BACKWARD : FFTW_FORWARD;
            auto ns = new int[log2ns.length]; 
            foreach(i; 0 .. log2ns.length)
                ns[i] = 1 << log2ns[i];

            p = fftw_plan_dft(ns.length.to!int, ns.ptr, a.ptr, r.ptr, dir, flags);
        }
        
        void compute(){ fftw_execute(p); }
        
        mixin ElementAccess!();
    }

    struct FFTW(Transform transform, bool isInverse, int flags)
        if(transform == Transform.rfft)
    {        
        T[] a;
        Complex!(T)[] r;
        void* p;
        int log2n;
        int ndim;

        this(uint[] log2ns)
        {
            initRealElementAccessImpl(log2ns); 
            log2n = log2ns.reduce!"a+b";
            auto n = st!1 << log2n;
            a = fftw_array!T(n);
            a[] = 0;
            r = fftw_array!(Complex!T)(
                n / 2 + (st!1 << (log2n - log2ns.back)));
           
            ndim = log2ns.length.to!int;
            
            auto ns = new int[ndim];
            foreach(i; 0 .. ndim)
                ns[i] = 1 << log2ns[i];

            static if(isInverse)
                p = fftw_plan_dft_c2r(ndim, ns.ptr, r.ptr, a.ptr, flags);
            else
                p = fftw_plan_dft_r2c(ndim, ns.ptr, a.ptr, r.ptr, flags);
        }

        void compute(){ fftw_execute(p); }

        ref re(size_t i){ return r[i].re; }
        ref im(size_t i){ return r[i].im; }

        alias a data;
        @property half_dim(){ return ndim - 1; }
        mixin realElementAccessImpl!();
    }
}


void speed(F, Transform transform, bool isInverse)(uint[] log2n, long flops)
{
    auto f = F(log2n);
   
    auto zero = delegate(size_t i){ return to!(typeof(F.init.inRe(0)))(0); };
 
    f.fill(zero, zero);

    ulong flopsPerIter = 
        ntransforms!F * 5UL * log2n.reduce!sum * (1UL << log2n.reduce!sum) /
        (transform == Transform.fft ? 1 : 2); 
    ulong niter = flops / flopsPerIter;
    niter = niter ? niter : 1;
        
    auto tick = TickDuration.currSystemTick;
    
    foreach(i; 0 .. niter)
        f.compute();
    
    tick = TickDuration.currSystemTick - tick;
    writefln("%f", to!double(niter * flopsPerIter) / tick.nsecs());
}

//void initialization(F, Transform transform, bool isInverse)(int[] log2n, long flops)
//{    
//    auto niter = 100_000_000 / (1 << log2n);
//    niter = niter ? niter : 1;
//
//    auto tick = TickDuration.currSystemTick;
//    
//    foreach(i; 0 .. niter)
//    {
//        auto f = F(log2n);
//        f.compute();
//    }
//    
//    tick = TickDuration.currSystemTick - tick;
//    writefln("%.3e", tick.nsecs() * 1e-9 / niter);
//}

void precision(F, Transform transform, bool isInverse)(uint[] log2n, long flops)
{
    alias SimpleFft!(real, transform, isInverse) S;
    alias typeof(S.init.inRe(0)) ST;
    alias typeof(F.init.inRe(0)) FT;

    auto n = st!1 << log2n.reduce!sum;
    auto tested = F(log2n);
    auto simple = S(log2n, ntransforms!F);
    
    rndGen.seed(1);
    
    static if(isInverse &&  transform == Transform.rfft)
    {
        auto tmp = SimpleFft!(real, Transform.rfft, false)(log2n, ntransforms!F);
        tmp.fill(i => to!ST(uniform(0.0, 1.0)), a => to!ST(0));
        tmp.compute();
        tested.fill(a => tmp.inRe(a).to!FT, a => tmp.inIm(a).to!FT);
    }
    else
    {
        auto rnd = delegate (size_t i) => to!FT(uniform(0.0, 1.0));
        tested.fill(rnd, rnd);
    }

    simple.fill(a => tested.inRe(a).to!ST, a => tested.inIm(a).to!ST);
   
    simple.compute();
    tested.compute();

//    writefln("simple\n%(%s\t%)\n", simple.a);
//    static if(is(typeof(tested.data)))
//        writefln("tested\n%(%s\t%)\n", tested.data);

    real sumSqDiff = 0.0;
    real sumSqAvg = 0.0;
    
    foreach(i; 0 .. n * ntransforms!F)
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

//        writefln("%s\t%.2e\t%.2e\t%.2e\t%.2e\t%.2e\t%.2e", i, sre, tre, sim, tim, 0.0, sim - tim);
        
        sumSqDiff += (sre - tre) ^^ 2 + (sim - tim) ^^ 2; 
        sumSqAvg += sre ^^ 2 + sim ^^ 2; 
    }
    writeln(cast(double) std.math.sqrt(sumSqDiff / sumSqAvg));
}

void runTest(bool testSpeed, Transform transform, bool isInverse)(
    uint[] log2n, string impl, long mflops)
{
    static if(testSpeed)
        alias speed f;
    else
        alias precision f;

    long flops = mflops * 1000_000;
 
    static if(!justDirect && (benchClib || dynamicC))
        if(impl == "c")
            return f!(CApi!(transform, isInverse), transform, isInverse)(
                log2n, flops);

    static if(!dynamicC)
    {
        if(impl == "direct")
            return f!(DirectApi!(transform, isInverse, false), transform, isInverse)(
                log2n, flops);

        if(impl == "direct-multi")
            return f!(
                DirectApi!(transform, isInverse, true),
                Transform.fft,
                isInverse)(log2n, flops);
    }
    
    static if(!justDirect && !dynamicC)
    { 
        if(impl == "simple")
            return f!(SimpleFft!(T, transform, isInverse), transform, isInverse)(
                    log2n, flops);
        
        if(impl == "std")
            return f!(StdApi!(false, transform, isInverse), transform, isInverse)(
                    log2n, flops);
        
        if(impl == "phobos")
            return f!(StdApi!(true, transform, isInverse), transform, isInverse)(
                    log2n, flops);
        
        if(impl == "pfft")
            return f!(PfftApi!(transform, isInverse), transform, isInverse)(
                    log2n, flops);
        
    }
    
    static if(benchFftw && !justDirect)
    {
        if(impl == "fftw")
            return f!(
                FFTW!(transform, isInverse, FFTW_PATIENT), transform, isInverse)(
                log2n, flops);

        if(impl == "fftw-measure")
            return f!(
                FFTW!(transform, isInverse, FFTW_MEASURE), transform, isInverse)(
                log2n, flops);
    }
    
    throw new Exception(
            "Implementation \"" ~ impl ~ "\" is not supported" );
}

template Group(A...){ alias A Members; }
auto callInstance(alias f, int n, alias FParams = Group!(), Params...)(
    Params params)
{
    static if(is(Params[0] == enum))
        alias EnumMembers!(Params[0]) possibleValues;
    else
        alias TypeTuple!(true, false) possibleValues; 

    foreach(e; possibleValues)
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
difference of the two results and the sum of squares of the result of the 
simple transform and print the square root of the quotient of the two sums.

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

'direct' and 'c' implementations can be tested even if the D 
compiler used to build the library and this program does not come with a 
working GC, but then you need to build this program with version NoGC.

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
    static if(dynamicC)
        PfftC!().load(args);

    try
    {
        bool s;
        bool r;
        bool i;
        bool h;
        bool st;
        int mflops = 10_000;
        int impl = -1;

        getopt(
            args, 
            "s", &s, 
            "r", &r, 
            "i", &i, 
            "m", &mflops,
            "st", &st,
            "impl", &impl,
            "h|help", &h);

        if(h)
        {
            writefln(usage, args[0]);
            return;
        }

        static if(!dynamicC) 
            if(impl != -1)
                direct.set_implementation(impl);

        enforce(args.length >= 3, 
            "There must be at least two non option arguments.");

        auto transform = 
            r ? Transform.rfft : 
            /*st ? Transform.fst :*/ Transform.fft;

        auto log2n = args[2 .. $].map!(to!uint).array;
        callInstance!(runTest, 3)(s, transform, i, log2n, args[1], mflops);
    }
    catch(Exception e)
    {
        auto s = findSplit(to!string(e), "---")[0];
        stderr.writefln("Exception was thrown: %s", s);
        stderr.writefln(usage, args[0]); 
    }
}
