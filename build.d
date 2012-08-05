#!/usr/bin/env rdmd 
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.process, std.string, std.array, std.algorithm, 
       std.conv, std.range, std.getopt, std.file, std.path : buildPath, absolutePath;

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

auto baseSIMD(Version v)
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
        version(DigitalMars)
		enum isWindowsDMD = true;
	    
  	
	enum libPath = buildPath("lib", "pfft.lib");
	enum clibPath = buildPath("lib", "pfft-c.lib");
}
else
{
	enum libPath = buildPath("lib", "libpfft.a");
	enum clibPath = buildPath("lib", "libpfft-c.a");
}

static if(!is(typeof(isWindowsDMD)))
    enum isWindowsDMD = false;

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
    auto simd = baseSIMD(v);
    auto m = 
        map!(t => simdModuleName(simd, t))(types).array() ~ 
        map!q{"impl_" ~ a}(types).array() ~
        ["fft_impl", "shuffle"] ~
        additional ~ 
        (v == Version.SSE_AVX ? ["detect_avx"] : []); 

    return join(map!fileName(m), " "); 
}

void buildCObjects(string[] types, string dcpath, string ccpath)
{
    auto typeFlags = join(map!(a => "-version=" ~ capitalize(a))(types), " "); 

    shellf("%s -O -inline -release -c -Iinclude %s %s", 
            dcpath, typeFlags,  buildPath("..", "pfft", "clib.d"));
    shellf("%s %s -c", ccpath, buildPath("..", "c", "dummy.c")); 
}

enum dmdOpt = "-O -inline -release";
enum dmdDbg = "-debug -g";

void buildTests(string[] types, string dcpath, Compiler c, string outDir, 
    bool optimized = true, bool dbg = false, string flags = "")
{
    auto srcPath = buildPath("..", "test", "test.d");

    auto clibSrc = isWindowsDMD ? "" : buildPath("..", "pfft", "clib.d");
    auto clibVersion = isWindowsDMD ? "NoBenchClib" : "BenchClib";

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
            shell(fm("%s_%s -s -m 1000 pfft \"%s\"", 
                absolutePath("test"), type, i));
    }
}

void buildDmd(Version v, string[] types, string dcpath, 
    string ccpath, bool clib, bool dbg)
{
    auto simd = baseSIMD(v);
    auto simdStr = to!string(simd);
    auto src = sources(v, types, clib ? ["clib"] : ["stdapi", "pfft"]);

    auto optOrDbg = dbg ? dmdDbg : dmdOpt; 

    shellf("%s %s -lib -of%s -version=%s %s", 
        dcpath, optOrDbg,  clib ? clibPath : libPath, to!string(v), src);
}

void buildLdc(Version v, string[] types, string dcpath, 
    string ccpath, bool clib)
{
    auto simd = baseSIMD(v);
    enum mattrDict = [SIMD.SSE : "sse2"];

    auto simdStr = to!string(simd);
    auto simdStrLC = toLower(simdStr);
    auto llcMattr = mattrDict.get(simd, simdStrLC);
    
    auto src = sources(v, types, clib ? ["capi"] : ["stdapi", "pfft"]);
    auto path = buildPath("lib", "libpfft.a");

    if(simd == SIMD.Scalar)
        shellf("%s -O3 -release -lib -of%s -d-version=%s %s", 
            dcpath, path, simdStr, src);
    else
    {
        execute(
            fm("%s -I.. -O3 -release -singleobj -output-bc -ofpfft.bc -d-version=%s %s", 
                dcpath,  to!string(v), src),
            fm("llvm-link %s pfft.bc -o both.bc", 
                buildPath("..", "ldc", simdStrLC ~ ".ll")),
            "opt -O3 -std-link-opts -std-compile-opts both.bc -o both.bc",
            fm("llc both.bc -o both.s -mattr=+%s", llcMattr),
            fm("%s both.s -c", ccpath),
            fm("ar cr %s both.o", path));
    }
}

enum gccArchFlagDict = [
    SIMD.SSE:    "-msse2", 
    SIMD.Neon:   "-mfpu=neon -mfloat-abi=softfp -mcpu=cortex-a8",
    SIMD.Scalar: "",
    SIMD.AVX :   "-mavx"];
    
string buildGdcAdditionaSIMD(Version v, SIMD simd, string[] types, 
    string dcpath, bool dbg, string flags)
{
    types = types.filter!(
            t => !(v == Version.SSE_AVX && simd == SIMD.AVX && t == "real"))()
        .array(); 

    auto arch = gccArchFlagDict[simd];
    auto optOrDbg = dbg ? dmdDbg : dmdOpt;
    auto simdStr = to!string(simd);
    auto src = implSources(simd, types);
    auto fname = toLower(simdStr) ~ ".o";
    
    shellf("%s %s %s %s -version=%s -c -of%s -I.. %s", 
        dcpath, optOrDbg, arch, flags, to!string(v), fname, src);

    return fname;
}

void buildGdcLib(Version v, string[] types, string dcpath, 
    string ccpath, bool clib, bool dbg, string flags)
{
    auto simd = baseSIMD(v);
    auto arch = gccArchFlagDict[simd];
    auto src = sources(v, types, clib ? [] : ["stdapi", "pfft"]);
    auto optOrDbg = dbg ? dmdDbg : dmdOpt; 
  
    auto implObjs = additionalSIMD(v)
        .map!(s => buildGdcAdditionaSIMD(v, s, types, dcpath, dbg, flags))()
        .array().join(" ");
 
    execute(
        fm("%s %s -version=%s %s %s %s -ofpfft.o -c -I..", 
            dcpath, optOrDbg, to!string(v), arch, flags, src),
        fm("ar cr %s pfft.o %s %s", 
            clib ? clibPath : libPath, clib ? "dummy.o clib.o" : "", implObjs));
}

void buildGdc(Version v, string[] types, string dcpath, 
    string ccpath, bool pgo, bool clib, bool dbg, string flags)
{
    if(pgo)
    {
        buildGdcLib(v, types, dcpath, ccpath, false, 
            dbg, "-fprofile-generate " ~ flags);

        buildTests(types, dcpath, Compiler.GDMD, ".", 
            false, dbg, "-fprofile-generate " ~ flags);
        
        runBenchmarks(types);
        buildGdcLib(v, types, dcpath, ccpath, clib, dbg, 
            fm("-fprofile-use %s", flags));
    }
    else
        buildGdcLib(v, types, dcpath, ccpath, clib, dbg, flags);
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
    try remove(libPath); catch{}
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

    if(isWindowsDMD && clib)
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
            buildCObjects(types, dcpath, ccpath);
        
        if(dc == Compiler.GDMD)
            buildGdc(v, types, dcpath, ccpath, !nopgo, clib, dbg, flags);
        else if(dc == Compiler.LDC)
            buildLdc(v, types, dcpath, ccpath, clib);
        else
            buildDmd(v, types, dcpath, ccpath, clib, dbg);

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
