#!/usr/bin/env rdmd 
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.process, std.string, std.array, std.algorithm, std.uuid, 
       std.conv, std.range, std.getopt, std.file, std.regex, std.exception,
       std.path : absolutePath, dirSeparator;

import buildutils;

enum Version{ AVX, SSE, Neon, Scalar, SSE_AVX }
enum SIMD{ AVX, SSE, Neon, Scalar}

auto parseVersion(string simdOpt)
{
    return [
        "sse": Version.SSE,
        "avx": Version.AVX,
        "sse-avx": Version.SSE_AVX,
        "neon": Version.Neon,
        "scalar": Version.Scalar][simdOpt];
}

T when(T)(bool condition, lazy T r){ return condition ? r : T.init; }

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
    return when(v == Version.SSE_AVX, [SIMD.AVX]);
}

@property supportedOnHost(Version v)
{
    import core.cpuid;
    
    foreach(s; v.baseSIMD ~ v.additionalSIMD) with(SIMD)
        if((s == SSE && !sse2) || (s == AVX && !avx) || (s == Neon && !isARM))
            return false;

    return true;
}

auto archFlags(SIMD simd, Compiler c)
{
    if(c == Compiler.GDC)
        return [
            SIMD.SSE:    "-msse2", 
            SIMD.Neon:   "-mfpu=neon -mfloat-abi=softfp -mcpu=cortex-a9",
            SIMD.Scalar: "",
            SIMD.AVX :   "-mavx"][simd];
    else if(c == Compiler.LDC)
        return  
            simd == SIMD.Scalar ? "" :
            simd == SIMD.SSE ? "-mattr=+sse2" : ("-mattr=+" ~ simd.name);
    else
        return "";
}

version(Windows)
    enum isWindows = true;
else
    enum isWindows = false;

version(linux)
    enum isLinux = true;
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

enum cObjs = ["druntime", "clib"];

string fixSeparators(string s)
{
    return replace(s, "/", dirSeparator);
}

auto simdModuleName(SIMD simd, string type)
{
    enum dict = [
        "sse_real" : "scalar_real",
        "avx_real" : "scalar_real"];
    
    auto s = simd.name~"_"~type;
    return dict.get(s, s); 
}

auto fileName(string moduleName)
{
    return "../pfft/"~moduleName;
}

auto implSources(SIMD simd, string[] types)
{
    return types.map!(t => fileName(simdModuleName(simd, t))).array;
}

auto sources(Version v, string[] types, string[] additional)
{
    auto m = 
        map!(t => simdModuleName(v.baseSIMD, t))(types).array ~ 
        map!q{"impl_" ~ a}(types).array ~
        ["fft_impl", "shuffle"] ~
        additional ~ 
        when(v == Version.SSE_AVX, ["detect_avx"]); 

    return map!fileName(m).array; 
}

//TODO: on MinGW we must use at least -O2 to avoid the stack alignment bug

void buildTests(
    string[] types, string dccmd, Compiler c, string outDir, 
    bool optimized = true, bool dbg = false, string fftw = null,
    bool dynamic = false, bool clib = false)
{
    auto fftwSuffixes = ["float" : "f", "double" : "", "real" : "l"]; 
    
    foreach(type; types)
        argList
            .compileCmd(dccmd)
            .src("../test/test")
            .conditional(clib,
                argList.src("../pfft/clib").version_("BenchClib"))
            .version_(capitalize(type))
            .output(outDir~"/test_"~type)
            .conditional(dynamic,
                argList.version_("DynamicC"),
                argList.ipath("include").lib("lib/pfft"))
            .conditional(optimized, argList.optimize.inline.release)
            .conditional(dbg, argList.debug_.g)
            .conditional(!!fftw, argList
                .lpath(fftw)
                .version_("BenchFftw")
                .linkTo("fftw3"~fftwSuffixes[type]))
            .conditional(isLinux, argList.linkTo("dl"))
            .run(c);
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
            auto fn = absolutePath("test") ~ "_" ~ type.to!string;
            auto rFlag = when(isReal, "-r");
            auto iStr = i.to!string;
            auto implStr = impl.to!string;
            vshell(fn~" -s -m 1000 pfft "~iStr~" --impl "~implStr~" "~rFlag);
        }
    }
}

