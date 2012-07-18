//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.clib;

import core.sys.posix.stdlib, core.stdc.stdlib, core.stdc.stdio, core.bitop;

private void assert_power2(size_t n)
{
    if(n & (n - 1))
    {
        fprintf(stderr, "Size passed to pfft functions must be a power of two.\n");
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
                posix_memalign(&mem, impl_`~type~`.alignment((cast(size_t) 1) << log2n), 
                    impl_`~type~`.table_size_bytes(log2n));

            return PfftTable`~Suffix~`(impl_`~type~`.fft_table(bsf(n), mem), log2n);
        }

        extern(C) void pfft_table_free_`~suffix~`(PfftTable`~Suffix~` table)
        {
            free(table.p);
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
            impl_`~type~`.Table table;
            impl_`~type~`.RTable rtable;
            impl_`~type~`.ITable itable;
            size_t log2n;
        }

        extern(C) size_t pfft_rtable_size_bytes_`~suffix~`(size_t n)
        {
            assert_power2(n);

            return 
                impl_`~type~`.table_size_bytes(bsf(n) - 1) +
                impl_`~type~`.itable_size_bytes(bsf(n)) +
                impl_`~type~`.rtable_size_bytes(bsf(n));
        }

        extern(C) auto pfft_rtable_`~suffix~`(size_t n, void* mem)
        {
            assert_power2(n);

            auto log2n = bsf(n);

            auto table_size = impl_`~type~`.table_size_bytes(bsf(n) - 1);
            auto rtable_size = impl_`~type~`.rtable_size_bytes(bsf(n));
            auto itable_size = impl_`~type~`.itable_size_bytes(bsf(n));

            /*if(mem is null)
                posix_memalign(&mem, impl_`~type~`.alignment((cast(size_t) 1) << log2n), 
                    table_size + rtable_size + itable_size);*/

            void* rmem, imem;
               
            posix_memalign(&mem, impl_`~type~`.alignment(table_size), table_size);
            posix_memalign(&rmem, impl_`~type~`.alignment(rtable_size), rtable_size);
            posix_memalign(&imem, impl_`~type~`.alignment(itable_size), itable_size);

            return PfftRTable`~Suffix~`(
                impl_`~type~`.fft_table(bsf(n) - 1, mem), 
                impl_`~type~`.rfft_table(bsf(n), rmem), 
                impl_`~type~`.interleave_table(bsf(n), imem), 
                log2n);
        }

        extern(C) void pfft_rtable_free_`~suffix~`(PfftRTable`~Suffix~` table)
        {
            free(table.table);
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

            void* p;
            posix_memalign(&p, impl_`~type~`.alignment(n), `~type~`.sizeof * n);

            return cast(`~type~`*) p;
        }

        extern(C) void pfft_free_`~suffix~`(`~type~`* p)
        {
            free(p);
        }
    `;
}

version(Float)
    mixin(code!("float", "f", "F"));

version(Double)
    mixin(code!("double", "d", "D"));

version(Real)
    mixin(code!("real", "l", "D"));
