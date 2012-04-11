#!/bin/sh

llvm-link llvm/shufps.ll -o shufps.bc

ldc2 -O3 -singleobj -output-bc test pfft/sse pfft/fft_impl.d pfft/bitreverse.d -d-version=ExternCShufps
llvm-link test.bc shufps.bc -o both.bc
opt -O3 -std-link-opts -std-compile-opts both.bc -o both.bc
llc both.bc -o both.s #-mattr=+avx
gcc both.s -L/opt/ldc/lib/ -ldruntime-ldc -lphobos-ldc -lrt -lpthread -ldl -lm -o test

ldc2 -O3 -singleobj -output-bc bench pfft/sse pfft/fft_impl.d pfft/bitreverse.d -d-version=ExternCShufps
llvm-link bench.bc shufps.bc -o both.bc
opt -O3 -std-link-opts -std-compile-opts both.bc -o both.bc
llc both.bc -o both.s #-mattr=+avx
gcc both.s -L/opt/ldc/lib/ -ldruntime-ldc -lphobos-ldc -lrt -lpthread -ldl -lm -o bench
