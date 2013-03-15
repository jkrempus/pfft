#!/usr/bin/env rdmd
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import buildutils;
import std.string: toLower, toUpper, capitalize;

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

@property name(Version v) { return v.to!string.toLower.replace("_", "-"); }
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

auto simdModuleName(SIMD simd, string type)
{
    enum dict = [
        "sse_real" : "scalar_real",
        "avx_real" : "scalar_real"];
    
    auto s = simd.name~"_"~type;
    return "pfft."~dict.get(s, s); 
}

auto commonArgs(Compiler c)
{
    return isWindows && c == Compiler.GDC ? argList.raw("-O2") : argList;
}

enum optimizeFlags = argList.optimize.inline.release.noboundscheck;

void buildTests(
    string[] types, ArgList dcArgs, Compiler c, string baseDir, 
    bool optimized = true, bool dbg = false, string fftw = null,
    bool dynamic = false, bool clib = false)
{
    auto fftwSuffixes = ["float" : "f", "double" : "", "real" : "l"]; 
    
    foreach(type; types)
        dcArgs
            .src(baseDir~"/test/test")
            .version_(capitalize(type))
            .output("test_"~type)
            .conditional(dynamic,
                argList.version_("DynamicC"),
                argList
                    .ipath(baseDir~"/generated/include")
                    .lib(baseDir~"/generated/lib/pfft")
                    .conditional(clib, argList
                        .src(baseDir~"/pfft/clib")
                        .version_("BenchClib")))
            .conditional(optimized, optimizeFlags)
            .conditional(dbg, argList.debug_.g)
            .conditional(!!fftw, argList
                .lpath(fftw)
                .version_("BenchFftw")
                .linkTo("fftw3"~fftwSuffixes[type]))
            .conditional(isLinux, argList.linkTo("dl"))
            .run(c);
}

void runBenchmarks(string[] types, Version v, string api = "")
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
            vshell(fn~" -s -m 1000 "~api~" "~iStr~" --impl "~implStr~" "~rFlag);
        }
    }
}

void buildObj(
    Compiler c, string[] modules, string objname, Version v, SIMD simd, 
    ArgList dcArgs, bool dbg, bool pic)
{
    dcArgs
        .conditional(dbg, argList.debug_.g, optimizeFlags)
        .version_(v.to!string)
        .conditional(pic, argList.pic)
        .raw(archFlags(simd, c))
        .module_(modules)
        .output(objname)
        .genObj
        .ipath("..")
        .build(c, false);
}
 
string buildAdditionalSIMD(
    Compiler dc, Version v, SIMD simd, string[] types, 
    ArgList dcArgs, bool dbg, bool pic)
{
    types = types.filter!(
            t => !(v == Version.SSE_AVX && simd == SIMD.AVX && t == "real"))()
        .array(); 

    auto src = types.map!(t => simdModuleName(simd, t)).array;

    buildObj(
        dc, src, simd.name, v, simd, 
        dcArgs.version_("InstantiateAdditionalSimd"), dbg, pic);

    return simd.name;
}

void buildLib(
    Compiler dc, Version v, string[] types, ArgList dcArgs, bool clib, bool dbg)
{
    auto src = 
        types.map!(t => simdModuleName(v.baseSIMD, t)).array ~ 
        types.map!(t => "pfft.impl_"~t).array ~
        ["pfft.fft_impl", "pfft.shuffle", "pfft.common"] ~
        when(!clib, ["pfft.stdapi", "pfft.pfft"]) ~ 
        when(v == Version.SSE_AVX, ["pfft.detect_avx"]); 

    auto implObjs = v.additionalSIMD
        .map!(s => buildAdditionalSIMD(dc, v, s, types, dcArgs, dbg, clib))
        .array;

    buildObj(dc, src, "pfft", v, v.baseSIMD, dcArgs, dbg, clib);

    commonArgs(dc)
        .genLib
        .output("lib/pfft" ~ (clib ? "-c" : ""))
        .obj("pfft")
        .obj(implObjs)
        .conditional(clib, argList.obj("druntime", "clib"))
        .run(dc);
    
    if(clib)
        dcArgs
            .genDynlib
            .output("lib/pfft-c")
            .obj("pfft")
            .obj(implObjs)
            .obj("druntime", "clib")
            .noDefaultLib
            .run(dc);
}

void buildLibPgo(
    Compiler dc, Version v, string[] types, ArgList dcArgs, bool clib, bool dbg)
{
    buildLib(dc, v, types, dcArgs.raw("-fprofile-generate"), clib, dbg);

    // benchmark with DynamicC when clib is true
    auto jd = argList.version_("JustDirect");
    buildTests(types, dcArgs.raw("-fprofile-generate").conditional(!clib, jd), 
        dc, "..", !dbg, dbg, null, clib); 

    runBenchmarks(types, v, clib ? "c" : "direct");
    buildLib(dc, v, types, dcArgs.raw("-fprofile-use"), clib, dbg);
}

