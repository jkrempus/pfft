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
