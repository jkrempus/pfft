module pfft.common_templates;

template TypeTuple(A...)
{
    alias A TypeTuple;
}

template get_member(alias a, string member)
{
    alias TypeTuple!(__traits(getMember, a, member))[0] get_member;
}

template ParamTypeTuple(alias f)
{
    auto params_struct(Ret, Params...)(Ret function(Params) f) 
    {
        struct R
        {
            Params p;
        }
        return R.init;
    }

    extern(C) auto params_struct(Ret, Params...)(Ret function(Params) f) 
    {
        struct R
        {
            Params p;
        }
        return R.init;
    }

    static if(is(typeof(params_struct(&f))))
        alias f f_instance;
    else
        alias f!() f_instance;

    alias typeof(params_struct(&f_instance).tupleof) ParamTypeTuple;
}

template ReturnType(alias f)
{
    alias typeof(f(ParamTypeTuple!f.init)) ReturnType;
}

template generate_arg_list(alias fun, bool includeTypes)
{
    alias ParamTypeTuple!fun Params;

    template arg_list(int i)
    {
        static if(i == 0)
            enum arg_list = "";
        else
            enum arg_list = 
                (i > 1 ? arg_list!(i - 1) ~ ", " : "") ~
                (includeTypes ? Params[i - 1].stringof ~ " " : "") ~
                "_" ~ i.stringof;
    }

    enum generate_arg_list = arg_list!(Params.length);
}

template st(alias a){ enum st = cast(size_t) a; }

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

