//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.impl_real;

import pfft.scalar_real, pfft.fft_impl;

alias TypeTuple!(FFT!(Vector!(), Options!())) FFTs;
mixin Instantiate!();
