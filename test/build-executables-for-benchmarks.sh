#!/bin/bash

types="float double real"

(cd ..; ./build.d --simd sse-avx; ./build.d --tests --dflags "-version=BenchFftw -L-L/opt/fftw/lib -L-lfftw3f -L-lfftw3 -L-lfftw3l")
for t in $types
do
    mv test_"$t" test_"$t"_sse_avx
done


(cd ..; ./build.d --simd sse; ./build.d --tests --dflags "-version=BenchFftw -L-L/opt/fftw-sse/lib -L-lfftw3f -L-lfftw3 -L-lfftw3l")
for t in $types
do
    mv test_"$t" test_"$t"_sse
done


(cd ..; ./build.d --simd scalar; ./build.d --tests)
for t in $types
do
    mv test_"$t" test_"$t"_scalar
done

(cd ..; ./build.d --simd sse --type float --dc DMD; ./build.d --tests --type float --dc DMD)
mv test_float test_float_sse_dmd

(cd ..; ./build.d --simd sse --type float --dc LDC; ./build.d --tests --type float --dc LDC)
mv test_float test_float_sse_ldc

cp test_float_sse test_float_sse_gdmd
