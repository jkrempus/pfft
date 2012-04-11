//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.conv, std.datetime;

auto gc_aligned_array(T)(size_t n)
{
    import core.memory;
    return (cast(T*)GC.malloc(T.sizeof*n))[0..n];
}

struct LowLewelApi
{
	version(Double)
		import pfft.impl_double;
	else
		import pfft.impl_float;
		
	float[] dr;
	float[] di;
	Table table;
	int log2n;
	
	this(int _log2n)
	{
		log2n = _log2n;
		dr = gc_aligned_array!T(1 << log2n);
		di = gc_aligned_array!T(1 << log2n);
		table = fft_table(log2n); // will leak memory but we don't care
	}
	
	void doit(){ fft(dr.ptr, di.ptr, log2n, table); }
	
	ref re(size_t i){ return dr[i]; }
	ref im(size_t i){ return di[i]; }
}

struct StdApi(T)
{
	import pfft.stdapi;
	import std.complex;
	
	Complex!(T)[] a;
	Fft!T fft;
	
	this(int log2n)
	{
		a = gc_aligned_array!(Complex!T)(1L << log2n);
		fft = new Fft!T(1L << log2n);
	}
	
	void doit(){ fft.fft(a); }
	
	ref re(size_t i){ return a[i].re; }
	ref im(size_t i){ return a[i].im; }
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
        f.doit();
    
    sw.stop();
    writefln("%f", to!double(niter * flopsPerIter) / sw.peek().nsecs());
}

void main(string[] args)
{
	version(BenchStdApi)
		alias StdApi!float F;
	else
		alias LowLewelApi F;

    bench!F(to!int(args[1])); 
}
