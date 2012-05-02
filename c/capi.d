import impl = pfft.impl_float;

extern(C) auto pfft_table(uint log2n, void* mem)
{
	return impl.fft_table(log2n, mem);
}

extern(C) void pfft_fft(float* re, float* im, uint log2n, impl.Table table)
{
	impl.fft(re, im, log2n, table);
}

extern(C) size_t pfft table_size_bytes(uint log2n)
{
    return impl.table_size_bytes(log2n);
}

extern(C) size_t alignment(uint log2n)
{
    return impl.alignment(log2n);
}
