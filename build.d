#!/usr/bin/env rdmd
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import buildutils;
import std.string: toLower, toUpper, capitalize;
import std.process, std.traits, std.typetuple;

T or(T, U)(T a, lazy U b){ return a ? a : b; }
T when(T)(bool condition, lazy T r){ return condition ? r : T.init; }

string get_ctype(alias t)()
{
    static if(is(typeof(t) == string))
        return t;
    else 
        return t.ctype;
}

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
    return isWindows && c == Compiler.GDC ? 
        argList.raw("-O2").inline : argList;
}

enum optimizeFlags = argList.optimize.inline.release.noboundscheck;

void buildTests(
    string[] types, ArgList dcArgs, Compiler c, string baseDir, 
    string fftw = null)
{
    auto fftwSuffixes = ["float" : "f", "double" : "", "real" : "l"]; 

    foreach(type; types)
        dcArgs
            .src(baseDir~"/test/test")
            .version_(capitalize(type))
            .output("test_"~type)
            .module_("pfft.stdapi", "pfft.pfft")
            .ipath(baseDir~"/generated/include")
            .lib(baseDir~"/generated/lib/pfft")
            .conditional(!!fftw, argList
                .lpath(fftw)
                .version_("BenchFftw")
                .linkTo("fftw3"~fftwSuffixes[type]))
            .conditional(isLinux, argList.linkTo("dl"))
            .build(c, false);
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

        auto sizes = 
            iota(4, 21).map!(a => [a]).array ~ 
            iota(4, 11).map!(a => [a, a]).array ~
            iota(4, 7).map!(a => [a, a, a]).array;

        version(Windows)
            auto r = sizes;
        else
            auto r = taskPool.parallel(sizes);

        foreach(i; r)
        {
            auto fn = absolutePath("test") ~ "_" ~ type.to!string;
            auto rFlag = when(isReal, "-r");
            auto iStr = format("%(%s %)", i);
            auto implStr = impl.to!string;
            vshell(fn~" -s -m 1000 "~api~" "~iStr~" --impl "~implStr~" "~rFlag);
        }
    }
}

void buildObj(
    Compiler c, string[] modules, string objname, Version v, SIMD simd, 
    ArgList dcArgs, bool pic)
{
    dcArgs
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
    Compiler dc, Version v, SIMD simd, string[] types, ArgList dcArgs, bool pic)
{
    types = types.filter!(
            t => !(v == Version.SSE_AVX && simd == SIMD.AVX && t == "real"))()
        .array(); 

    auto src = types.map!(t => simdModuleName(simd, t)).array;

    buildObj(
        dc, src, simd.name, v, simd, 
        dcArgs.version_("InstantiateAdditionalSimd"), pic);

    return simd.name;
}

string[] exportedSymbols(string[] types)
{
    import pfft.declarations;

    string[] r = [];
    foreach(t; types)
    {
        if(t == "float")
            r ~= mangledMemberNames!(Declarations!("f", float));
        else if(t == "double")
            r ~= mangledMemberNames!(Declarations!("d", double));
        else if(t == "real")
            r ~= mangledMemberNames!(Declarations!("l", real));
        else 
            enforce(0);
    }

    return r;
}

void buildLibImpl(
    Compiler dc,
    Version v,
    string[] types,
    ArgList dcArgs,
    bool portable,
    bool dynamic,
    string[] addModule)
{
    auto src = 
        types.map!(t => simdModuleName(v.baseSIMD, t)).array ~ 
        types.map!(t => "pfft.impl_"~t).array ~
        ["pfft.fft_impl", "pfft.shuffle", "pfft.common"] ~
        when(v == Version.SSE_AVX, ["pfft.detect_avx"]); 

    auto implObjs = v.additionalSIMD
        .map!(s => buildAdditionalSIMD(dc, v, s, types, dcArgs, dynamic))
        .array;

    buildObj(dc, src, "pfft", v, v.baseSIMD, dcArgs.module_(addModule), dynamic);

    if(portable)
    {
        auto objN = (string a) => objName(dc, a);
        auto symbolFlags = (string flag) =>
          exportedSymbols(types).map!(a => only(flag, a)).joiner().array;

        auto linked = objN("linked");
        auto objs = chain(["druntime", "pfft"], implObjs).map!objN.array;

        vexecute(["ld","--gc-sections", "-r", "-o", linked]
            ~ symbolFlags("-u") ~ objs);

        vexecute(
            ["objcopy", linked, objN("copied"), "--remove-section=.eh_frame"]
            ~ (dc == Compiler.LDC ? ["--strip-symbol", "_d_dso_registry"] : [])
            ~ symbolFlags("-G"));

        auto common = argList.output("lib/pfft").obj("copied").noDefaultLib;
        common.genLib.run(dc);
        if(dynamic) common.genDynlib.run(dc);
    }
    else
    {
        auto common = dcArgs.output("lib/pfft").obj("pfft").obj(implObjs);
        common.genLib.run(dc);
        if(dynamic) common.genDynlib.run(dc);
    }
}

