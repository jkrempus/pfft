//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.impl_float;

import pfft.fft_impl;
import pfft.declarations;

version(SSE_AVX)
{
    import pfft.detect_avx;
    import sse = pfft.sse_float;
    
    mixin Instantiate!(
        "f", get, set, 
        FFT!(sse.Vector!(), sse.Options!()),
        Declarations!("f_avx", float));
}
else
{
    version(Scalar)
        import pfft.scalar_float;
    else version(Neon)
        import pfft.neon_float;
    else version(StdSimd)
        import pfft.stdsimd;
    else version(AVX)
        import pfft.avx_float;
    else version(SSE)
        import pfft.sse_float;

    mixin Instantiate!("f", 0, i => 0, FFT!(Vector!(),Options!()));
}
