//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/**
Functions in this module can be used from both C and D. To use them from C, 
include pfft.h. Only the functions that operate on floats are listed here. To
calculate fft of doubles or reals (long doubles in C), just replace the "_f"
suffix on functions and "F" on types with "_d" or "_l" on functions and "D" or 
"L" on types. 

Example of using this module from C:
---
#include <stdio.h>
#include <stdlib.h>
#include <pfft.h>

int main(int argc, char **argv)
{
    int n = atoi(argv[1]);
    PfftTableF tab = pfft_table_f(n, 0);
    float *re = pfft_allocate_f(n);
    float *im = pfft_allocate_f(n);
    
    int i;
    for(i = 0; i < n; i++)
        scanf("%f %f", re + i, im + i);

    pfft_fft_f(re, im, tab);
       
    for(i = 0; i < n; i++)
        printf("%f %f\n", re[i], im[i]);

    pfft_free_f(re);
    pfft_free_f(im);
    pfft_table_free_f(tab);
}
---
 */
module pfft.clib;

/**
    A struct that contains precomputed tables used in $(D pfft_fft_f) and $(D pfft_ifft_f).
 */
struct PfftTableF{}

/**
Returns an instance $(D PfftTableF) suitable for computing discrete fourier
transforms on input sequences of length n (I will also use the name n 
to refer to the length of the input sequence in the function descriptions below).
If null is passed as mem, the function will
alocate the needed memory. In this case you should call $(D pfft_table_free_f) on 
the returned instance of $(D PfftTableF) when you are done with it. If a value 
different from null is passed as mem, the function does not allocate and 
uses memory at mem instead. In this case there should be at least 
$(D pfft_table_size_bytes_f) bytes of memory available at mem and it should be 
properly aligned. To find out what the proper alignment is, use $(D pfft_alignment_f).
 */
extern(C) PfftTableF pfft_table_f(size_t n, void* mem);

/**
This function returns the size of a memory block needed by $(D pfft_table_f). See
the description of $(D pfft_table_f) above. 
 */
extern(C) size_t pfft_table_size_bytes_f(size_t n);

/**
Frees the memory used by a $(D PfftTableF) instance. If you passed a pointer
different from null as a second parameter to $(D pfft_table_f) when creating 
the instance of $(D PfftTableF,) you should not call this function on it - 
you should take care of dealocating memory you used yoursef instead. 
 */
extern(C) void pfft_table_free_f(PfftTableF table);

/**
Computes discrete fourier transform. re should contain the real
part of the input sequence and im the imaginary part of the sequence. The
length of the input sequence should be equal to the number that was passed
to $(D pfft_table_f) when creating table. The method operates in place - the 
result is saved back to $(D_PARAM re) and $(D_PARAM im). Both arrays must 
be properly aligned. An easy way to obtain a properly aligned block of memory
is to use $(D pfft_allocate_f). If you want to take care of memory allocation in
some other way, you should make sure that the addresses re and im are multiples
of the number returned by $(D pfft_alignment_f).
 */  
extern(C) void pfft_fft_f(float* re, float* im, PfftTableF table);

/**
This function is an inverse of $(D pfft_fft_f,) scaled by n. See the
description of $(D pfft_fft_f).
 */
extern(C) void pfft_ifft_f(float* re, float* im, PfftTableF table);

/**
A struct that contains precomputed tables used in $(D pfft_rfft_f) and $(D pfft_irfft_f).
 */
struct PfftRTableF{}

/**
This function is used in the same way as $(D pfft_table_f,) the only difference is
that it returns an instance of struct $(D PfftRTableF).
 */
extern(C) PfftRTableF pfft_rtable_f(size_t n, void* mem);

/**
This function returns the size of a memory block needed by $(D pfft_rtable_f).
See the descriptions of $(D pfft_rtable_f) and $(D pfft_table_f).
 */
extern(C) size_t pfft_rtable_size_bytes_f(size_t n);

/**
This function is used in the same was as $(D pfft_table_free_f,) the only difference
is that it takes an instance of struct $(D PfftRTableF) as a parameter.
 */
extern(C) void pfft_rtable_free_f(PfftRTableF table);


/**
Calculates discrete fourier transform of the real valued sequence in data. 
The method operates in place. When the method completes, data contains the
result. First $(I n / 2 + 1) elements contain the real part of the result and 
the rest contains the imaginary part. Imaginary parts at position 0 and 
$(I n / 2) are known to be equal to 0 and are not stored, so the content of 
data looks like this: 

 $(D r(0), r(1), ... r(n / 2), i(1), i(2), ... i(n / 2 - 1))  


The elements of the result at position greater than $(I n / 2) can be trivially 
calculated from the relation $(I DFT(f)[i] = DFT(f)[n - i]*) that holds 
because the input sequence is real. 


The length of the array must be equal to n and the array must be properly 
aligned. To obtain a properly aligned array you can use $(D pfft_allocate_f).
If you want to take care of memory allocation in some other way, you should 
make sure that the address data is a multiple of the number returned by 
$(D pfft_alignment_f).
 */
extern(C) void pfft_rfft_f(float* data, PfftRTableF table);

/**
Calculates the inverse of $(D pfft_rfft_f), scaled by n. Before the method 
is called, data should contain a complex sequence in the same format as the 
result of $(D pfft_rfft_f). It is assumed that the input sequence is a discrete 
fourier transform of a real valued sequence, so the elements of the input 
sequence not stored in data can be calculated from 
$(I DFT(f)[i] = DFT(f)[n - i]*). When the method completes, the array 
contains the real part of the inverse discrete fourier transform of the 
input sequence, scaled by n. The imaginary part is known to be equal to zero.

The length of the array must be equal to n and the array must be properly 
aligned. To obtain a properly aligned array you can use $(D pfft_allocate_f).
If you want to take care of memory allocation in some other way, you should 
make sure that the address data is a multiple of the number returned by 
$(D pfft_alignment_f).
 */
extern(C) void pfft_irfft_f(float* data, PfftRTableF table);

/**
Returns appropriate alignment for use with functions in this module for a 
memory block of size nbytes.
 */
extern(C) size_t pfft_alignment_f(size_t nbytes);

/**
Returns a pointer to an array of size nelements, aligned apropriately for 
use with functions in this module.
 */
extern(C) float* pfft_allocate_f(size_t nelements);

/**
Frees memory allocated with $(D pfft_allocate_f).
 */
extern(C) void pfft_free_f(float* p);
