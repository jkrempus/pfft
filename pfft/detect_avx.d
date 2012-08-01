module pfft.detect_avx;

private __gshared int avx_state;

private void set_avx_state()
{
    enum xcr0_avx_shift = 2;            // AVX enabled by OS
    enum cpuid_avx = 1 << 28;           // processor supports AVX
    enum cpuid_xsave = 1 << 26;         // processor supports xgetbv
    enum mask = cpuid_avx | cpuid_xsave;

    int r = void;
    version(GNU)
        asm
        {
            "mov $1, %%eax
            cpuid
            mov $0, %%eax
            and $0x14000000, %%ecx
            cmp $0x14000000, %%ecx
            jne exit_label%=
            xor %%ecx, %%ecx
            xgetbv
            shr $2, %%eax
            and $1, %%eax
        exit_label%=: 
            mov %%eax, %0"
            : "=r" r
            :
            : "eax", "ebx", "ecx", "edx" ;
        }
    else
        asm
        {
            mov EAX, 1;
            cpuid;
            mov EAX, 0;
            and ECX, mask;
            cmp ECX, mask;
            jne exit_label;
            xor ECX, ECX;
            xgetbv;
            shr EAX, xcr0_avx_shift;
            and EAX, 1;
        exit_label:
            mov r, EAX;
        }
    
    avx_state = r | 2;  
}

@property get()()
{
    if(!avx_state)
        set_avx_state();

    return avx_state & 1;
}