void buildObj(
    Compiler c, string[] src, string objname, Version v, SIMD simd, 
    string dccmd, bool dbg, bool pic)
{
    argList
        .compileCmd(dccmd)
        .conditional(dbg,
            argList.debug_.g,
            argList.optimize.inline.release)
        .version_(v.to!string)
        .conditional(pic, argList.pic)
        .raw(archFlags(simd, c))
        .src(src)
        .output(objname)
        .genObj
        .ipath("..")
        .run(c);
}
 
string buildAdditionalSIMD(
    Compiler dc, Version v, SIMD simd, string[] types, 
    string dccmd, bool dbg, bool pic)
{
    types = types.filter!(
            t => !(v == Version.SSE_AVX && simd == SIMD.AVX && t == "real"))()
        .array(); 

    auto src = implSources(simd, types);
    
    buildObj(dc, src, simd.name, v, simd, dccmd, dbg, pic);
    
    return simd.name;
}

void buildLib(
    Compiler dc, Version v, string[] types,
    string dccmd, bool clib, bool dbg)
{
    auto src = sources(v, types, when(!clib, ["stdapi", "pfft"]));
 
    auto implObjs = v.additionalSIMD
        .map!(s => buildAdditionalSIMD(dc, v, s, types, dccmd, dbg, clib))
        .array;
 
    buildObj(dc, src, "pfft", v, v.baseSIMD, dccmd, dbg, clib);

    argList
        .genLib
        .output("lib/pfft")
        .obj("pfft")
        .obj(implObjs)
        .conditional(clib, argList.obj(cObjs))
        .run(dc);
    
    if(clib)
        argList
            .compileCmd(dccmd)
            .genDynlib
            .output("lib/pfft-c")
            .obj("pfft")
            .obj(implObjs)
            .obj(cObjs)
            .noDefaultLib
            .run(dc);
}

void buildDmd(Version v, string[] types, string dccmd, bool clib, bool dbg)
{
    buildLib(Compiler.DMD, v, types, dccmd, clib, dbg); 
}

void buildLdc(Version v, string[] types, string dccmd, bool clib, bool dbg)
{
    buildLib(Compiler.LDC, v, types, dccmd, clib, dbg); 
}

void buildGdc(Version v, string[] types, string dccmd, 
    bool pgo, bool clib, bool dbg)
{
    if(pgo)
    {
        buildLib(Compiler.GDC, v, types, 
            dccmd ~ " -fprofile-generate ", false, dbg);

        buildTests(types, dccmd ~ " -fprofile-generate ", 
            Compiler.GDC, ".", false, dbg);

        runBenchmarks(types, v);
        buildLib(Compiler.GDC, v, types, 
            dccmd ~ " -fprofile-use", clib, dbg);
    }
    else
        buildLib(Compiler.GDC, v, types, dccmd, clib, dbg);
}

string getModuleLocation(string dccmd, string module_)
{
        auto dirName = randomUUID().toString();
        mkdir(dirName);
        auto prevPath = absolutePath(".");
        chdir(dirName);

        auto src = "import "~module_~";"; 
        std.file.write("tmp.d", cast(void[]) src);
        vshell(dccmd~" -c -o- tmp.d -deps=out.deps");
        auto r = match(
            readText("out.deps"), 
            module_ ~ ` \(([^)]*)\)`).front[1];

        chdir(prevPath);
        std.file.rmdirRecurse(dirName);
        return r;
}

