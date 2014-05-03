#ifndef _PFFT_{TYPE}_H_
#define _PFFT_{TYPE}_H_

#include <stdint.h>
#include "pfft_declarations.h"

#ifdef __cplusplus
extern "C"
{
#endif

#ifndef _PFFT_ALLOCATION_HELPERS_
#define _PFFT_ALLOCATION_HELPERS_

#include <stdlib.h>

#if defined _POSIX_VERSION && _POSIX_VERSION > 200112L
#include <unistd.h>
static size_t pfft_pagesize(){ return sysconf(_SC_PAGESIZE); }
#elif defined _MSC_VER
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
static size_t pfft_pagesize()
{
    SYSTEM_INFO info;
    GetSystemInfo(&info);
    return (size_t) info.dwPageSize;
}
#undef WIN32_LEAN_AND_MEAN
#endif

#if defined _POSIX_VERSION && _POSIX_VERSION > 200112L
#include <unistd.h>

static void* pfft_aligned_alloc(size_t alignment, size_t size)
{
    void* p;
    if(posix_memalign(&p, alignment, size)) p = NULL;
    return p;
}

#define pfft_aligned_free free

static void* pfft_recommended_alignment(size_t sz, size_t minimal_alignment)
{
    return pfft_recommended_alignment_native(
        sz, minimal_alignment, pfft_pagesize());
}

#elif defined __STDC_VERSION__ && __STDC_VERSION__ > 201112L
#define pfft_aligned_alloc aligned_alloc
#define pfft_aligned_free free
static void* pfft_recommended_alignment(size_t sz, size_t minimal_alignment)
{
    return pfft_recommended_alignment_native(
        sz, minimal_alignment, pfft_pagesize());
}
#else

static void* pfft_aligned_alloc(size_t alignment, size_t size)
{
    return pfft_align(alignment, size,
        malloc(apfft_align_size(alignment, size)));
}

static void* pfft_aligned_free(void* p) { free(pfft_memory(p)); }

static void* pfft_recommended_alignment(size_t sz, size_t minimal_alignment)
{
    return pfft_recommended_alignment_non_native(
        sz, minimal_alignment, 64, pfft_pagesize());
}
#endif
#endif

PfftTable{Suffix} pfft_fft_table_allocate_{suffix}(size_t* nptr, size_t nlen)
{
    size_t sz = pfft_fft_table_size_{suffix}(nptr, len);
    size_t alignment = pfft_recommended_alignment(sz, pfft_alignment_{suffix}(sz));
    return pfft_fft_table(nptr, nlen, pfft_aligned_alloc(alignment, sz));
}

void pfft_fft_table_free_{suffix}(PfftTable{Suffix} table)
{
    pfft_aligned_free(pfft_fft_table_memory_{suffix}(table));
}

PfftRealTable{Suffix} pfft_rfft_table_allocate_{suffix}(size_t* nptr, size_t nlen)
{
    size_t sz = pfft_fft_table_size_{suffix}(nptr, len);
    size_t alignment = pfft_recommended_alignment(sz, pfft_alignment_{suffix}(sz));
    return pfft_rfft_table(nptr, nlen, pfft_aligned_alloc(alignment, sz));
}

void pfft_rfft_table_free_{suffix}(PfftRealTable{Suffix} table)
{
    pfft_aligned_free(pfft_rfft_table_memory_{suffix}(table));
}

PfftMultiTable{Suffix} pfft_fft_table_allocate_{suffix}(size_t* nptr, size_t nlen)
{
    size_t sz = pfft_fft_table_size_{suffix}(nptr, len);
    size_t alignment = pfft_recommended_alignment(sz, pfft_alignment_{suffix}(sz));
    return pfft_fft_table(nptr, nlen, pfft_aligned_alloc(alignment, sz));
}

void pfft_fft_table_free_{suffix}(PfftMultiTable{Suffix} table)
{
    pfft_aligned_free(pfft_fft_table_memory_{suffix}(table));
}

PfftRealMultiTable{Suffix} pfft_rfft_table_allocate_{suffix}(size_t* nptr, size_t nlen)
{
    size_t sz = pfft_fft_table_size_{suffix}(nptr, len);
    size_t alignment = pfft_recommended_alignment(sz, pfft_alignment_{suffix}(sz));
    return pfft_rfft_table(nptr, nlen, pfft_aligned_alloc(alignment, sz));
}

void pfft_rfft_table_free_{suffix}(PfftRealMultiTable{Suffix} table)
{
    pfft_aligned_free(pfft_rfft_table_memory_{suffix}(table));
}

#ifdef __cplusplus
}
#endif

#endif
