module pfft.common;

T max(T)(T a, T b){ return a > b ? a : b; }
T min(T)(T a, T b){ return a < b ? a : b; }

import core.bitop;
public import core.stdc.string;
public import pfft.common_templates;

alias bsr log2;

uint first_set_bit(size_t a)
{ 
    return a == 0 ? 8 * size_t.sizeof : bsf(a); 
}

size_t exp2(uint a){ return st!1 << a; }

size_t next_pow2(size_t a)
{
    return a == 0 ? 1 : exp2(bsr(2 * a - 1));
}

template select(bool select_first, alias first, alias second)
{
    static if(select_first)
        alias first select;
    else
        alias second select;
}

struct Tuple(A...)
{
    A a;
    alias a this;
}

version(GNU)
{
    public import gcc.attribute;
    enum private_decl = attribute("private");
    enum noinline = attribute("noinline");
    enum always_inline = attribute("forceinline");
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

U[] array_cast(U, T)(T[] arr)
{
    return (cast(U*) arr.ptr)[0 .. arr.length * T.sizeof / U.sizeof];
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

size_t align_size(T)(size_t size)
{
    enum mask = T.alignof - 1;
    return (size + mask) & ~mask; 
}

@property front(T)(T[] a){ return a[0]; }
@property empty(T)(T[] a){ return a.length == 0; }
void popFront(T)(ref T[] a){ a = a[1 .. $]; }

auto map(alias mapper, R)(R r)
{
    static struct Result
    {
        R r;
        @property empty(){ return r.empty(); } 
        @property front(){ return mapper(r.front()); }
        void popFront(){ r.popFront(); } 
    }

    return Result(r);
}

T reduce(alias reducer, T, R)(T seed, R a)
{
    foreach(e; a)
        seed = reducer(seed, e);

    return seed;
}

auto sum(R)(R r)
{
    typeof(r.front) seed = 0;
    return reduce!((a, e) => a + e)(seed, r); 
}

R dropExactly(R)(R r, size_t n)
{
    foreach(i; 0 .. n)
        r.popFront();

    return r;
}

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

template SelectImplementation(Implementations...)
{
    @always_inline: 

    template call(string func_name)
    {
        auto call(A...)(uint selection, A args)
        {
            mixin(
                "alias ReturnType!(Implementations[0]." ~
                func_name ~ ") Ret;");

            foreach(i, I; Implementations)
                if(i == selection)
                {
                    mixin("alias I." ~ func_name ~ " func;");

                    ParamTypeTuple!(func) fargs;

                    foreach(j, _; fargs)
                        fargs[j] = cast(typeof(fargs[j])) args[j];

                    return cast(Ret) func(fargs);
                }

            assert(false);
        }
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

    void initialize(){ end = 0; }

    void add(T)(T** ptr, size_t n)
    {
        buf[end] = Entry(cast(void**) ptr, n * T.sizeof, T.alignof - 1);
        end++;
    }

    void iter(alias f, Args...)(Args args)
    {
        insertion_sort!((a, b) => 
            first_set_bit(a.size) > first_set_bit(b.size))(buf[0 .. end]);

        size_t istart = 0;
        foreach(i; 0 ..end)
        {
            istart = (istart + buf[i].align_mask) & ~buf[i].align_mask;
            auto iend = istart + buf[i].size;
            f(i, istart, iend, args);
            istart = iend;
        }
    }

    size_t size()
    {
        size_t r;
        static void f(size_t i, size_t s, size_t e, size_t* p){ *p = e; }
        iter!f(&r);
        return r;
    }

    void allocate(void* ptr)
    {
        static void f(S)(size_t i, size_t s, size_t e, void* p, S self)
        { 
            *self.buf[i].ptr = p + s; 
        }

        iter!f(ptr, &this);
//        import core.memory;
//        foreach(i; 0 .. end)
//            *buf[i].ptr = GC.malloc(buf[i].size);
    }
}
