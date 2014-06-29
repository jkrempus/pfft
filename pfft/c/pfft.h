#ifndef _PFFT_{TYPE}_H_
#define _PFFT_{TYPE}_H_

#include <stdint.h>
#include "pfft_declarations_{suffix}.h"

#ifdef __cplusplus
extern "C"
{
#endif

#ifndef _PFFT_ALLOCATION_HELPERS_
#define _PFFT_ALLOCATION_HELPERS_

#include <stdlib.h>

#if defined (__unix__) || (defined (__APPLE__) && defined (__MACH__))
#include <unistd.h>
#endif

#if defined _POSIX_VERSION && _POSIX_VERSION > 200112L
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

static void* pfft_allocate_{suffix}(size_t sz)
{
  void* p;
  if(posix_memalign(
      &p, pfft_recommended_alignment_{suffix}(sz, pfft_pagesize()), sz))
  {
      p = NULL;
  }
  
  return p;
}

#define pfft_free_{suffix} free

#elif defined __STDC_VERSION__ && __STDC_VERSION__ > 201112L

static void* pfft_allocate_{suffix}(size_t sz)
{
  return aligned_alloc(
      pfft_recommended_alignment_{suffix}(sz, pfft_pagesize()), sz);
}

#define pfft_free_{suffix} free
#else

static void* pfft_allocate_{suffix}(size_t size)
{
    return pfft_align_memory(
        size, malloc(pfft_align_memory_size(alignment, size)), pfft_pagesize());
}

static void* pfft_free_{suffix}(void* p) { free(pfft_align_memory_retrieve(p)); }
#endif
#endif

PfftTable{Suffix}* pfft_fft_table_allocate_{suffix}(size_t* nptr, size_t nlen)
{
    size_t sz = pfft_fft_table_size_{suffix}(nptr, nlen);
    return pfft_fft_table_{suffix}(nptr, nlen, pfft_allocate_{suffix}(sz));
}

void pfft_fft_table_free_{suffix}(PfftTable{Suffix}* table)
{
    pfft_free_{suffix}(pfft_fft_table_memory_{suffix}(table));
}

PfftRealTable{Suffix}* pfft_rfft_table_allocate_{suffix}(size_t* nptr, size_t nlen)
{
    size_t sz = pfft_fft_table_size_{suffix}(nptr, nlen);
    return pfft_rfft_table_{suffix}(nptr, nlen, pfft_allocate_{suffix}(sz));
}

void pfft_rfft_table_free_{suffix}(PfftRealTable{Suffix}* table)
{
    pfft_free_{suffix}(pfft_rfft_table_memory_{suffix}(table));
}

PfftMultiTable{Suffix}* pfft_multi_fft_table_allocate_{suffix}(size_t n)
{
    size_t sz = pfft_multi_fft_table_size_{suffix}(n);
    return pfft_multi_fft_table_{suffix}(n, pfft_allocate_{suffix}(sz));
}

void pfft_multi_fft_table_free_{suffix}(PfftMultiTable{Suffix}* table)
{
    pfft_free_{suffix}(pfft_multi_fft_table_memory_{suffix}(table));
}

PfftRealMultiTable{Suffix}* pfft_multi_rfft_table_allocate_{suffix}(size_t n)
{
    size_t sz = pfft_multi_rfft_table_size_{suffix}(n);
    return pfft_multi_rfft_table_{suffix}(n, pfft_allocate_{suffix}(sz));
}

void pfft_multi_rfft_table_free_{suffix}(PfftRealMultiTable{Suffix}* table)
{
    pfft_free_{suffix}(pfft_multi_rfft_table_memory_{suffix}(table));
}

#ifdef __cplusplus
}
#endif

#endif
