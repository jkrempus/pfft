module pfft_{suffix};

import pfft_declarations_{suffix};

/// Allocate an aligned block of memory, sz bytes large.
static void* pfft_allocate_{suffix}(size_t sz);

/// free a block of memory allocated with pfft_allocate_{suffix}
static void* pfft_free_{suffix}(void* p);

/**
  Allocates and initializes a PfftTable{Suffix}.

  Params:
    nptr = A pointer to the start of an array containing the data sizes.
           The ith entry in this array represents the size in the ith dimension
    nlen = The length of the array pointed to by nptr.
*/
PfftTable{Suffix}* pfft_fft_table_allocate_{suffix}(size_t* nptr, size_t nlen);

/** 
  Frees the memory allocated by pfft_fft_table_allocate_{suffix}
*/
void pfft_fft_table_free_{suffix}(PfftTable{Suffix}* table);

/**
  Allocates and initializes a PfftRealTable{Suffix}.

  Params:
    nptr = A pointer to the start of an array containing data sizes
           The ith entry in this array represents the size in the ith dimension
    nlen = The length of the array pointed to by nptr.
*/
PfftRealTable{Suffix}* pfft_rfft_table_allocate_{suffix}(size_t* nptr, size_t nlen);

/** 
  Frees the memory allocated by pfft_rfft_table_allocate_{suffix}
*/
void pfft_rfft_table_free_{suffix}(PfftRealTable{Suffix}* table);

/**
  Allocates and initializes a PfftMultiTable{Suffix}.

  Params:
    n = The transform size.
*/
PfftMultiTable{Suffix}* pfft_multi_fft_table_allocate_{suffix}(size_t n);

/** 
  Frees the memory allocated by pfft_multi_fft_table_allocate_{suffix}
*/
void pfft_multi_fft_table_free_{suffix}(PfftMultiTable{Suffix}* table);

/**
  Allocates and initializes a PfftRealMultiTable{Suffix}.

  Params:
    n = The transform size.
*/
PfftRealMultiTable{Suffix}* pfft_multi_rfft_table_allocate_{suffix}(size_t n);

/** 
  Frees the memory allocated by pfft_multi_rfft_table_allocate_{suffix}
*/
void pfft_multi_rfft_table_free_{suffix}(PfftRealMultiTable{Suffix}* table);
