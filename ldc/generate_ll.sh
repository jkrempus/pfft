#!/bin/bash
./generate_simd_functions.d c $1 | clang -x c - -mavx -c -O3 -emit-llvm -o - | llvm-link -S -

