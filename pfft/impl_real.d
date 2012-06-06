module pfft.impl_real;

public import pfft.scalar_real;

import pfft.fft_impl;

mixin(instantiate!(FFT!(Vector, Options)));
