import std.stdio, std.array, std.range, std.algorithm, std.datetime,
    std.conv;
import pfft.bitreverse, pfft.sse;
import core.simd;

void test_bit_reverse_simple_small(string[] args)
{
    auto a = array(iota(32));
    
    bit_reverse_simple_small!3(a.ptr, 3);
    writeln(a);
    bit_reverse_simple(a.ptr, 3);
    writeln(a);
    writeln("");
    
    bit_reverse_simple_small!4(a.ptr, 4);
    writeln(a);
    bit_reverse_simple(a.ptr, 4);
    writeln(a);
    writeln("");
    
    bit_reverse_simple_small!5(a.ptr, 5);
    writeln(a);
    bit_reverse_simple(a.ptr, 5);
    writeln(a);
    writeln("");
}

alias BitReverse!(SSE, Options) BR;

void interleave_chunks(size_t chunk_size, T)(T* p, int log2n)
{
    int shift = log2n - 1;
    size_t mask = (1UL << shift) - 1;
    size_t next(size_t j)
    { 
        return (j & mask)*2 + (j >> shift); 
    };
    size_t previous(size_t j)
    { 
        return (j >> 1) + ((j & 1UL) << shift); 
    };
    foreach(i; 1UL..mask + 1)
    if(next(i) > i && previous(i) > i)
    {
        auto j = i;
        T[chunk_size] a = void;
        BR.copy_array!T(a.ptr, p + j * chunk_size, chunk_size);
        j = next(j);
        do
        {
            BR.swap_array!T(a.ptr, p + j * chunk_size, chunk_size);
            j = next(j);
        }
        while (j != i);
        BR.copy_array!T(p + j * chunk_size, a.ptr, chunk_size);
    }
}

struct NTimes(T, int n)
{
    static if(n)
    {
        T a;
        NTimes!(T, n - 1) b;
    }
}

void interleave_small(size_t buffer_size)(float4* p, size_t n)
{
    assert(n < buffer_size);
    
    float4[buffer_size] buff = void;
    
    BR.copy_array!float4(buff.ptr, p, cast(int)n);
    
    auto a = buff.ptr, b = a + n / 2;
    
    foreach(i; 0 .. n / 2)
        SSE.interleave!4(a[i], b[i], p[2*i], p[2*i + 1]);
}

void interleave(int log2_buffer_size)(float* p, int log2n)
{
    enum buffer_size = 1UL << log2_buffer_size;
    
    if(log2n <= log2_buffer_size)
        interleave_small!buffer_size(cast(float4*)p, (1 << log2n) / 4);
    else
    {
        interleave_chunks!(buffer_size / 2)(p, log2n - log2_buffer_size + 1);
        
        foreach(i; iota(0UL, 1UL << log2n, buffer_size))
            interleave_small!buffer_size(cast(float4*)(p + i), buffer_size / 4);
    }
}

void bench_interleave(string[] args)
{
    auto log2n = to!int(args[1]);
    auto arr = new float[1 << log2n];
    arr[] = 0f;
    
    ulong flopsPerIter = 5UL * (log2n - 1) * (1UL << (log2n - 1)); 
    ulong niter = 10_000_000_000L / flopsPerIter;
    niter = niter ? niter : 1;
    
    StopWatch sw;
    sw.start();
    
    foreach(i; 0 .. niter)
        interleave!12(arr.ptr, log2n);
        
    sw.stop();
    
    writeln( to!double(niter) * flopsPerIter / sw.peek().nsecs());
}

void test_interleave(string[] args)
{
    auto log2n = to!int(args[1]);
    auto arr = array(map!"cast(float)a"(iota(1<<log2n)));
    interleave!6(arr.ptr, log2n);
    writeln(arr);
}

void main(string[] args)
{
    //test_bit_reverse_simple_small();
    bench_interleave(args);
    //test_interleave(args);
}
