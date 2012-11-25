#!/usr/bin/env rdmd 
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.process, std.string, std.array, std.algorithm, 
       std.conv, std.range, std.getopt, std.file,
       std.path : absolutePath, dirSeparator;

import interpolate : interpolate;
alias interpolate itp;

enum Version{ AVX, SSE, Neon, Scalar, SSE_AVX }
enum SIMD{ AVX, SSE, Neon, Scalar}
enum Compiler{ DMD, GDC, LDC}

auto parseVersion(string simdOpt)
{
    return [
        "sse": Version.SSE,
        "avx": Version.AVX,
        "sse-avx": Version.SSE_AVX,
        "neon": Version.Neon,
        "scalar": Version.Scalar][simdOpt];
}

T when(T)(bool condition, T r){ return condition ? r : T.init; }

@property name(Version v)
{
    return v.to!string.toLower.replace("_", "-"); 
}

@property name(SIMD s) { return s.to!string.toLower; }

@property baseSIMD(Version v)
{
    return [
        Version.SSE: SIMD.SSE,
        Version.AVX: SIMD.AVX,
        Version.Neon: SIMD.Neon,
        Version.Scalar: SIMD.Scalar,
        Version.SSE_AVX: SIMD.SSE][v];
}

@property additionalSIMD(Version v)
{
    return v == Version.SSE_AVX ? [SIMD.AVX] : [];
}

@property supportedOnHost(Version v)
{
    import core.cpuid;
    
    foreach(s; v.baseSIMD ~ v.additionalSIMD) with(SIMD)
        if((s == SSE && !sse2) || (s == AVX && !avx) || (s == Neon && !isARM))
            return false;

    return true;
}

bool verbose;

version(Windows)
{
	enum isWindows = true;
	enum dlibPath = "lib\\pfft.lib";
	enum clibPath = "lib\\pfft-c.lib";
    enum dynLibPath = "lib\\pfft-c.dll";
    enum defPath = "lib\\pfft-c.def";
}
else
{
	enum isWindows = false;
	enum dlibPath = "lib/libpfft.a";
	enum clibPath = "lib/libpfft-c.a";
}

version(linux)
{
    enum isLinux = true;
    enum dynLibPath = "lib/libpfft.so";
}
else 
    enum isLinux = false;

version(OSX)
    enum isOSX = true;
else 
    enum isOSX = false;

version(ARM)
    enum isARM = true;
else 
    enum isARM = false;

string libPath(bool clib){ return clib ? clibPath : dlibPath; }
string cObjs(bool clib){ return clib ? "dummy.o clib.o" : ""; }

string fixSeparators(string s)
{
    return replace(s, "/", dirSeparator);
}

void execute(Cmds...)(Cmds cmds)
{
    foreach(c; cmds)
    {
        auto cc = fixSeparators(c);
        if(verbose)
            writeln(cc);
        
        auto r = shell(cc);
        if(verbose)
            writeln(r);
    }
}

auto ex(Cmds...)(Cmds cmds)
{
    auto r = "execute(";
    foreach(c; cmds)
        r ~= interpolate(c) ~ ", ";
    
    return r ~ ");";
}

void removeFiles(S...)(S files)
{
    foreach(f; files)
        remove(f);
}

auto simdModuleName(SIMD simd, string type)
{
    enum dict = [
        "sse_real" : "scalar_real",
        "avx_real" : "scalar_real"];
    
    auto s = mixin(itp("%{simd.name}_%{type}"));
    return dict.get(s, s); 
}

auto fileName(string moduleName)
{
    return mixin(itp(`../pfft/%{moduleName}.d`));
}

string implSources(SIMD simd, string[] types)
{
    return types.map!(t => fileName(simdModuleName(simd, t)))().join(" ");
}

