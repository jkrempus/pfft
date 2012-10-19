#!/usr/bin/env rdmd 
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.process, std.string, std.array, std.algorithm, 
       std.conv, std.range, std.getopt, std.file, std.path : buildPath, absolutePath, dirSeparator;

enum Version{ AVX, SSE, Neon, Scalar, SSE_AVX }
enum SIMD{ AVX, SSE, Neon, Scalar}
enum Compiler{ DMD, GDMD, LDC}

auto parseVersion(string simdOpt)
{
    return [
        "sse": Version.SSE,
        "avx": Version.AVX,
        "sse-avx": Version.SSE_AVX,
        "neon": Version.Neon,
        "scalar": Version.Scalar][simdOpt];
}

@property baseSIMD(Version v)
{
    return [
        Version.SSE: SIMD.SSE,
        Version.AVX: SIMD.AVX,
        Version.Neon: SIMD.Neon,
        Version.Scalar: SIMD.Scalar,
        Version.SSE_AVX: SIMD.SSE][v];
}

auto additionalSIMD(Version v)
{
    return v == Version.SSE_AVX ? [SIMD.AVX] : [];
}

alias format fm;

bool verbose;

auto shellf(A...)(A a)
{
    auto cmd = fm(a);
    if(verbose) 
        writeln(cmd); 
   
    auto r = shell(cmd);
    if(verbose)
        writeln(r);

    return r; 
}

version(Windows)
{
	enum isWindows = true;
	enum libPath = "lib\\pfft.lib";
	enum clibPath = "lib\\pfft-c.lib";
}
else
{
	enum isWindows = false;
	enum libPath = "lib/libpfft.a";
	enum clibPath = "lib/libpfft-c.a";
}

version(linux)
    enum isLinux = true;
else 
    enum isLinux = false;

void execute(Cmds...)(Cmds cmds)
{
    foreach(c; cmds)
    {
        if(verbose)
            writeln(c);
        
        auto r = shell(c);
        if(verbose)
            writeln(r);
    }
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
    
    auto s = fm("%s_%s", toLower(to!string(simd)), type);
    return dict.get(s, s);    
}

