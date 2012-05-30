#!/usr/bin/env rdmd
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio;

enum usage = `
Usage:
    %s [c|d] [avx|sse]
`;

enum shufpsTemplate = 
q{
    auto shufps(int m0, int m1, int m2, int m3)(%s a, %s b)
    {

        enum sm = m3 | (m2<<2) | (m1<<4) | (m0<<6);
        mixin("auto r = shufps" ~ sm.stringof ~ "(a, b);");
        return r;
    }    
};

enum avxDCode = 
q{
    extern(C) float8 insert128_0(float8, float4);
    extern(C) float8 insert128_1(float8, float4);

    extern(C) float4 extract128_0(float8);
    extern(C) float4 extract128_1(float8);

    extern(C) float8 interleave128_lo(float8, float8);
    extern(C) float8 interleave128_hi(float8, float8);

    extern(C) float8 broadcast128(float4*);

    extern(C) float8 unpckhps(float8, float8);
    extern(C) float8 unpcklps(float8, float8);
};

enum avxCCode = 
q{
    __m256 insert128_0(__m256 a, __m128 b){ return _mm256_insertf128_ps(a, b, 0); }
    __m256 insert128_1(__m256 a, __m128 b){ return _mm256_insertf128_ps(a, b, 1); }

    __m128 extract128_0(__m256 a){ return _mm256_extractf128_ps(a, 0); }
    __m128 extract128_1(__m256 a){ return _mm256_extractf128_ps(a, 1); }

    __m256 interleave128_lo(__m256 a, __m256 b){ return _mm256_permute2f128_ps(a, b, _MM_SHUFFLE(0,2,0,0)); }
    __m256 interleave128_hi(__m256 a, __m256 b){ return _mm256_permute2f128_ps(a, b, _MM_SHUFFLE(0,3,0,1)); }

    __m256 broadcast128(__m128 *p) { return _mm256_broadcast_ps(p); }

    __m256 unpckhps(__m256 a, __m256 b) { return _mm256_unpackhi_ps(a, b); }
    __m256 unpcklps(__m256 a, __m256 b) { return _mm256_unpacklo_ps(a, b); }

};

void printUsage(string[] args)
{
    stderr.writefln(usage, "generate_shufps_code");
}

void main(string[] args)
{    
    if(args.length != 3 || !(args[2] == "avx" || args[2] == "sse" ))
        return printUsage(args);
    
    if(args[1] == "c")
    {
        auto t = args[2] == "avx" ? "__m256" : "__m128";
        auto s = args[2] == "avx" ? "256" : "";

        writefln("#include <%smmintrin.h>", args[2] == "avx" ? "i" : "x");
             
        foreach(i; 0 .. 256)
            writefln("%s shufps%d(%s a, %s b){ return _mm%s_shuffle_ps(a, b, %d); }", t, i, t, t, s, i);
        
        if(args[2] == "avx")
            writefln(avxCCode);
    }
    else if(args[1] == "d")
    {
        auto t = args[2] == "avx" ? "float8" : "float4";

        writeln("import core.simd;");

        foreach(i; 0 .. 256)
            writefln("extern(C) %s shufps%d(%s, %s);", t, i, t, t);
        
        writefln(shufpsTemplate, t, t);
        
        if(args[2] == "avx")
            writefln(avxDCode);
    }
    else
        printUsage(args);
}
