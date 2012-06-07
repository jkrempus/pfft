//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.impl_float;

version(Scalar)
{
    public import pfft.scalar_float;
}
else version(Neon)
{
    public import pfft.neon_float;
}
else version(StdSimd)
{
    public import pfft.stdsimd;
}
else version(AVX)
{
    public import pfft.avx_float;
}
else
{
    public import pfft.sse_float;
}

import pfft.fft_impl;

mixin(instantiate!(FFT!(Vector, Options)));
