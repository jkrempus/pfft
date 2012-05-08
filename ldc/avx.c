#include <immintrin.h>

__m256 insert128_0(__m256 a, __m128 b){ return _mm256_insertf128_ps(a, b, 0); }
__m256 insert128_1(__m256 a, __m128 b){ return _mm256_insertf128_ps(a, b, 1); }

__m128 extract128_0(__m256 a){ return _mm256_extractf128_ps(a, 0); }
__m128 extract128_1(__m256 a){ return _mm256_extractf128_ps(a, 1); }

__m256 interleave128_lo(__m256 a, __m256 b){ return _mm256_permute2f128_ps(a, b, _MM_SHUFFLE(0,2,0,0)); }
__m256 interleave128_hi(__m256 a, __m256 b){ return _mm256_permute2f128_ps(a, b, _MM_SHUFFLE(0,3,0,1)); }

__m256 broadcast128(__m128 *p) { return _mm256_broadcast_ps(p); }

__m256 unpckhps(__m256 a, __m256 b) { return _mm256_unpackhi_ps(a, b); }
__m256 unpcklps(__m256 a, __m256 b) { return _mm256_unpacklo_ps(a, b); }

