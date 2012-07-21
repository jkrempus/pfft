#!/bin/bash

types="float double real"

(cd ..; ./build.d --simd AVX; ./build.d --tests)
for t in $types
do
    mv test_"$t" test_"$t"_avx
done


(cd ..; ./build.d --simd SSE; ./build.d --tests)
for t in $types
do
    mv test_"$t" test_"$t"_sse
done


(cd ..; ./build.d --simd Scalar; ./build.d --tests)
for t in $types
do
    mv test_"$t" test_"$t"_scalar
done

(cd ..; ./build.d --simd SSE --type float --dc DMD; ./build.d --tests --type float --dc DMD)
mv test_float test_float_sse_dmd

(cd ..; ./build.d --simd SSE --type float --dc LDC; ./build.d --tests --type float --dc LDC)
mv test_float test_float_sse_ldc

cp test_float_avx test_float_avx_gdmd
