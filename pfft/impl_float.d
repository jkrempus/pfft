//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.impl_float;

version(Scalar)
{
    public import pfft.scalar;
}
else version(Neon)
{
    public import pfft.neon;
}
else version(StdSimd)
{
    public import pfft.stdsimd;
}
else version(AVX)
{
    public import pfft.avx;
}
else
{
    public import pfft.sse;
}

import pfft.fft_impl;

mixin(instantiate!(FFT!(Vector, Options))());
