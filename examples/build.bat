gdc -o pfft_example.exe pfft_example.d -I ..\generated\include -L ..\generated\lib -lpfft

gdc -o pfft_real_example.exe pfft_real_example.d -I ..\generated\include -L ..\generated\lib -lpfft

gdc -o std_example.exe std_example.d -I ..\generated\include -L ..\generated\lib -lpfft

gdc -o std_real_example.exe std_real_example.d -I ..\generated\include -L ..\generated\lib -lpfft

gcc -o c_example.exe c_example.c -I ..\generated-c\include -L ..\generated-c\lib -lpfft-c

cl c_real_example.c /I..\generated-c\include ../generated-c/lib/pfft-c-msvc.lib

copy ..\generated-c\lib\pfft-c.dll .