void buildLib(
    bool pgo, 
    Compiler dc, 
    Version v,
    string[] types,
    ArgList dcArgs,
    bool portable,
    bool dynamic,
    string[] addModule)
{
    if(!pgo)
        return buildLibImpl(dc, v, types, dcArgs, portable, dynamic, addModule);

    buildLibImpl(dc, v, types, dcArgs.raw("-fprofile-generate"), false, false, addModule);

    auto jd = argList.version_("JustDirect");
    buildTests(types, dcArgs.raw("-fprofile-generate").version_("JustDirect"),
        dc, "..", null); 

    runBenchmarks(types, v, "direct");
    buildLibImpl(dc, v, types, dcArgs.raw("-fprofile-use"), portable, dynamic, addModule);
}

void buildCObjects(Compiler dc, string[] types, ArgList dcArgs)
{
    dcArgs
        .genObj
        .optimize
        .pic
        .ipath("include")
        .output("druntime")
        .src("../pfft/druntime_stubs")
        .conditional(dc == Compiler.LDC, argList.module_("core.bitop"))
        .build(dc, false);
}

template ScalarNames(string d_, string c_, string upper_, string suffix_)
{
    enum d = d_;
    enum c = c_;
    enum upper = upper_;
    enum suffix = suffix_;
}

alias scalars = TypeTuple!(
  ScalarNames!("float", "float", "FLOAT", "f"),
  ScalarNames!("double", "double", "DOUBLE", "d"),
  ScalarNames!("real", "long double", "LONGDOUBLE", "l"));

string insertType(alias type)(string s)
{
    return s
        .replace("{type}", type.c)
        .replace("{TYPE}", type.upper)
        .replace("{suffix}", type.suffix)
        .replace("{Suffix}", toUpper(type.suffix));
}

enum decl_module_name(string lang, alias type) = 
    lang == "c-doc" ?  "pfft_declarations_"~type.suffix : "pfft.impl_"~type.d;

string generate_decl_module(string lang, alias type)()
{
    import pfft.declarations;
    return 
        "module "~decl_module_name!(lang, type)~";\n\n"~
        "extern(C):\n\n"~
        generate_decls!(lang, api!(type.suffix, type.d));
}

void copyIncludes(string[] types, bool portable)
{
    import pfft.declarations;

    mkdir("include/pfft");
    foreach(type; scalars)
    {
        if(!types.canFind(type.d)) continue;
        if(portable)
        {
            auto toplevel = rd(fixSeparators("../pfft/c/pfft.h"));
            auto decls = rd(fixSeparators("../pfft/c/pfft_declarations.h"));

            foreach(f; only(&toplevel, &decls))
                *f = insertType!type(*f);

            decls = replace(decls, "{declarations}", 
                generate_decls!("c", api!(type.suffix, type.c)));

            wr(toplevel, "include/pfft_"~type.suffix~".h");
            wr(decls, "include/pfft_declarations_"~type.suffix~".h");
        }

        wr(
            generate_decl_module!("d", type),
            "include/pfft/impl_"~type.d~".di");
    }

    cp("../pfft/stdapi.d", "include/pfft/");
    cp("../pfft/pfft.d", "include/pfft/");
    cp("../pfft/common_templates.d", "include/pfft/");
}

