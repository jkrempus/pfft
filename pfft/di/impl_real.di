module pfft.impl_float;

alias real T;
alias void* Table;

void fft(T* re, T* im, uint log2n, Table t);
Table fft_table(uint log2n, void* p = null);
size_t table_size_bytes(uint log2n);
void deinterleaveArray(T* even, T* odd, T* interleaved, size_t n);
void interleaveArray(T* even, T* odd, T* interleaved, size_t n);
size_t alignment(uint log2n);