void buildCObjects(Compiler dc, string[] types, string dccmd)
{
    auto versionSyntax =
        dc == Compiler.DMD ? "-version=" :
        dc == Compiler.GDC ? "-fversion=" : "-d-version=";

    auto typeFlags = types.map!(a => versionSyntax ~ capitalize(a)).join(" ");

    auto src = fixSeparators("../pfft/clib.d");

    buildObj(
        dc, ["../pfft/clib"], "clib", Version.Scalar, SIMD.Scalar, 
        dccmd~" "~typeFlags, false, true); 
 
    string bitopSrc = when(
        dc == Compiler.LDC, getModuleLocation(dccmd, "core.bitop"));

    buildObj(
        dc, [bitopSrc, "../pfft/druntime_stubs"], "druntime", 
        Version.Scalar, SIMD.Scalar, dccmd, false, true);
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
        auto name ="impl_"~type~".di";
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

void deleteDOutput(Compiler dc)
{
    try rmdirRecurse(fixSeparators("include/pfft")); catch{}
    try std.file.remove(libName(dc, "lib/pfft")); catch{}
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
  --clib                Build a C library. This doesn't currently work with DMD.
  --tests               Build tests. Executables will be saved to ./test. 
                        Can not be used with --clib or when cross compiling.
                        You must build the D library for selected types before 
                        building tests.
  --dynamic-tests       Buildt tests for the dynamic c library. Executables 
                        will be saved to ./test.
  --no-pgo              Disable profile guided optimization. This flag can
                        only be used with GDC. Using this flag will result
                        in slightly worse performance, but the build will be 
                        much faster. You must use this flag when cross
                        compiling with GDC. This flag is ignored when building
                        tests.
  --debug               Turns on debug flags and turns off optimization flags.
  --fftw PATH           Enable support for testing FFTW. PATH must be the path
                        to FFTW libraries. The generated executables will
                        be covered by the GPL.
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
    bool clib;
    bool nopgo;
    bool tests;
    bool dynamic;
    bool help;
    bool dbg;
    string fftw = null;
    Compiler dc = Compiler.GDC;

    getopt(args, 
        "simd", &simdOpt, 
        "type", &types, 
        "dc-cmd", &dccmd, 
        "clib", &clib,
        "dc", &dc,
        "tests", &tests,
        "dynamic-tests", &dynamic,
        "no-pgo", &nopgo,
        "fftw", &fftw,
        "h|help", &help,
        "v|verbose", &verbose,
        "debug", &dbg);

    tests = tests || dynamic;

    if(help)
    {
        writeln(usage);
        return;
    }
  
    if(dc == Compiler.DMD && clib)
        invalidCmd("Can not build the C library using DMD");

    if(fftw)
        stderr.writeln(
            "Building with FFTW support enabled - the generated "
            "executable will be covered by the GPL (see FFTW's license).");

    types = array(uniq(sort(types)));

    if(dccmd == "")
        dccmd = [
            Compiler.DMD : "dmd", 
            Compiler.GDC : "gdc", 
            Compiler.LDC : "ldc2"][dc];

    if(dc == Compiler.LDC)
        // By default, ldc2 will generate code that can use all the features 
        // of the host processor. That's usually not what we want.
        dccmd = dccmd ~ " -mcpu=generic";
   
    if(types == [])
        types = ["double", "float", "real"];

    if(simdOpt == "")
        simdOpt = (dc != Compiler.DMD) ? "sse-avx" : "sse";

    auto buildDir = (clib && !tests) ? "generated-c" : "generated";
    if(tests)
    {
        chdir(buildDir);
        buildTests(types, dccmd, dc, "../test", !dbg, dbg, fftw, dynamic, clib);
    }
    else
    {
        Version v = parseVersion(simdOpt);

        if(!isLinux)
            // PGO currently only works on Linux.
            nopgo = true;

        if(dc == Compiler.GDC && !nopgo && !v.supportedOnHost)
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
            buildCObjects(dc, types, dccmd);
        
        if(dc == Compiler.GDC)
            buildGdc(v, types, dccmd, !nopgo, clib, dbg);
        else 
            buildLib(dc, v, types, dccmd, clib, dbg);

        foreach(e; dirEntries(".", SpanMode.shallow, false))
            if(e.isFile)
                remove(e.name);
        if(clib)
            deleteDOutput(dc);
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
