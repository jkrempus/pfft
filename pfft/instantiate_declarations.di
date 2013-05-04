module pfft.instantiate_declarations;

mixin template Instantiate()
{
    struct TableValue{};
    alias TableValue* Table;

    void fft(T* re, T* im, uint log2n, Table t);
    Table fft_table(uint log2n, void* p = null);
    void* fft_table_memory(Table table);
    uint fft_table_log2n(Table table);
    size_t fft_table_size_bytes(uint log2n);

    struct RTableValue{};
    alias RTableValue* RTable;

    struct TransposeBufferValue{};
    alias TransposeBufferValue* TransposeBuffer;

    void rfft(T* re, T* im, Table t, RTable rt);
    void irfft(T* re, T* im, Table t, RTable rt);
    RTable rfft_table(uint log2n, void* p = null);
    size_t rtable_size_bytes(int log2n);

    void deinterleave_array(T* even, T* odd, T* interleaved, size_t n);
    void interleave_array(T* even, T* odd, T* interleaved, size_t n);
    void scale(T* data, size_t n, T factor);
    //void cmul(T*, T*, T*, T*, size_t);
    size_t alignment(size_t n);

    struct ITableValue{};
    alias ITableValue* ITable;

    size_t itable_size_bytes(uint log2n);
    ITable interleave_table(uint log2n, void* p);
    void interleave(T* p, uint log2n, ITable table);
    void deinterleave(T* p, uint log2n, ITable table);

    void set_implementation(int);
    
    size_t transpose_buffer_size_bytes(int[] log2n);

    void fft_transposed(
        T* re,
        T* im,
        int log2stride, 
        int log2n,
        int log2m,
        Table tables,
        TransposeBuffer buffer);

    void multidim_fft(
        T* re,
        T* im,
        Table[] table, 
        TransposeBuffer buf);
}

