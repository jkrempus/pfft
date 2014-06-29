module pfft.druntime_stubs;

version(Windows)
    version(GNU)
        version = MinGW;

extern(C):

void abort();
int puts(const char*);

__gshared void* _Dmodule_ref;

template stub(string name)
{
    enum stub = `
void `~name~`()
{
    enum message = "`~name~` should not be called!\n";
    version(MinGW)
    {
        puts(message);
    }
    else
    {
        import core.stdc.stdio;
	fputs("`~name~` should not be called!\n", stderr);
    }
    abort();
}
`;
}

mixin(
    stub!"_d_array_bounds" ~
    stub!"_D15TypeInfo_Struct6__vtblZ" ~
    stub!"_D10TypeInfo_g6__initZ" ~
    stub!"_D10TypeInfo_i6__initZ" ~
    stub!"_D10TypeInfo_l6__initZ" ~
    stub!"_D10TypeInfo_m6__initZ" ~
    stub!"_D10TypeInfo_d6__initZ" ~
    stub!"_D10TypeInfo_k6__initZ" ~
    stub!"_D10TypeInfo_v6__initZ" ~
    stub!"_D16TypeInfo_Pointer6__vtblZ" ~
    stub!"_D13TypeInfo_Enum6__vtblZ" ~ 
    stub!"_D14TypeInfo_Array6__vtblZ" ~
    stub!"_adEq2" ~
    stub!"_D6object10_xopEqualsFxPvxPvZb");

version(GNU)
    mixin(stub!"__gdc_personality_v0");

version(LDC)
    mixin(stub!"_D14TypeInfo_Const6__vtblZ");


void _d_assert(string file, uint line)
{
    version(MinGW)
    {
    	// TODO
    }
    else
    {
        import core.stdc.stdlib, core.stdc.stdio, core.stdc.string;

        auto cstr = cast(char*) malloc(file.length);
        memcpy(cstr, file.ptr, file.length);
        cstr[file.length - 1] = 0; 

	fprintf(stderr, "assert failed on line %d in file %s!\n", line, cstr);
    }
    abort();
}

void _d_assert_msg(string msg, string file, uint line)
{
    _d_assert(file, line);
}
