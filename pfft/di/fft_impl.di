module pfft.fft_impl;

struct FFTTable(T)
{
    T * table;
    uint * brTable;
}
