#include <stdio.h>
#include <stdlib.h>
#include <pfft_f.h>

int main(int argc, char **argv)
{
    size_t n = atoi(argv[1]);
    PfftTableF* tab = pfft_fft_table_allocate_f(&n, 1);
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
    pfft_fft_table_free_f(tab);
}