string sources(Version v, string[] types, string[] additional)
{
    auto m = 
        map!(t => simdModuleName(v.baseSIMD, t))(types).array() ~ 
        map!q{"impl_" ~ a}(types).array() ~
        ["fft_impl", "shuffle"] ~
        additional ~ 
        (v == Version.SSE_AVX ? ["detect_avx"] : []); 

    return join(map!fileName(m), " "); 
}

enum dmdOpt = "-O -inline -release";
enum dmdDbg = "-debug -g";
enum gdcOpt = "-O3 -finline-functions -frelease";
enum gdcDbg = "-fdebug -g";
enum ldcOpt = "-O3 -release";
enum ldcDbg = "-d-debug -g";

void buildTests(string[] types, string dccmd, Compiler c, string outDir, 
    bool optimized = true, bool dbg = false)
{
    auto srcPath = fixSeparators("../test/test.d");

    auto clibSrc = fixSeparators("../pfft/clib.d");
    auto clibVersion = "BenchClib";

    foreach(type; types)
    {
        auto binPath = fixSeparators(outDir ~ "/test_" ~ type);
        auto ver = capitalize(type);

        auto common = mixin(itp(
            "%{ver} -Iinclude %{srcPath} %{clibSrc} %{dlibPath}"));

        final switch(c)
        {
            case Compiler.DMD:
                auto opt = optimized ? dmdOpt : " ";
                opt ~= dbg ? dmdDbg : ""; 
                mixin(ex(
                    `%{dccmd} %{opt} -version=%{clibVersion} `
                    `-of%{binPath} -version=%{common}`));
                break;

            case Compiler.GDC:
                auto opt = optimized ? gdcOpt : " ";
                opt ~= dbg ? gdcDbg : ""; 
                mixin(ex(
                    `%{dccmd} %{opt} -fversion=%{clibVersion} `
                    `-o %{binPath} -fversion=%{common}`));
                break;
            
            case Compiler.LDC:
                auto opt = optimized ? ldcOpt : " ";
                opt ~= dbg ? ldcDbg : "";
                mixin(ex(
                    "%{dccmd} %{opt} -d-version=%{clibVersion} "
                    "-of%{binPath} -d-version=%{common} -linkonce-templates"));
        }
    }
}

void runBenchmarks(string[] types, Version v)
{
    import std.parallelism;

    foreach(isReal; [false])        // only profile complex transforms for now
    foreach(impl; 0 .. 1 + v.additionalSIMD.length)
    foreach(type; types)
    {
        if(verbose)
            writefln("Running benchmarks for type %s.", type);

        version(Windows)
            auto r = iota(4, 21);
        else
            auto r = taskPool.parallel(iota(4,21));

        foreach(i; r)
        {
            auto base = absolutePath("test");
            auto rFlag = isReal ? "-r" : "";
            mixin(ex(
                `%{base}_%{type} -s -m 1000 direct "%{i}" --impl "%{impl}" `
                `%{rFlag}`));
        }
    }
}

void buildDmd(Version v, string[] types, string dccmd, 
    string cccmd, bool clib, bool dbg)
{
    auto src = sources(v, types, clib ? [] : ["stdapi", "pfft"]);
    auto optOrDbg = dbg ? dmdDbg : dmdOpt; 

    mixin(ex(
        `%{dccmd} %{optOrDbg} -lib -of%{libPath(clib)} -I.. `
        `-version=%{v} %{src} %{cObjs(clib)} %{when(clib, "-fPIC")}`)); 
}

string buildAdditionalSIMD(F)(
    F buildObj, Version v, SIMD simd, string[] types, 
    string dccmd, string cccmd, bool dbg, bool pic)
{
    types = types.filter!(
            t => !(v == Version.SSE_AVX && simd == SIMD.AVX && t == "real"))()
        .array(); 

    auto src = implSources(simd, types);
    auto fname = simd.name ~ ".o";
    
    buildObj(src, fname, v, simd, dccmd, cccmd, dbg, pic);

    return fname;
}


