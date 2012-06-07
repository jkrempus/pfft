//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import core.sys.posix.stdlib, core.stdc.stdlib, core.stdc.stdio, core.bitop;

struct Table
{
    void *p;
    size_t log2n;
}

private void assert_power2(size_t n)
{
    if(n & (n - 1))
    {
        perror("Size passed to pfft functions must be a power of two.");
        abort(); 
    }
}


private template code(string type, string suffix)
{
    enum code = 
    `
        import impl_`~type~` = pfft.impl_`~type~`;

        extern(C) auto pfft_table_`~suffix~`(size_t n, void* mem)
        {
            assert_power2(n);

            auto log2n = bsf(n);

            if(mem is null)
                posix_memalign(&mem, impl_`~type~`.alignment(log2n), 
                    impl_`~type~`.table_size_bytes(log2n));

            return Table(impl_`~type~`.fft_table(bsf(n), mem), log2n);
        }

        extern(C) void pfft_fft_`~suffix~`(`~type~`* re, `~type~`* im, Table table)
        {
            impl_`~type~`.fft(re, im, cast(uint) table.log2n, table.p);
        }

        extern(C) size_t pfft_table_size_bytes_`~suffix~`(size_t n)
        {
            assert_power2(n);

            return impl_`~type~`.table_size_bytes(bsf(n));
        }

        extern(C) size_t pfft_alignment_`~suffix~`(size_t n)
        {
            assert_power2(n);

            return impl_`~type~`.alignment(bsf(n));
        }

        extern(C) `~type~`* pfft_allocate_`~suffix~`(size_t n)
        {
            assert_power2(n);

            void* p;
            posix_memalign(&p, impl_`~type~`.alignment(bsf(n)), `~type~`.sizeof * n);

            return cast(`~type~`*) p;
        }

        extern(C) void pfft_free_`~suffix~`(`~type~`* p)
        {
            free(p);
        }

        extern(C) void pfft_table_free_`~suffix~`(Table table)
        {
            free(table.p);
        }
    `;
}

version(Float)
    mixin(code!("float", "f"));

version(Double)
    mixin(code!("double", "d"));

version(Real)
    mixin(code!("real", "l"));
