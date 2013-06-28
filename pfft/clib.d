//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.clib;

import core.stdc.stdlib, core.stdc.string, core.bitop;
import pfft.common_templates;

version(Posix)
    import core.sys.posix.stdlib, core.sys.posix.unistd;

size_t max(size_t a, size_t b){ return a > b ? a : b; } 
size_t min(size_t a, size_t b){ return a < b ? a : b; } 

size_t pagesize()
{
    static if(is(typeof(sysconf)) && is(typeof(_SC_PAGESIZE)))
        return sysconf(_SC_PAGESIZE);
    else
        // just take a guees in this case
        return 4096;
}

static if(is(typeof(posix_memalign)))
{
    auto allocate_aligned(size_t alignment, size_t size)
    {
        void* ptr;
        posix_memalign(&ptr, alignment, size);
        return ptr;
    }

    alias free free_aligned;

    size_t alignment_(alias F)(size_t n)
    {
        n = cast(size_t) 1 << bsr(n); 

        return min(max(n, F.alignment(n)), pagesize());  
    }
}
else
{
    auto allocate_aligned(size_t alignment, size_t size)
    {
        enum psize = (void*).sizeof;
        auto p = malloc(size + alignment + psize);
        auto aligned = cast(void*)(
            (cast(size_t)p + psize + alignment) & ~(alignment - 1U));
        *cast(void**)(aligned - psize) = p;
        return aligned; 
    }

    void free_aligned(void* p)
    {
        free(*cast(void**)(p - (void*).sizeof)); 
    }

    size_t alignment_(alias F)(size_t n)
    {
        n = cast(size_t) 1 << bsr(n); 

        static if(is(typeof(sysconf)) && is(typeof(_SC_PAGESIZE)))
            size_t page_size = sysconf(_SC_PAGESIZE);
        else
            // just take a guees in this case
            enum page_size = 4096;

        enum cache_line = 64;       

            return pagesize(); // TODO: fix this
 
        if(n < 5 * page_size)
            // align to cache line at most to avoid wasting memory 
            return min(max(n, F.alignment(n)), cache_line);
        else
            // aligne to page size, the increase of memory size isn't that
            // signifficant in this case and this can improve performance
            return pagesize();
    }
}

private void assert_power2(size_t n)
{
    if((n & (n - 1)) || n == 0)
    {
        version(Posix)
        {
            import core.stdc.stdio; 
            fprintf(stderr, 
                "Size passed to pfft functions must be a power of two.\n");
        }
        exit(1); 
    }
}

size_t ptrsize_align(size_t n)
{
    return (n + (void*).sizeof) & ~((void*).sizeof - 1);
}

align(1) struct Table(T){}
align(1) struct RTable(T){}

