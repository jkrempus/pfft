module pfft.impl_double;

alias double T;

struct TableValue{};
alias TableValue* Table;

void fft(T* re, T* im, uint log2n, Table t);
Table fft_table(uint log2n, void* p = null);
size_t table_size_bytes(uint log2n);

struct RTableValue{};
alias RTableValue* RTable;

void rfft(T* re, T* im, uint log2n, Table t, RTable rt);
void irfft(T* re, T* im, uint log2n, Table t, RTable rt);
RTable rfft_table(uint log2n, void* p = null);
size_t rtable_size_bytes(int log2n);

void deinterleaveArray(T* even, T* odd, T* interleaved, size_t n);
void interleaveArray(T* even, T* odd, T* interleaved, size_t n);
void scale(T* data, size_t n, T factor);
size_t alignment(uint log2n);
