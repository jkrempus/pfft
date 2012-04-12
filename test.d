//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.conv, std.datetime, std.complex, std.getopt, 
	std.random, std.numeric;

auto gc_aligned_array(T)(size_t n)
{
    import core.memory;
    return (cast(T*)GC.malloc(T.sizeof*n))[0..n];
}

template splitElementAccess(alias _re, alias _ri)
{
	ref re(size_t i){ return _re[i]; }
	ref im(size_t i){ return _ri[i]; }
	ref result_re(size_t i){ return _re[i]; }
	ref result_im(size_t i){ return _ri[i]; }
}

struct LowLewelApi
{
	version(Double)
		import pfft.impl_double;
	else
		import pfft.impl_float;
		
	float[] _re;
	float[] _ri;
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

struct SplitApi(T)
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

struct StdApi(T)
{
	import pfft.stdapi;
	
	Complex!(T)[] a;
	Complex!(T)[] r;
	Fft fft;
	
	this(int log2n)
	{
		a = gc_aligned_array!(Complex!T)(1L << log2n);
		r = gc_aligned_array!(Complex!T)(1L << log2n);
		fft = new Fft(1L << log2n);
	}
	
	void compute(){ fft.fft!T(a, r); }

	mixin ElementAccess!(a, r);
}

version(BenchFftw)
{
	pragma (msg, "Using FFTW - you should link to libfftw3f.a. Note that the resulting binary will be covered by GPL (see FFTW license).");
	
	extern(C) void* fftwf_malloc(size_t);
	extern(C) void* fftwf_plan_dft_1d(int, Complex!(float)*, Complex!(float)*, int, uint);
	extern(C) void fftwf_execute(void *);

	enum FFTW_FORWARD = -1;
	enum FFTW_ESTIMATE = 1U << 6;
	enum FFTW_MEASURE = 0U;
	enum FFTW_PATIENT = 1U << 5;

	struct FFTW
	{
		alias float T;
		
		Complex!(T)* a;
		Complex!(T)* r;
		
		void* p;
		
		this(int log2n)
		{
			a = cast(Complex!(T)*) fftwf_malloc(Complex!(T).sizeof * 1L << log2n);
			r = cast(Complex!(T)*) fftwf_malloc(Complex!(T).sizeof * 1L << log2n);
			p = fftwf_plan_dft_1d(1 << log2n, a, r, FFTW_FORWARD, FFTW_MEASURE);
		}
		
		void compute(){ fftwf_execute(p); }
		
		mixin ElementAccess!(a, r);
	}
}

void bench(F)(int log2n)
{
	auto f = F(log2n);
	
	foreach(i; 0 .. 1L << log2n)
		f.re(i) = 0.0, f.im(i) = 0.0;
	
	ulong flopsPerIter = 5UL * log2n * (1UL << log2n); 
    ulong niter = 10_000_000_000L / flopsPerIter;
    niter = niter ? niter : 1;
    
	StopWatch sw;
    sw.start();
    
    foreach(i; 0 .. niter)
        f.compute();
    
    sw.stop();
    writefln("%f", to!double(niter * flopsPerIter) / sw.peek().nsecs());
}

auto sq(T)(T a){ return a * a; }

void precision(F)(int log2n)
{
	auto f = F(log2n);
	
	auto c = new Complex!real[1U << log2n];
	
	rndGen.seed(1);
    foreach(i, e; c)
    {
        c[i].re = uniform(0.0,1.0);
        c[i].im = uniform(0.0,1.0);
        f.re(i) = c[i].re;
        f.im(i) = c[i].im;
    }
    
    auto ft = (new Fft(1 << log2n)).fft!real(c);
    f.compute();
    
    
    auto sumSqDiff = 0.0;
    auto sumSqAvg = 0.0;
    
	foreach(i, e; c)
	{
		sumSqDiff += sq(ft[i].re - f.result_re(i)) + sq(ft[i].im - f.result_im(i)); 
		sumSqAvg += 0.5 * (sq(ft[i].re + f.result_re(i)) + sq(ft[i].im + f.result_im(i))); 
	}
    writeln(std.math.sqrt(sumSqDiff / sumSqAvg));
}

bool runTest(alias f)(string[] args)
{
	int log2n = to!int(args[2]);
	
	if(args[1] == "lowlevel")
		f!LowLewelApi(log2n);
	else if(args[1] == "std")
		f!(StdApi!float)(log2n);
	else if(args[1] == "split")
		f!(SplitApi!float)(log2n);
	else
	{
		version(BenchFftw)
		{
			if(args[1] == "fftw")
				f!FFTW(log2n);
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
	string what = "lowlevel";
	bool s = false;
	bool p = false;
	
	getopt(args, "s", &s, "p", &p);
	
	if(args.length == 3)
	{
		if(s && runTest!bench(args))
			return;

		if(p && runTest!precision(args))
			return;
	}
	
	writeln("You're using it wrong.");
}
