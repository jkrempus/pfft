//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.impl_float;

import pfft.fft_impl;

version(SSE_AVX)
{
    import pfft.detect_avx;
    import sse = pfft.sse_float, avx = pfft.avx_float; 
    
    mixin Instantiate!(
        "float", get, FFT!(sse.Vector!(), sse.Options!()), avx);
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
    
    mixin Instantiate!("float", 0, FFT!(Vector!(),Options!()));
}
