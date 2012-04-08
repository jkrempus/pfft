//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio;

enum shufpsTemplate = q{
auto shufps(int m0, int m1, int m2, int m3)(float4 a, float4 b)
{
	
	enum sm = m3 | (m2<<2) | (m1<<4) | (m0<<6);
	mixin("auto r = shufps" ~ sm.stringof ~ "(a, b);");
	return r;
}	
};

void main(string[] args)
{	
	if(args[1] == "c")
	{
		writeln("#include <xmmintrin.h>");
		
		foreach(i; 0 .. 256)
			writefln("__m128 shufps%d(__m128 a, __m128 b){ return _mm_shuffle_ps(a, b, %d); }", i, i);
	}
	else if(args[1] == "d")
	{
		writeln("import core.simd;");
		
		foreach(i; 0 .. 256)
			writefln("extern(C) float4 shufps%d(float4, float4);", i);
		
		writeln(shufpsTemplate);
	};
}
