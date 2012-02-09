//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.scalar;

import pfft.fft_impl;

struct Options
{
    enum log2_bitreverse_large_chunk_size = 6;
    enum large_limit = 14;
    enum log2_optimal_n = 11;
    enum passes_per_recursive_call = 6;
    enum log2_recursive_passes_chunk_size = 6;
}


alias FFT!(Scalar!float,Options) S;
alias FFT!(Scalar!double,Options) SD;

void fft(float* re, float* im, int log2n, S.Tables tables)
{
    S.fft(re, im, log2n, tables);
}

auto fft_table(int log2n)
{
    return S.tables(log2n);
}

void fft(double* re, double* im, int log2n, SD.Tables tables)
{
    SD.fft(re, im, log2n, tables);
}

auto fft_table_d(int log2n)
{
    return SD.tables(log2n);
}
