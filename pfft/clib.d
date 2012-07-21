//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.clib;

import core.stdc.stdlib, core.bitop;

version(Windows)
{
	
    extern(Windows) void * _aligned_malloc( size_t size, size_t alignment);
    extern(Windows) void _aligned_free(void*);

    auto allocate_aligned(size_t alignment, size_t size)
    {
        return _aligned_malloc(size, alignment);
    }

    alias _aligned_free free_aligned;
}
else
{
    extern(C) void *memalign(size_t alignment, size_t size);

    import core.sys.posix.stdlib; 
    
    auto allocate_aligned(size_t alignment, size_t size)
    {
        version(Android)
            return memalign(alignment, size);
        else
        {
            void* ptr;
            posix_memalign(&ptr, alignment, size);
            return ptr;
        }
    }

    alias free free_aligned;
}

private void assert_power2(size_t n)
{
    if(n & (n - 1))
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

private template code(string type, string suffix, string Suffix)
{
    enum code = 
    `
        import impl_`~type~` = pfft.impl_`~type~`;

        /// A documentation comment. 
        struct PfftTable`~Suffix~`
        {
            impl_`~type~`.Table p;
            size_t log2n;
        }

        extern(C) size_t pfft_table_size_bytes_`~suffix~`(size_t n)
        {
            assert_power2(n);

            return impl_`~type~`.table_size_bytes(bsf(n));
        }

        extern(C) auto pfft_table_`~suffix~`(size_t n, void* mem)
        {
            assert_power2(n);

            auto log2n = bsf(n);

            if(mem is null)
                mem = allocate_aligned(impl_`~type~`.alignment((cast(size_t) 1) << log2n), 
                    impl_`~type~`.table_size_bytes(log2n));

            return PfftTable`~Suffix~`(impl_`~type~`.fft_table(bsf(n), mem), log2n);
        }

        extern(C) void pfft_table_free_`~suffix~`(PfftTable`~Suffix~` table)
        {
            free_aligned(table.p);
        }

        extern(C) void pfft_fft_`~suffix~`(`~type~`* re, `~type~`* im, PfftTable`~Suffix~` table)
        {
            impl_`~type~`.fft(re, im, cast(uint) table.log2n, table.p);
        }

        extern(C) void pfft_ifft_`~suffix~`(`~type~`* re, `~type~`* im, PfftTable`~Suffix~` table)
        {
            impl_`~type~`.fft(im, re, cast(uint) table.log2n, table.p);
        }

        struct PfftRTable`~Suffix~`
        {
            impl_`~type~`.RTable rtable;
            impl_`~type~`.Table table;
            impl_`~type~`.ITable itable;
            size_t log2n;
        }

        extern(C) size_t pfft_rtable_size_bytes_`~suffix~`(size_t n)
        {
            assert_power2(n);

            return 
                impl_`~type~`.itable_size_bytes(bsf(n)) +
                impl_`~type~`.table_size_bytes(bsf(n) - 1) +
                impl_`~type~`.rtable_size_bytes(bsf(n));
        }

        extern(C) auto pfft_rtable_`~suffix~`(size_t n, void* mem)
        {
            assert_power2(n);

            auto log2n = bsf(n);

            auto rtable_size = impl_`~type~`.rtable_size_bytes(log2n);
            auto table_size = impl_`~type~`.table_size_bytes(log2n - 1);
            auto itable_size = impl_`~type~`.itable_size_bytes(log2n);

            auto sz = table_size + rtable_size + itable_size;
            auto al = impl_`~type~`.alignment(sz);

            if(mem is null)
                mem = allocate_aligned(al, sz);

            return PfftRTable`~Suffix~`(
                impl_`~type~`.rfft_table(log2n, mem), 
                impl_`~type~`.fft_table(log2n - 1, mem + rtable_size), 
                impl_`~type~`.interleave_table(log2n, mem + rtable_size + table_size), 
                log2n);
        }

        extern(C) void pfft_rtable_free_`~suffix~`(PfftRTable`~Suffix~` table)
        {
            free_aligned(table.rtable);
        }

        extern(C) void pfft_rfft_`~suffix~`(`~type~`* data, PfftRTable`~Suffix~` table)
        {
            impl_`~type~`.deinterleave(data, cast(uint) table.log2n, table.itable);
            impl_`~type~`.rfft(
                data, data + ((cast(size_t) 1) << (table.log2n - 1)), 
                cast(uint) table.log2n, table.table, table.rtable); 
        }

        extern(C) void pfft_irfft_`~suffix~`(`~type~`* data, PfftRTable`~Suffix~` table)
        {
            impl_`~type~`.irfft(
                data, data + ((cast(size_t) 1) << (table.log2n - 1)),
                cast(uint) table.log2n, table.table, table.rtable); 
            impl_`~type~`.interleave(data, cast(uint) table.log2n, table.itable);
        }

        extern(C) size_t pfft_alignment_`~suffix~`(size_t n)
        {
            assert_power2(n);

            return impl_`~type~`.alignment(n);
        }

        extern(C) `~type~`* pfft_allocate_`~suffix~`(size_t n)
        {
            assert_power2(n);

            auto p = allocate_aligned(impl_`~type~`.alignment(n), `~type~`.sizeof * n);

            return cast(`~type~`*) p;
        }

        extern(C) void pfft_free_`~suffix~`(`~type~`* p)
        {
            free_aligned(p);
        }
    `;
}

version(Float)
    mixin(code!("float", "f", "F"));

version(Double)
    mixin(code!("double", "d", "D"));

version(Real)
    mixin(code!("real", "l", "L"));
