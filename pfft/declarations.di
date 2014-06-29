module pfft.declarations;

template ct_mapjoin(alias mapper, string separator, args...)
{
    static if(args.length == 0)
        enum ct_mapjoin = "";
    else 
        enum ct_mapjoin = 
            mapper!(args[0]) ~ 
            (args.length == 1 ? "" : separator) ~ 
            ct_mapjoin!(mapper, separator, args[1..$]);
}

template type_name(string lang, alias t)
{
    static if(is(typeof(t) == string))
        enum type_name = t;
    else 
        enum type_name = lang == "d" ? t.dtype : t.ctype;
}

template dname_to_cname(string dname, decls...)
{
    static if(decls.length == 0)
    { }
    else static if(decls[0].dname == dname)
        enum dname_to_cname = decls[0].cname;
    else
        enum dname_to_cname = dname_to_cname!(dname, decls[1..$]);
}

template api(string suffix, string scalar)
{
    template list(args...){ alias elements = args; }

    template arg(string name_, alias type_)
    {
        enum name = name_;
        alias type = type_;
    }

    template ty(string dname_, string doc_)
    {
        enum kind = "type";
        enum dname = dname_;
        enum cname = "Pfft"~dname_~Suffix;
        enum doc = doc_;
    }

    template fn(alias dname_, alias ret_, alias args_, string doc_)
    {
        enum kind = "func";
        enum dname = dname_;
        enum cname = "pfft_"~dname~"_"~suffix;
        alias ret = ret_;
        alias args = args_;
        enum doc = doc_;
    }

    enum Suffix = (suffix[0] + 'A' - 'a') ~ suffix[1..$];
    
    template ptr(string name)
    {
        enum dtype = name~"*";
        enum ctype = "Pfft"~name~Suffix~"*";
    }

    enum scalar_ptr = scalar~"*";
    alias api = list!(
        ty!("Table", 
            "The fft table"),
        fn!("fft_table_size",
            "size_t",
            list!(arg!("nptr", "size_t*"), arg!("nlen", "size_t")),
            "Returns the size of memory needed for an fft table."),
        fn!("fft_table_memory",
            "void*",
            list!(arg!("table", ptr!"Table")),
            "Retrieves the pointer that was passed to fft_table when the table was being constructed"),
        fn!("fft_table",
            ptr!"Table",
            list!(
                arg!("nptr", "size_t*"),
                arg!("nlen", "size_t"), 
                arg!("p", "void*")),
            "Constructs an fft table."),
        fn!("fft",
            "void",
            list!(
                arg!("re", scalar_ptr), 
                arg!("im", scalar_ptr), 
                arg!("table", ptr!"Table")),
            "Computes a discrete Fourier transform"),


        ty!("RealTable", 
            "The rfft table"),
        fn!("rfft_table_size",
            "size_t",
            list!(arg!("nptr", "size_t*"), arg!("nlen", "size_t")),
            "Returns the size of memory needed for an rfft table."),
        fn!("rfft_table_memory",
            "void*",
            list!(arg!("table", ptr!"RealTable")),
            "Retrieves the pointer that was passed to rfft_table when the table was being constructed"),
        fn!("rfft_table",
            ptr!"RealTable",
            list!(
                arg!("nptr", "size_t*"), 
                arg!("nlen", "size_t"), 
                arg!("p", "void*")),
            "Constructs an rfft table."),
        fn!("rfft",
            "void",
            list!(
                arg!("data", scalar_ptr), 
                arg!("table", ptr!"RealTable")),
            "Computes a real discrete Fourier transform"),
        fn!("irfft",
            "void",
            list!(
                arg!("data", scalar_ptr), 
                arg!("table", ptr!"RealTable")),
            "Computes an inverse real discrete Fourier transform"),
        fn!("raw_rfft1d",
            "void",
            list!(
                arg!("re", scalar_ptr), 
                arg!("im", scalar_ptr), 
                arg!("table", ptr!"RealTable")),
            "Lowest level interface to a one-dimensional real discrete Fourier transform"),
        fn!("raw_irfft1d",
            "void",
            list!(
                arg!("re", scalar_ptr), 
                arg!("im", scalar_ptr), 
                arg!("table", ptr!"RealTable")),
            "Lowest level interface to a one-dimensional inverse real discrete Fourier transform"),


        ty!("MultiTable", 
            "The multi fft table"),
        fn!("multi_fft_table_size",
            "size_t",
            list!(arg!("n", "size_t")),
            "Returns the size of memory needed for a multi fft table."),
        fn!("multi_fft_table_memory",
            "void*",
            list!(arg!("table", ptr!"MultiTable")),
            "Retrieves the pointer that was passed to multi_fft_table when the table was being constructed"),
        fn!("multi_fft_table",
            ptr!"MultiTable",
            list!(arg!("n", "size_t"), arg!("p", "void*")),
            "Constructs a multi fft table."),
        fn!("multi_fft",
            "void",
            list!(
                arg!("re", scalar_ptr), 
                arg!("im", scalar_ptr), 
                arg!("table", ptr!"MultiTable")),
            "Computes multiple discrete Fourier transforms in parallel."),
        fn!("multi_fft_ntransforms",
            "size_t",
            list!(),
            "Returns the number of Fourier transforms that multi_fft will compute in parallel."),


        ty!("RealMultiTable", 
            "The multi rfft table"),
        fn!("multi_rfft_table_size",
            "size_t",
            list!(arg!("n", "size_t")),
            "Returns the size of memory needed for a multi rfft table."),
        fn!("multi_rfft_table_memory",
            "void*",
            list!(arg!("table", ptr!"RealMultiTable")),
            "Retrieves the pointer that was passed to multi_rfft_table when the table was being constructed"),
        fn!("multi_rfft_table",
            ptr!"RealMultiTable",
            list!(arg!("n", "size_t"), arg!("p", "void*")),
            "Constructs a multi rfft table."),
        fn!("multi_rfft",
            "void",
            list!(
                arg!("data", scalar_ptr), 
                arg!("table", ptr!"RealMultiTable")),
            "Computes multiple real discrete Fourier transforms in parallel."),
        fn!("multi_irfft",
            "void",
            list!(
                arg!("data", scalar_ptr), 
                arg!("table", ptr!"RealMultiTable")),
            "Computes multiple inverse real discrete Fourier transforms in parallel."),
        fn!("multi_rfft_ntransforms",
            "size_t",
            list!(),
            "Returns the number of Fourier transforms that multi_rfft will compute in parallel."),


        fn!("deinterleave_array",
            "void",
            list!(
                arg!("even", scalar_ptr),
                arg!("odd", scalar_ptr),
                arg!("interleaved", scalar_ptr),
                arg!("n", "size_t")),
            "Deinterleaves array interleaved of size 2 * n into arrays even and odd."),
        fn!("interleave_array",
            "void",
            list!(
                arg!("even", scalar_ptr),
                arg!("odd", scalar_ptr),
                arg!("interleaved", scalar_ptr),
                arg!("n", "size_t")),
            "Interleaves arrays even and odd of size n into array interleaved."),
        fn!("scale",
            "void",
            list!(arg!("data", scalar_ptr), arg!("n", "size_t"), arg!("factor", scalar)),
            "Multiplies n elements in array data by factor."),
        fn!("cmul",
            "void",
            list!(
                arg!("real_dst", scalar_ptr),
                arg!("imag_dst", scalar_ptr),
                arg!("real_src", scalar_ptr),
                arg!("imag_src", scalar_ptr),
                arg!("n", "size_t")),
`Multiplies n complex numbers in real_dst and imag_dst with n complex numbers
in real_src and imag_src`),

        fn!("alignment",
            "size_t",
            list!(),
            "Returns the required alignment for a block of n elements."),
        fn!("set_implementation",
            "void",
            list!(arg!("implementation", "int")),
            "Chooses fft implementation. For testing only, unsafe."),

        fn!("recommended_alignment",
            "size_t",
            list!(arg!("n", "size_t"), arg!("page_size", "size_t")),
            "Recomended alignment. The result of this function will be at least "
            "as large as the result of alignment(). Using recommended_alignment "
            "can sometimes slightly improve performance. The parameter n is the "
            "size of the memory block we will be allocating with the alignment "
            "this function returns. The parameter page_size is the page size "
            "of the system. If it is different from zero, the function can use "
            "it to make a better decision  when choosing optimal alignemnt."),

        fn!("allocate",
            "void*",
            list!(
              arg!("n", "size_t"), 
              arg!("mem", "void*"), 
              arg!("page_size", "size_t")),
            "Takes a pointer to an allocated block of memory (mem) and returns "
            "an aligned pointer. The size of the block of memory at mem must "
            "be at least allocate_size(n, page_size). The return value ret will"
            "such that the block of memory between ret and ret + n will be " 
            "inside the block of memory pointed to by mem. The parameter "
            "page_size should be either zero or the page size of the system. "
            "If it is differt from zero, it can be used to make a better "
            "decision about optimal alignment."),

        fn!("allocate_size",
            "size_t",
            list!(arg!("n", "size_t"), arg!("page_size", "size_t")),
            "Returns the minimal size of the memory block passed to allocate()."),

        fn!("allocate_getmem",
            "void*",
            list!(arg!("p", "void*")),
            "Takes the pointer returned by allocate() and returns the value "
            "that was passed to allocate() as mem parameter.")
    );
}
    
template generate_decls(string lang, alias api)
{
    template decl_to_str(alias decl)
    {
        enum name = (lang == "d" ? decl.dname : decl.cname);

        static if(decl.kind == "type")
            enum decl_to_str = 
                (decl.doc == "" ? "" : "/**\n"~decl.doc~"\n*/\n")~
                "struct "~name~";\n";
        else
        {
            enum arg_to_str(alias arg) = type_name!(lang, arg.type)~" "~arg.name;

            enum decl_to_str = 
                "/**\n"~decl.doc~"\n*/\n"~
                (lang == "d" ? "pragma(mangle, \""~decl.cname~"\") " : "")~
                type_name!(lang, decl.ret)~" "~name~
                "("~ct_mapjoin!(arg_to_str, ", ", decl.args.elements)~");\n"; 
        }
    }

    enum generate_decls = ct_mapjoin!(decl_to_str, "\n", api.elements);
}

template Declarations(string name, T, size_t = size_t)
{
    extern(C):

    mixin(generate_decls!("d", api!(name, T.stringof)));
}
