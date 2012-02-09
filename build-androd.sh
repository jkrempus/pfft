#!/bin/sh

# Tested with the toolchain from here: https://bitbucket.org/goshawk/gdc/wiki/GDC%20on%20Android .
# I have replaced main() from druntime with one that only calls the d 
# main. and set __USE_LARGEFILE64 in druntime to false.
# dummy.d is needed to satisfy the linker

arm-linux-androideabi-gdc -nophoboslib -lgdruntime -O3 -frelease \
    -finline -fweb -fversion=NoPhobos -fversion=Neon -fversion=Android \
    -mcpu=cortex-a8  -mfpu=neon -mfloat-abi=softfp \
    -o bench bench.d pfft/fft_impl.d pfft/neon.d pfft/bitreverse.d \
    dummy.d
    
arm-linux-androideabi-gdc -nophoboslib -lgdruntime -O3 -frelease \
    -finline -fweb -fversion=NoPhobos -fversion=Neon -fversion=Android \
    -mcpu=cortex-a8  -mfpu=neon -mfloat-abi=softfp \
    -o test_nophobos test_nophobos.d pfft/fft_impl.d pfft/neon.d \
    pfft/bitreverse.d pfft/scalar.d dummy.d