private template cimpl(T)
{
    mixin("import impl = pfft.impl_"~T.stringof~";");

    auto compute_log2n_table(size_t* n, size_t nlen, uint* dst)
    {
        size_t j = 0;
        foreach(i; 0 .. nlen)
        {
            assert_power2(n[i]);
            if(n[i] > 1)
            {
                dst[j] = bsf(n[i]);
                j++;
            }
        }

        return dst[0 .. j]; 
    }

    size_t table_size(size_t* n, size_t nlen)
    {
        uint[8 * size_t.sizeof] log2n_mem;
        auto log2n = compute_log2n_table(n, nlen, log2n_mem.ptr);
        return impl.multidim_fft_table_size(log2n);
    }
    
    Table!T * table(size_t* n, size_t nlen, void* mem)
    {
        uint[8 * size_t.sizeof] log2n_mem;
        auto log2n = compute_log2n_table(n, nlen, log2n_mem.ptr);

        if(mem is null)
        {
            auto sz = table_size(n, nlen);
            mem = allocate_aligned(alignment_!(impl)(sz), sz);
        }

        return cast(Table!T*) impl.multidim_fft_table(log2n, mem);
    }

    void table_free(Table!T* table)
    {
        free_aligned(impl.multidim_fft_table_memory(
            cast(impl.MultidimTable) table));
    }
        
    void fft(T* re, T* im, Table!T* table)
    {
        auto p = cast(impl.MultidimTable) table;
        impl.multidim_fft(re, im, p);
    }

    void ifft(T* re, T* im, Table!T* table)
    {
        auto p = cast(impl.MultidimTable) table;
        impl.multidim_fft(im, re, p);
    }

    size_t rtable_size(size_t* n, size_t nlen)
    {
        uint[8 * size_t.sizeof] log2n_mem;
        auto log2n = compute_log2n_table(n, nlen, log2n_mem.ptr);
        log2n[0]--;
        return impl.multidim_rfft_table_size(log2n);
    }
    
    RTable!T * rtable(size_t* n, size_t nlen, void* mem)
    {
        uint[8 * size_t.sizeof] log2n_mem;
        auto log2n = compute_log2n_table(n, nlen, log2n_mem.ptr);
        log2n[0]--;

        if(mem is null)
        {
            auto sz = rtable_size(n, nlen);
            mem = allocate_aligned(alignment_!(impl)(sz), sz);
        }

        return cast(RTable!T*) impl.multidim_rfft_table(log2n, mem);
    }

    void rtable_free(RTable!T* table)
    {
        free_aligned(impl.multidim_rfft_table_memory(
            cast(impl.MultidimTable) table));
    }
        
    void rfft(T* data, RTable!T* table)
    {
        auto p = cast(impl.RealMultidimTable) table;
        impl.multidim_rfft(data, p);
    }

    void irfft(T* data, RTable!T* table)
    {
        auto p = cast(impl.RealMultidimTable) table;
        impl.multidim_irfft(data, p);
    }
        
    size_t alignment(size_t n)
    {
        return alignment_!(impl)(n / 2);
    }

    T* allocate(size_t n)
    {
        return cast(T*) 
            allocate_aligned(alignment_!(impl)(n), T.sizeof * n);
    }

    void free(T* p) { free_aligned(p); }
}

private template code(string type, string suffix, string Suffix)
{
    template generate_wrapper(string name_base)
    {
        enum name = `cimpl!`~type~`.`~name_base;
        enum wrapper_name = `pfft_`~name_base~`_`~suffix;
        mixin("alias "~name~" wrapped;"); 
        alias ParamTypeTuple!wrapped Params;
        alias typeof(wrapped(Params.init)) Return;

        template arg_list(int i, bool types)
        {
            static if(i == 0)
                enum arg_list = "";
            else
                enum arg_list = 
                    (i > 1 ? arg_list!(i - 1, types) ~ ", " : "") ~
                    (types ? Params[i - 1].stringof ~ " " : "") ~
                    "_" ~ i.stringof;
        }

        enum generate_wrapper = 
            Return.stringof ~ " " ~ 
            wrapper_name ~ "(" ~ arg_list!(Params.length, true) ~ "){ return " ~ 
            name ~ "(" ~ arg_list!(Params.length, false) ~ "); }\n";
    }

    enum cimpl_str = "cimpl!("~type~").";
    enum code = 
        generate_wrapper!"table_size" ~ 
        generate_wrapper!"table" ~ 
        generate_wrapper!"table_free" ~ 
        generate_wrapper!"fft" ~ 
        generate_wrapper!"ifft" ~
        generate_wrapper!"rtable_size" ~ 
        generate_wrapper!"rtable" ~ 
        generate_wrapper!"rtable_free" ~ 
        generate_wrapper!"rfft" ~ 
        generate_wrapper!"irfft" ~ 
        generate_wrapper!"alignment" ~ 
        generate_wrapper!"allocate" ~ 
        generate_wrapper!"free" ~ 
        "alias Table!"~type~" PfftTable"~Suffix~";\n" ~
        "alias RTable!"~type~" PfftRTable"~Suffix~";\n";
}

export:
extern(C):

version(Float)
    mixin(code!("float", "f", "F"));

version(Double)
    mixin(code!("double", "d", "D"));

version(Real)
    mixin(code!("real", "l", "L"));