void noShared(string dccmd, string objname, string implObjs){}

void buildLib(F0, F1)(
    F0 buildObj, F1 buildShared, Version v, string[] types, string dccmd, 
    string cccmd, bool clib, bool dbg)
{
    auto src = sources(v, types, clib ? [] : ["stdapi", "pfft"]);
 
    auto implObjs = v.additionalSIMD
        .map!(s => buildAdditionalSIMD(
                buildObj, v, s, types, dccmd, cccmd, dbg, clib))()
        .array().join(" ");
 
    buildObj(src, "pfft.o", v, v.baseSIMD, dccmd, cccmd, dbg, clib);

    mixin(ex(`ar cr %{libPath(clib)} pfft.o %{cObjs(clib)} %{implObjs}`)); 
    
    if(clib)
        buildShared(dccmd, "pfft.o", implObjs);
}

void buildLdcObj(
    string src, string objname, Version v, SIMD simd, 
    string dccmd, string cccmd, bool dbg, bool pic)
{
    auto mattrFlag =  
        simd == SIMD.Scalar ? "" :
        simd == SIMD.SSE ? "-mattr=+sse2" :
        ("-mattr=+" ~ simd.name);

    auto optOrDbg = dbg ? ldcDbg : ldcOpt;

    auto llvmVerStr = shell("llvm-config --version");
    auto picFlag = when(pic, "-relocation-model=pic");

    if(["3.2", "3.3"].canFind(llvmVerStr[0 .. 3]))
    {
        mixin(ex(
            `%{dccmd} -I.. %{optOrDbg} -c -singleobj %{picFlag} `
            "of%{objname} -d-version=%{v} %{src} %{mattrFlag}"));
    }
    else
    {
        mixin(ex(
            "%{dccmd} -I.. %{optOrDbg} -singleobj"
                 "-output-bc -ofpfft.bc -d-version=%{v} %{src}"));

        if(!dbg) 
            execute(
                "opt -O3 -std-link-opts -std-compile-opts pfft.bc -o pfft.bc");

        mixin(ex(
            `llc pfft.bc -o pfft.s -O=%{dbg ? 0 : 3} %{mattrFlag} `
            `%{isOSX ? "-disable-cfi" : ""} %{picFlag}`,
            "as pfft.s -o%{objname}"));
    }
}
 
void buildLdc(Version v, string[] types, string dccmd, 
    string cccmd, bool clib, bool dbg)
{
    buildLib(&buildLdcObj, &noShared, v, types, dccmd, cccmd, clib, dbg); 
}

void buildGdcShared(string dccmd, string objname, string implObjs)
{
    version(Windows)
        auto def = "-Wl,--output-def=" ~ defPath;
    else
        auto def = "";    
 
    mixin(ex(
        `%{dccmd} -shared -o %{dynLibPath} %{objname} %{cObjs(true)} `
        `%{implObjs} %{def}`)); 
}

void buildGdcObj(
    string src, string objname, Version v, SIMD simd, 
    string dccmd, string cccmd, bool dbg, bool pic)
{
    auto archFlags = [
        SIMD.SSE:    "-msse2", 
        SIMD.Neon:   "-mfpu=neon -mfloat-abi=softfp -mcpu=cortex-a9",
        SIMD.Scalar: "",
        SIMD.AVX :   "-mavx"][simd];

    auto optOrDbg = dbg ? gdcDbg : gdcOpt; 

    mixin(ex(
        `%{dccmd} %{optOrDbg} -fversion=%{v} %{when(pic, "-fPIC")}`
        `%{archFlags} %{src} -o %{objname} -c -I..`)); 
}
 