auto fileName(string moduleName)
{
    return buildPath("..", "pfft", fm("%s.d", moduleName));
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

void buildTests(string[] types, string dcpath, Compiler c, string outDir, 
    bool optimized = true, bool dbg = false, string flags = "")
{
    auto srcPath = buildPath("..", "test", "test.d");

    auto clibSrc = buildPath("..", "pfft", "clib.d");
    auto clibVersion = "BenchClib";

    foreach(type; types)
    {
        auto binPath = buildPath(outDir, "test_" ~ type);
        auto ver = capitalize(type);

        auto common = fm("%s -Iinclude %s %s %s -of%s %s", 
            ver, srcPath, clibSrc, libPath, binPath, flags);

        final switch(c)
        {
            case Compiler.DMD:
            case Compiler.GDMD:
                auto opt = optimized ? dmdOpt : "";
                opt ~= dbg ? dmdDbg : ""; 
                shellf("%s %s -version=%s -version=%s", 
                    dcpath, opt, clibVersion, common);
                break;

            case Compiler.LDC:
                auto opt = optimized ? "-O5 -release" : "";
                shellf("%s %s -d-version=%s -d-version=%s", 
                    dcpath, opt, clibVersion, common);
        }
    }
}

void runBenchmarks(string[] types)
{
    import std.parallelism;

    foreach(type; types)
    {
        if(verbose)
            writefln("Running benchmarks for type %s.", type);

        version(Windows)
            auto r = iota(4, 21);
        else
            auto r = taskPool.parallel(iota(4,21));

        foreach(i; r)
            shell(fm("%s_%s -s -m 1000 direct \"%s\"", 
                absolutePath("test"), type, i));
    }
}

void buildDmd(Version v, string[] types, string dcpath, 
    string ccpath, bool clib, bool dbg, string flags)
{
    auto src = sources(v, types, clib ? [] : ["stdapi", "pfft"]);

    auto optOrDbg = dbg ? dmdDbg : dmdOpt; 

    shellf("%s %s -lib -of%s -version=%s %s %s %s", 
        dcpath, optOrDbg,  clib ? clibPath : libPath, to!string(v), src, flags,
            clib ? "clib.o dummy.o" : "");
}

string buildAdditionalSIMD(F)(
    F buildObj, Version v, SIMD simd, string[] types, 
    string dcpath, string ccpath, bool dbg, string flags)
{
    types = types.filter!(
            t => !(v == Version.SSE_AVX && simd == SIMD.AVX && t == "real"))()
        .array(); 

    auto optOrDbg = dbg ? dmdDbg : dmdOpt;
    auto src = implSources(simd, types);
    auto fname = toLower(to!string(simd)) ~ ".o";
    
    buildObj(src, fname, v, simd, dcpath, ccpath, dbg, flags);

    return fname;
}

void buildLib(F)(
    F buildObj, Version v, string[] types, string dcpath, 
    string ccpath, bool clib, bool dbg, string flags)
{
    auto src = sources(v, types, clib ? [] : ["stdapi", "pfft"]);
 
    auto implObjs = additionalSIMD(v)
        .map!(s => buildAdditionalSIMD(
                buildObj, v, s, types, dcpath, ccpath, dbg, flags))()
        .array().join(" ");
 
    buildObj(src, "pfft.o", v, v.baseSIMD, dcpath, ccpath, dbg, flags);

    shellf("ar cr %s pfft.o %s %s", 
        clib ? clibPath : libPath, clib ? "dummy.o clib.o" : "", implObjs);
}

void buildLdcObj(
    string src, string objname, Version v, SIMD simd, 
    string dcpath, string ccpath, bool dbg, string flags)
{
    auto llcMattrFlag =  simd == SIMD.Scalar ? "" : format(
        "-mattr=+%s", simd == SIMD.SSE ? "sse2" : toLower(to!string(simd)));

    execute(
        fm("%s -I.. -O3 -release -singleobj -output-bc -ofpfft.bc -d-version=%s %s", 
            dcpath,  to!string(v), src),
        "opt -O3 -std-link-opts -std-compile-opts pfft.bc -o pfft.bc",
        fm("llc pfft.bc -o pfft.s %s", llcMattrFlag),
        fm("%s pfft.s -c -o%s", ccpath, objname));
}
 
void buildLdc(Version v, string[] types, string dcpath, 
    string ccpath, bool clib)
{
    buildLib(&buildLdcObj, v, types, dcpath, ccpath, clib, false, ""); 
}

void buildGdcObj(
    string src, string objname, Version v, SIMD simd, 
    string dcpath, string ccpath, bool dbg, string flags)
{
    auto gccArchFlag = [
        SIMD.SSE:    "-msse2", 
        SIMD.Neon:   "-mfpu=neon -mfloat-abi=softfp -mcpu=cortex-a9",
        SIMD.Scalar: "",
        SIMD.AVX :   "-mavx"][simd];

    shellf("%s %s -version=%s %s %s %s -of%s -c -I..", 
        dcpath, dbg ? dmdDbg : dmdOpt, to!string(v), 
        gccArchFlag, flags, src, objname);
}
 
void buildGdc(Version v, string[] types, string dcpath, 
    string ccpath, bool pgo, bool clib, bool dbg, string flags)
{
    if(pgo)
    {
        buildLib(&buildGdcObj, v, types, dcpath, ccpath, false, 
            dbg, "-fprofile-generate " ~ flags);

        buildTests(types, dcpath, Compiler.GDMD, ".", 
            false, dbg, "-fprofile-generate -version=JustDirect" ~ flags);
        
        runBenchmarks(types);
        buildLib(&buildGdcObj, v, types, dcpath, ccpath, clib, dbg, 
            fm("-fprofile-use %s", flags));
    }
    else
        buildLib(&buildGdcObj, v, types, dcpath, ccpath, clib, dbg, flags);
}

void buildCObjects(Compiler dc, string[] types, string dcpath, string ccpath)
{
    auto buildObj = dc == Compiler.LDC ? &buildLdcObj : &buildGdcObj;    
    auto typeFlags = join(map!(a => "-version=" ~ capitalize(a))(types), " "); 
    auto src = buildPath("..", "pfft", "clib.d");
  
    buildObj(
        src, "clib.o", Version.Scalar, SIMD.Scalar, 
        dcpath, ccpath, false, typeFlags); 

    shellf("%s %s -c", ccpath, buildPath("..", "c", "dummy.c")); 
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

        auto iStr = readText(buildPath("..", "c", "pfft.template"));
        auto oStr = "";

        foreach(type; types)
        {
            auto tmp = replace(iStr, "{type}", typeDict[type]);
            auto s = suffixDict[type];
            tmp = replace(tmp, "{suffix}", s);
            tmp = replace(tmp, "{Suffix}", toUpper(s));
            oStr ~= tmp;
        }
        
        std.file.write(buildPath("include", "pfft.h"), oStr);
    }

    foreach(type; types)
    {
        auto name = fm("impl_%s.di", type);
        copy(
            buildPath("..", "pfft", "di", name), 
            buildPath("include", "pfft", name));
    }
    
    copy(
        buildPath("..", "pfft", "stdapi.d"), 
        buildPath("include", "pfft", "stdapi.d"));
    copy(
        buildPath("..", "pfft", "pfft.d"), 
        buildPath("include", "pfft", "pfft.d"));
}

