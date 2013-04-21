module pfft.common;

import core.bitop;

alias bsr log2;

template TypeTuple(A...)
{
    alias A TypeTuple;
}

template st(alias a){ enum st = cast(size_t) a; }

struct Tuple(A...)
{
    A a;
    alias a this;
}

void swap(T)(ref T a, ref T b)
{
    auto aa = a;
    auto bb = b;
    b = aa;
    a = bb;
}

template ints_up_to(arg...)
{
    static if(arg.length == 1)
        alias ints_up_to!(0, arg[0], 1) ints_up_to;
    else static if(arg[0] < arg[1])
        alias 
            TypeTuple!(arg[0], ints_up_to!(arg[0] + arg[2], arg[1], arg[2])) 
            ints_up_to;
    else
        alias TypeTuple!() ints_up_to;
}

template powers_up_to(int n, T...)
{
    static if(n > 1)
    {
        alias powers_up_to!(n / 2, n / 2, T) powers_up_to;
    }
    else
        alias T powers_up_to;
}

template RepeatType(T, int n, R...)
{
    static if(n == 0)
        alias R RepeatType;
    else
        alias RepeatType!(T, n - 1, T, R) RepeatType;
}

version(LDC)
    pragma(LDC_intrinsic, "llvm.prefetch")
        void llvm_prefetch(void*, int, int, int);

void prefetch(bool isRead, bool isTemporal)(void* p)
{
    version(GNU)
    {
        import gcc.builtins;
        __builtin_prefetch(p, isRead ? 0 : 1, isTemporal ? 3 : 0);
    }
    else version(LDC)
        llvm_prefetch(p, isRead ? 0 : 1, isTemporal ? 3 : 0, 1);
}

void prefetch_array(int len, TT)(TT* a)
{
    enum elements_per_cache_line = 64 / TT.sizeof;

    foreach(i; ints_up_to!(len / elements_per_cache_line))
        prefetch!(true, true)(a + i * elements_per_cache_line);
}

