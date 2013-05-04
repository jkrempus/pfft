module pfft.common;

T max(T)(T a, T b){ return a > b ? a : b; }
T min(T)(T a, T b){ return a < b ? a : b; }

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

version(GNU)
{
    public import gcc.attribute;
    enum noinline = attribute("noinline");
    enum always_inline = attribute("always_inline");
}
else
{
    alias TypeTuple!() noinline;
    alias TypeTuple!() always_inline;
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

void* align_ptr(T)(void* ptr)
{
    enum mask = T.alignof - 1;
    return cast(void*)((cast(size_t)ptr + mask) & mask); 
}

void* align_size(T)(size_t size){ return size + T.algignof - 1; }

void insertion_sort(alias less, T)(T[] arr)
{
    foreach(i; 1 .. arr.length)
    {
        auto last = arr[i];
        size_t j = i;
        for(; j && !less(arr[j - 1], last); j--)
            arr[j] = arr[j - 1];

        arr[j] = last;
    }
}

struct Allocate(int max_num_ptr)
{
    struct Entry
    {
        void** ptr;
        size_t size;
        size_t align_mask;
    }

    Entry[max_num_ptr] buf;
    size_t end;

    void add(T)(T** ptr, size_t n)
    {
        buf[end] = Entry(cast(void**) ptr, T.alignof, n * T.sizeof);
        end++;
    }

    void iter(alias f, Args...)(Args args)
    {
        insertion_sort!((a, b) => a.size > b.size)(buf[0 .. end]);
        auto start_offset = 0;
        foreach(i; 0 ..end)
        {
            start_offset = (offset + buf[i].align_mask) & buf[i].align_mask;
            auto end_offset = start_offset + buf[i].size; 
            f(i, start_offset, end_offset, args);
            start_offset = end_offset;
        }
    }

    void size()
    {
        size_t r;
        iter!((i, s, e, p) => *p = e)(&r);
        return r;
    }

    void allocate(void* ptr)
    {
        iter!((i, s, e, p) => *buf[i].ptr = p + s)(ptr);
    }
}