void deleteDOutput()
{
    try rmdirRecurse(buildPath("include", "pfft")); catch{}
    try std.file.remove(libPath); catch{}
}

enum usage = `
Usage: rdmd build [options]
build.d is an rdmd script used to build the pfft library. It saves the 
generated library and include files to ./generated or to ./generated-c when 
building with --clib. The script must be run from the directory it resides in.

Options:
  --dc DC               Specifies D compiler to use. DC must be one of DMD, 
                        GDMD and LDC.
  --dc-path PATH        A path to D compiler
  --cc-path PATH        A path to C compiler (used when building with --clib
                        or with LDC).
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
                        only be used with GDMD. Using this flag will result
                        in slightly worse performance, but the build will be 
                        much faster. You must use this flag when cross
                        compiling with GDMD. This flag is ignored when building
                        tests.
  --debug               Turns on debug flags and turns off optimization flags.
  --dflags FLAGS        Additional flags to be passed to D compiler.
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
    string dcpath = "";
    string ccpath = "gcc";
    bool clib;
    bool nopgo;
    bool tests;
    bool help;
    bool dbg;
    string flags = "";
    Compiler dc = Compiler.GDMD;

    getopt(args, 
        "simd", &simdOpt, 
        "type", &types, 
        "dc-path", &dcpath, 
        "cc-path", &ccpath,
        "clib", &clib,
        "dc", &dc,
        "tests", &tests,
        "no-pgo", &nopgo,
        "dflags", &flags,
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

    if(dcpath == "")
        dcpath = [
            Compiler.DMD : "dmd", 
            Compiler.GDMD : "gdmd", 
            Compiler.LDC : "ldc2"][dc];
   
    if(types == [])
        types = ["double", "float", "real"];

    if(simdOpt == "")
        simdOpt = dc == Compiler.GDMD && isLinux ? "sse-avx" : "sse";

    auto buildDir = clib ? "generated-c" : "generated";
    if(tests)
    {
        chdir(buildDir);
        buildTests(types, dcpath, dc, buildPath("..", "test"), !dbg, dbg, flags);
    }
    else
    {
        Version v = parseVersion(simdOpt);

        try rmdirRecurse(buildDir); catch{}
        mkdir(buildDir);
        chdir(buildDir);
        mkdir("lib");
        mkdir("include");
        mkdir(buildPath("include", "pfft"));

        copyIncludes(types, clib);

        if(clib)
            buildCObjects(dc, types, dcpath, ccpath);
        
        if(dc == Compiler.GDMD)
            buildGdc(v, types, dcpath, ccpath, !nopgo, clib, dbg, flags);
        else if(dc == Compiler.LDC)
            buildLdc(v, types, dcpath, ccpath, clib);
        else
            buildDmd(v, types, dcpath, ccpath, clib, dbg, flags);

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
