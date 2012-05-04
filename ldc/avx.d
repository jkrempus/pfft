import core.simd;

extern(C) float8 insert128_0(float8, float4);
extern(C) float8 insert128_1(float8, float4);

extern(C) float4 extract128_0(float8);
extern(C) float4 extract128_1(float8);

extern(C) float8 interleave128_lo(float8, float8);
extern(C) float8 interleave128_hi(float8, float8);
