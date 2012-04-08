import std.stdio;

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
	}
}
