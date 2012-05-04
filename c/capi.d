import impl = pfft.impl_float;
import core.sys.posix.stdlib, core.stdc.stdlib, core.stdc.stdio, core.bitop;

private void assert_power2(size_t n)
{
    if(n & (n - 1))
    {
        perror("Size passed to pfft functions must be a power of two.");
        abort(); 
    }
}

extern(C) auto pfft_table(size_t n, void* mem)
{
    assert_power2(n);
    
    auto log2n = bsf(n);
    
    if(mem is null)
        posix_memalign(&mem, impl.alignment(log2n), impl.table_size_bytes(log2n));

	return impl.fft_table(bsf(n), mem);
}

extern(C) void pfft_fft(float* re, float* im, size_t n, impl.Table table)
{
    assert_power2(n);
    
	impl.fft(re, im, bsf(n), table);
}

extern(C) size_t pfft_table_size_bytes(size_t n)
{
    assert_power2(n);
    
    return impl.table_size_bytes(bsf(n));
}

extern(C) size_t pfft_alignment(size_t n)
{
    assert_power2(n);

    return impl.alignment(bsf(n));
}

extern(C) float* pfft_allocate(size_t n)
{
    assert_power2(n);
    
    void* p;
    posix_memalign(&p, impl.alignment(bsf(n)), float.sizeof * n);
    
    return cast(float*) p;
}

extern(C) void pfft_free(void* p)
{
    free(p);
}
    