void buildCObjects(Compiler dc, string[] types, ArgList dcArgs)
{
    auto common = dcArgs
        .genObj
        .optimize
        .pic
        .ipath("include");

    common
        .output("clib")
        .src("../pfft/clib")
        .version_(types.map!(capitalize).array)
        .build(dc, false);
 
    common
        .output("druntime")
        .src("../pfft/druntime_stubs")
        .conditional(dc == Compiler.LDC, argList.module_("core.bitop"))
        .build(dc, false);
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

        auto iStr = std.file.readText(fixSeparators("../c/pfft.template"));
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
        
    mkdir("include/pfft");
    foreach(type; types)
        cp("../pfft/di/impl_"~type~".di", "include/pfft/");
 
    cp("../pfft/instantiate_declarations.di", "include/pfft/");   
    cp("../pfft/stdapi.d", "include/pfft/");
    cp("../pfft/pfft.d", "include/pfft/");
}

void buildDoc(Compiler c, string ccmd)
{
    auto common = argList
        .compileCmd(ccmd)
        .noOutput
        .docInclude(
            "doc/candydoc/candy.ddoc", 
            "doc/ddoc/modules.ddoc", 
            "doc/ddoc/additional-macros.ddoc");

    common.src("pfft/pfft").docFile("doc/pfft.pfft.html").build(c, false);
    common.src("pfft/stdapi").docFile("doc/pfft.stdapi.html").build(c, false);
    common.src("doc/ddoc/clib").docFile("doc/pfft.clib.html").build(c, false);
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
  --doc                 Build documentation. This will generate documentation html
                        files and put them in doc directory.
  --clib                Build a C library. This doesn't currently work with DMD.
  --tests               Build tests. Executables will be saved to ./test. 
                        Can not be used when cross compiling. You must build the 
                        D library for selected types before building tests.
                        If both --tests and --clib are present, tests will be built,
                        and the resulting binaries will support testing the C API.
  --dynamic-tests       Buildt tests for the dynamic c library. Executables 
                        will be saved to ./test.
  --no-pgo              Disable profile guided optimization. This flag can
                        only be used with GDC. Using this flag will result
                        in slightly worse performance, but the build will be 
                        much faster. You must use this flag when cross
                        compiling with GDC. This flag is ignored when building
                        tests.
  --dversion VERSION    Pass version flag VERSION to compiler. There can be multiple
                        --dversion flags.
  --flag FLAG           Prepend - to FLAG and pass it to compiler. There can be
                        multiple --flag flags.
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
    bool doc;
    string fftw = null;
    string[] versions; 
    string[] flags; 
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
        "doc", &doc,
        "debug", &dbg,
        "dversion", &versions,
        "flag", &flags);

    tests = tests || dynamic;

    if(dccmd == "")
        dccmd = [
            Compiler.DMD : "dmd", 
            Compiler.GDC : "gdc", 
            Compiler.LDC : "ldc2"][dc];

    if(doc)
        return buildDoc(dc, dccmd);

    if(help)
        return writeln(usage);
  
    if(dc == Compiler.DMD && clib && !tests)
        invalidCmd("Can not build the C library using DMD");

    if(fftw)
        stderr.writeln(
            "Building with FFTW support enabled - the generated "
            "executable will be covered by the GPL (see FFTW's license).");

    types = array(uniq(sort(types)));

    if(dc == Compiler.LDC)
        // By default, ldc2 will generate code that can use all the features 
        // of the host processor. That's usually not what we want.
        dccmd = dccmd ~ " -mcpu=generic";
   
    if(types.empty)
        types = ["double", "float", "real"];

    if(simdOpt == "")
        simdOpt = (dc != Compiler.DMD) ? "sse-avx" : "sse";

    auto dcArgs = commonArgs(dc)
        .compileCmd(dccmd)
        .version_(versions)
        .raw(flags.map!(a => "-"~a).array);

    auto buildDir = (clib && !tests) ? "generated-c" : "generated";
    if(tests)
    {
        cd("test");
        buildTests(types, dcArgs, dc, "..", !dbg, dbg, fftw, dynamic, clib);
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

        rm(buildDir, "rf");
        mkdir(buildDir);
        cd(buildDir);
        mkdir("lib");
        mkdir("include");

        copyIncludes(types, clib);

        if(clib)
            buildCObjects(dc, types, dcArgs);
        
        if(dc == Compiler.GDC && !nopgo)
            buildLibPgo(dc, v, types, dcArgs, clib, dbg);
        else 
            buildLib(dc, v, types, dcArgs, clib, dbg);

        foreach(e; dirEntries(".", SpanMode.shallow, false))
            if(e.isFile)
                rm(e.name);

        if(clib)
            rm("include/pfft", "-rf");
    }
}

void main(string[] args)
{
    try 
        doit(args);
    catch(Exception e)
    {
        auto s = to!string(e);//.findSplit("---")[0];
        stderr.writefln("Exception was thrown: %s", s);
        core.stdc.stdlib.exit(1); 
    }
}
