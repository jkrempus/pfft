#include <stdio.h>
#include <stdlib.h>
#include <pfft.h>

int main(int argc, char **argv)
{
    int n = atoi(argv[1]);
    PfftRTableF tab = pfft_rtable_f(n, 0);
    float *data = pfft_allocate_f(n);
    
    int i;
    for(i = 0; i < n; i++)
        scanf("%f", data + i);

    pfft_rfft_f(data, tab);
       
    for(i = 0; i < n / 2 + 1; i++)
        printf("%f %f\n", data[i], i == 0 || i == n / 2 ? 0 : data[i + n / 2]);

    pfft_free_f(data);
    pfft_rtable_free_f(tab);
}