void buildGdc(Version v, string[] types, string dccmd, 
    string cccmd, bool pgo, bool clib, bool dbg)
{
    if(pgo)
    {
        buildLib(&buildGdcObj, &noShared, v, types, 
            dccmd ~ " -fprofile-generate ", cccmd, false, dbg);

        buildTests(types, dccmd ~ " -fprofile-generate -fversion=JustDirect ", 
            Compiler.GDC, ".", false, dbg);
        
        runBenchmarks(types, v);
        buildLib(&buildGdcObj, &buildGdcShared, v, types, 
            dccmd ~ " -fprofile-use", cccmd, clib, dbg);
    }
    else
        buildLib(&buildGdcObj, &buildGdcShared, v, types, dccmd, cccmd, 
            clib, dbg);
}

void buildCObjects(Compiler dc, string[] types, string dccmd, string cccmd)
{
    auto buildObj = dc == Compiler.LDC ? &buildLdcObj : &buildGdcObj;
    auto versionSyntax =
        dc == Compiler.DMD ? "-version=" :
        dc == Compiler.GDC ? "-fversion=" : "-d-version=";

    auto typeFlags = types.map!(a => versionSyntax ~ capitalize(a)).join(" ");

    auto src = fixSeparators("../pfft/clib.d");
  
    buildObj(
        src, "clib.o", Version.Scalar, SIMD.Scalar, 
        mixin(itp("%{dccmd} %{typeFlags}")), cccmd, false, true); 

    mixin(ex(`%{cccmd} ../c/dummy.c -c`)); 
}

void copyIncludes(string[] types, bool clib)
{
    if(clib)
    {
        auto suffixDict = [
            "float" : "f", 
            "double" : "d", 
            "real" : "l"];

        auto typeDict = [
            "float" : "float",
            "double" : "double",
            "real" : "long double"];

        auto iStr = readText(fixSeparators("../c/pfft.template"));
        auto oStr = "";

        foreach(type; types)
        {
            auto tmp = replace(iStr, "{type}", typeDict[type]);
            auto s = suffixDict[type];
            tmp = replace(tmp, "{suffix}", s);
            tmp = replace(tmp, "{Suffix}", toUpper(s));
            oStr ~= tmp;
        }
        
        std.file.write(fixSeparators("include/pfft.h"), oStr);
    }

    foreach(type; types)
    {
        auto name = mixin(itp("impl_%{type}.di"));
        copy(
            fixSeparators("../pfft/di/" ~ name), 
            fixSeparators("include/pfft/" ~ name));
    }
    
    copy(
        fixSeparators("../pfft/stdapi.d"), 
        fixSeparators("include/pfft/stdapi.d"));
    copy(
        fixSeparators("../pfft/pfft.d"), 
        fixSeparators("include/pfft/pfft.d"));
}

void deleteDOutput()
{
    try rmdirRecurse(fixSeparators("include/pfft")); catch{}
    try std.file.remove(dlibPath); catch{}
}

enum usage = `
Usage: rdmd build [options]
build.d is an rdmd script used to build the pfft library. It saves the 
generated library and include files to ./generated or to ./generated-c when 
building with --clib. The script must be run from the directory it resides in.

Options:
  --dc DC               Specifies D compiler to use. DC must be one of DMD, 
                        GDC and LDC.
  --dc-cmd COMMAND      D compiler command (can include flags)
  --cc-cmd COMMAND      A C compiler command (used when building with --clib,
                        can include flags).
  --simd SIMD           SIMD instruction set to use. Must be one of sse, avx,
                        neon, sse-avx and scalar. sse-avx builds both sse and
                        avx implementations. An implementations is then 
                        selected at run time, based on what is supported - if 
                        the OS and CPU support AVX, AVX implementation is used, 
                        otherwise we use the SSE implementation. On GDC 
                        on Linux this is the default value for this flag. 
                        On other platforms and compilers sse is the default.  
                        This flag is ignored when building tests.
  --type TYPE           Arithmetic type that the resulting library will support.
                        TYPE must be one of float, double and real. There can
                        be more than one --type flag. Omitting this flag is 
                        equivalent to --type float --type double --type real.
  --clib                Build a C library.
  --tests               Build tests. Executables will be saved to ./test. 
                        Can not be used with --clib or when cross compiling.
                        You must build the D library for selected types before 
                        building tests.
  --no-pgo              Disable profile guided optimization. This flag can
                        only be used with GDC. Using this flag will result
                        in slightly worse performance, but the build will be 
                        much faster. You must use this flag when cross
                        compiling with GDC. This flag is ignored when building
                        tests.
  --debug               Turns on debug flags and turns off optimization flags.
  -v, --verbose         Be verbose.
  -h, --help            Print this message to stdout.
`;

