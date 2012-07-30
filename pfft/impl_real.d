//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.impl_real;

public import pfft.scalar_real;

import pfft.fft_impl;

alias FFT!(Vector, Options) F;
mixin Instantiate!();
