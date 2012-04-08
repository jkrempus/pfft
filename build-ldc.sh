#!/bin/sh

llvm-link llvm/shufps.ll -o shufps.bc

ldc2 -O5 -singleobj -output-bc test pfft/sse pfft/fft_impl.d pfft/bitreverse.d -d-version=ExternCShufps
llvm-ld -native -L/opt/ldc/lib/ -ldruntime-ldc -lphobos-ldc -lrt -lpthread -ldl -lm -o test test.bc shufps.bc

ldc2 -O5 -singleobj -output-bc bench pfft/sse pfft/fft_impl.d pfft/bitreverse.d -d-version=ExternCShufps
llvm-ld -native -L/opt/ldc/lib/ -ldruntime-ldc -lphobos-ldc -lrt -lpthread -ldl -lm -o bench bench.bc shufps.bc
