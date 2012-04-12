//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.scalar_real;

import pfft.fft_impl;

struct Options
{
    enum log2_bitreverse_large_chunk_size = 5;
    enum large_limit = 12;
    enum log2_optimal_n = 9;
    enum passes_per_recursive_call = 4;
    enum log2_recursive_passes_chunk_size = 5;
    enum { fast_init };
}
mixin Instantiate!(FFT!(Scalar!real,Options));