void buildDoc(Compiler c, string ccmd, string[] types)
{
    auto list = ["pfft.pfft", "pfft.stdapi"];
    foreach(type; scalars)
        if(types.canFind(type.d))
            foreach(lang; TypeTuple!("c", "d"))
                list ~= decl_module_name!(lang, type);

    auto common = argList
        .doc
        .compileCmd(ccmd)
        .noOutput;

    common
        .src("pfft/pfft")
        .src("pfft/stdapi")
        .jsonFile("doc/src/d.json").build(c, false);

    auto direct_args = common;
    auto c_args = common;
    foreach(type; scalars)
        if(types.canFind(type.d))
        {
            c_args = c_args
                .src(writeToRandom(generate_decl_module!("c-doc", type), ".d"))
                .src(writeToRandom(insertType!type(rd("doc/src/c.d")), ".d"));
            
            direct_args = direct_args
                .src(writeToRandom(generate_decl_module!("d", type), ".d"));
        }

    c_args.jsonFile("doc/src/c.json").build(c, false);
    direct_args.jsonFile("doc/src/direct.json").build(c, false);

    foreach(name; ["c", "d", "direct"])
    {
        auto dir = format("doc/%s", name);
        rm(dir, "rf");
        cp("doc/src/assets/", dir, "r");
        vshellf("ddox generate-html doc/src/%s.json doc/%s", name, name);
    }
}

enum usage = `
Usage: rdmd build [options]
build.d is an rdmd script used to build the pfft library. It saves the 
generated library and include files to ./generated. 
The script must be run from the directory it resides in.

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
  --portable            Build a portable library. A portable library is a library that can
                        be used with any D or C compiler that supports the object format.
                        This doesn't currently work with DMD on windows.
  --dynamic             Build a dynamic library.
  --tests               Build tests. Executables will be saved to ./test. 
                        Can not be used when cross compiling. You must build the 
                        D library for selected types before building tests.
  --pgo                 Enable profile guided optimization. This flag can
                        only be used with GDC on Linux.This flag is ignored 
                        when building tests.
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
    bool portable;
    bool dynamic;
    bool tests;
    bool help;
    bool dbg;
    bool doc;
    bool pgo;
    string fftw = null;
    string[] versions; 
    string[] flags;
    string[] addModule; 
    Compiler dc = Compiler.GDC;

    getopt(args, 
        "simd", &simdOpt, 
        "type", &types, 
        "dc-cmd", &dccmd, 
        "portable", &portable,
        "dynamic", &dynamic,
        "dc", &dc,
        "tests", &tests,
        "pgo", &pgo,
        "fftw", &fftw,
        "h|help", &help,
        "v|verbose", &verbose,
        "doc", &doc,
        "debug", &dbg,
        "dversion", &versions,
        "flag", &flags,
        "add-module", &addModule);

    types = array(uniq(sort(types)));

    if(types.empty)
        types = ["double", "float", "real"];

    if(dccmd == "")
        dccmd = [
            Compiler.DMD : "dmd", 
            Compiler.GDC : "gdc", 
            Compiler.LDC : "ldc2"][dc];

    if(doc) return buildDoc(dc, dccmd, types);

    if(help) return writeln(usage);
  
    if(dc == Compiler.DMD && portable && !tests)
        invalidCmd("Can not build a portable library using DMD");

    if(fftw)
        stderr.writeln(
            "Building with FFTW support enabled - the generated "
            "executable will be covered by the GPL (see FFTW's license).");

    if(simdOpt == "")
        simdOpt = (dc != Compiler.DMD) ? "sse-avx" : "sse";

    auto dcArgs = commonArgs(dc)
        .compileCmd(dccmd)
        .version_(versions)
        .conditional(dbg, argList.debug_, optimizeFlags)
        .conditional(dc == Compiler.GDC, argList.raw("-fno-strict-aliasing"))
        .raw(flags.map!(a => "-"~a).array);

    auto buildDir = "generated";
    if(tests)
    {
        cd("test");
        buildTests(types, dcArgs, dc, "..", fftw);
    }
    else
    {
        Version v = parseVersion(simdOpt);

        if(pgo && !isLinux)
        {
            stderr.writefln("PGO currently only works on Linux!");
            pgo = false;
        }

        if(pgo && !v.supportedOnHost)
        {
            pgo = false;
            stderr.writefln(
                "Building with the --pgo flag, but not all SIMD "
                "instruction sets needed for \"--simd %s\" are supported on "
                "host. Continuing with build, but with PGO turned off.", 
                v.name);
        }

        rm(buildDir, "rf");
        mkdir(buildDir);
        cd(buildDir);
        mkdir("lib");
        mkdir("include");

        copyIncludes(types, portable);

        if(portable)
            buildCObjects(dc, types, dcArgs);
        
        buildLib(pgo, dc, v, types, dcArgs, portable, dynamic, addModule);

        version(none)
        foreach(e; dirEntries(".", SpanMode.shallow, false))
            if(e.isFile)
                rm(e.name);
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