void invalidCmd(string message = "")
{
    if(message != "")
        stderr.writefln("Invalid command line: %s", message);
    
    stderr.writeln(usage); 
    core.stdc.stdlib.abort();
}

void doit(string[] args)
{
    auto simdOpt = "";
    string[] types;
    string dccmd = "";
    string cccmd = "gcc";
    bool clib;
    bool nopgo;
    bool tests;
    bool help;
    bool dbg;
    Compiler dc = Compiler.GDC;

    getopt(args, 
        "simd", &simdOpt, 
        "type", &types, 
        "dc-path", &dccmd, 
        "cc-path", &cccmd,
        "clib", &clib,
        "dc", &dc,
        "tests", &tests,
        "no-pgo", &nopgo,
        "h|help", &help,
        "v|verbose", &verbose,
        "debug", &dbg);

    if(help)
    {
        writeln(usage);
        return;
    }
  
    if(tests && clib)
        invalidCmd("Can not build tests for the c library.");

    if(isWindows && dc == Compiler.DMD && clib)
        invalidCmd("Can not build the C library using DMD on Windows.");

    types = array(uniq(sort(types)));

    if(dccmd == "")
        dccmd = [
            Compiler.DMD : "dmd", 
            Compiler.GDC : "gdc", 
            Compiler.LDC : "ldc2"][dc];
   
    if(types == [])
        types = ["double", "float", "real"];

    if(simdOpt == "")
        simdOpt = (dc != Compiler.DMD && !isOSX) ? "sse-avx" : "sse";

    auto buildDir = clib ? "generated-c" : "generated";
    if(tests)
    {
        chdir(buildDir);
        buildTests(types, dccmd, dc, "../test", !dbg, dbg);
    }
    else
    {
        Version v = parseVersion(simdOpt);

        if(!v.supportedOnHost && !nopgo)
        {
            nopgo = true;
            stderr.writefln(
                "Building without the --no-pgo flag, but not all SIMD "
                "instruction sets needed for \"--simd %s\" are supported on "
                "host. Continuing with build, but with PGO turned off.", 
                v.name);
        }

        try rmdirRecurse(buildDir); catch{}
        mkdir(buildDir);
        chdir(buildDir);
        mkdir("lib");
        mkdir("include");
        mkdir(fixSeparators("include/pfft"));

        copyIncludes(types, clib);

        if(clib)
            buildCObjects(dc, types, dccmd, cccmd);
        
        if(dc == Compiler.GDC)
            buildGdc(v, types, dccmd, cccmd, !nopgo, clib, dbg);
        else if(dc == Compiler.LDC)
            buildLdc(v, types, dccmd, cccmd, clib, dbg);
        else
            buildDmd(v, types, dccmd, cccmd, clib, dbg);

        foreach(e; dirEntries(".", SpanMode.shallow, false))
            if(e.isFile)
                remove(e.name);
        if(clib)
            deleteDOutput();
    }
}

void main(string[] args)
{
    try 
        doit(args);
    catch(Exception e)
    {
        auto s = findSplit(to!string(e), "---")[0];
        stderr.writefln("Exception was thrown: %s", s);
        stderr.writeln(usage);
        core.stdc.stdlib.exit(1); 
    }
}
