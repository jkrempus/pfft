module pfft.instantiate_declarations;

mixin template Instantiate(string name)
{
    // TODO: define NamedType template and use it instead of void*
    alias void* MultiTable;
    alias void* MultiRTable;
    alias void* TransposeBuffer;
    alias void* MultiITable;
    alias void* MultidimTable;
    alias void* RealMultidimTable;

    pragma(mangle, "pfft_multi_fft_table_"~name) MultiTable multi_fft_table(uint log2n, void* p);
    pragma(mangle, "pfft_multi_fft_table_size_"~name) size_t multi_fft_table_size(size_t log2n);
    pragma(mangle, "pfft_multi_fft_"~name) void multi_fft(T* re, T* im, MultiTable t);
    pragma(mangle, "pfft_multi_fft_ntransforms_"~name) size_t multi_fft_ntransforms();

    pragma(mangle, "pfft_multi_rfft_table_"~name) MultiRTable multi_rfft_table(uint log2n, void* p);
    pragma(mangle, "pfft_multi_rtable_size_"~name) size_t multi_rtable_size(size_t log2n);
    pragma(mangle, "pfft_multi_rfft_complete_"~name) void multi_rfft_complete(T* data, MultiTable t, MultiRTable rt, MultiITable it);
    pragma(mangle, "pfft_multi_rfft_ntransforms_"~name) size_t multi_rfft_ntransforms();

    pragma(mangle, "pfft_deinterleave_array_"~name) void deinterleave_array(T* even, T* odd, T* interleaved, size_t n);
    pragma(mangle, "pfft_interleave_array_"~name) void interleave_array(T* even, T* odd, T* interleaved, size_t n);
    pragma(mangle, "pfft_scale_"~name) void scale(T* data, size_t n, T factor);
    //pragma(mangle, "pfft_cmul_"~name) void cmul(T*, T*, T*, T*, size_t);
    pragma(mangle, "pfft_alignment_"~name) size_t alignment(size_t n);

    pragma(mangle, "pfft_multi_itable_size_"~name) size_t multi_itable_size(uint log2n);
    pragma(mangle, "pfft_multi_interleave_table_"~name) MultiITable multi_interleave_table(uint log2n, void* p);
  
    pragma(mangle, "pfft_set_implementation_"~name) void set_implementation(int);
    
    pragma(mangle, "pfft_multidim_fft_table_size_"~name) size_t multidim_fft_table_size(uint[] log2n);
    pragma(mangle, "pfft_multidim_fft_table_"~name) MultidimTable multidim_fft_table(uint[] log2n, void* ptr);
    pragma(mangle, "pfft_multidim_fft_table_memory_"~name) void* multidim_fft_table_memory(MultidimTable table);
    pragma(mangle, "pfft_multidim_fft_"~name) void multidim_fft( T* re, T* im, MultidimTable table);
    
    pragma(mangle, "pfft_multidim_rfft_table_size_"~name) size_t multidim_rfft_table_size(uint[] log2n);
    pragma(mangle, "pfft_multidim_rfft_table_"~name) RealMultidimTable multidim_rfft_table(uint[] log2n, void* ptr);
    pragma(mangle, "pfft_raw_rfft_"~name) void raw_rfft(T* re, T* im, RealMultidimTable rmt);
    pragma(mangle, "pfft_multidim_rfft_"~name) void multidim_rfft(T* p, RealMultidimTable rmt);
    pragma(mangle, "pfft_multidim_irfft_"~name) void multidim_irfft(T* p, RealMultidimTable rmt);
    pragma(mangle, "pfft_multidim_rfft_table_memory_"~name) void* multidim_rfft_table_memory(MultidimTable table);
}
