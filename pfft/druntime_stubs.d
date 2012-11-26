module pfft.druntime_stubs;

import core.stdc.stdlib, core.stdc.stdio, core.stdc.string;

extern(C):

__gshared void* _Dmodule_ref;

template stub(string name)
{
    enum stub = `
void `~name~`()
{
	fputs("`~name~` should not be called!\n", stderr);
	abort();
}
`;
}

mixin(
    stub!"_D15TypeInfo_Struct6__vtblZ" ~
    stub!"_D10TypeInfo_g6__initZ" ~
    stub!"_D10TypeInfo_i6__initZ" ~
    stub!"_D10TypeInfo_l6__initZ" ~
    stub!"_D10TypeInfo_m6__initZ" ~
    stub!"_D10TypeInfo_d6__initZ" ~
    stub!"_D10TypeInfo_k6__initZ" ~
    stub!"_D10TypeInfo_v6__initZ" ~
    stub!"_D16TypeInfo_Pointer6__vtblZ" ~
    stub!"_D13TypeInfo_Enum6__vtblZ");

void _d_assert(string file, uint line)
{
    auto cstr = cast(char*) malloc(file.length);
    memcpy(cstr, file.ptr, file.length);
    cstr[file.length - 1] = 0; 

	fprintf(stderr, "assert failed on line %d in file %s!\n", line, cstr);
	abort();
}
