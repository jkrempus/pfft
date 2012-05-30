#!/bin/bash

/opt/ldc-3.1/bin/ldc2 -O3 -release -singleobj -output-bc test.d \
    ../pfft/stdapi.d ../pfft/splitapi.d ../pfft/impl_float.d \
    ../pfft/sse.d ../pfft/fft_impl.d ../pfft/bitreverse.d
llvm-link ../ldc/shufps.ll test.bc -o both.bc
opt -O3 -std-link-opts -std-compile-opts both.bc -o both.bc
llc both.bc -o both.s #-mattr=+avx
gcc both.s -L/opt/ldc-3.1/lib/ -ldruntime-ldc -lphobos-ldc -lrt -lpthread -ldl -lm -o test
