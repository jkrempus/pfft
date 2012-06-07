//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.process, std.string, std.array, std.algorithm, 
       std.conv, std.range, std.getopt, std.file, std.path : buildPath;

enum SIMD{ AVX, SSE, Scalar }
enum Compiler{ DMD, GDMD, LDC }

struct Types{ SIMD simd; string[] types; }

alias format fm;

bool verbose;

auto shellf(A...)(A a)
{
    if(verbose) 
        writeln(fm(a)); 
    
    return shell(fm(a)); 
}

enum libPath = buildPath("lib", "libpfft.a");
enum clibPath = buildPath("lib", "libpfft-c.a");

void execute(Cmds...)(Cmds cmds)
{
    foreach(c; cmds)
    {
        if(verbose)
            writeln(c);
        
        shell(c);
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

string sources(Types t, string[] additional)
{
    auto moduleName(string a)
    {
        return simdModuleName(t.simd, a);
    }

    auto m = 
        array(map!moduleName(t.types)) ~ 
        array(map!q{"impl_" ~ a}(t.types)) ~
        ["fft_impl", "bitreverse"] ~
        additional; 

    auto fileName(string a)
    {
        return buildPath("..", "pfft", fm("%s.d", a));
    }

    return join(map!fileName(m), " "); 
}

void buildCObjects(Types t, string dcpath, string ccpath)
{
    auto typeFlags = join(
        map!(a => "-version=" ~ capitalize(a))(t.types), 
        " "); 

    shellf("%s -O -inline -release -c -Iinclude %s %s", 
            dcpath, typeFlags,  buildPath("..", "pfft", "clib.d"));
    shellf("%s %s -c", ccpath, buildPath("..", "c", "dummy.c")); 
}

void buildTests(Types t, string dcpath, Compiler c, string outDir, 
    bool optimized = true, string flags = "")
{
    auto srcPath = buildPath("..", "test", "test.d");
    auto simdStr = to!string(t.simd);

    foreach(type; t.types)
    {
        auto binPath = buildPath(outDir, "test_" ~ type);
        auto ver = capitalize(type);

        auto common = fm("%s -Iinclude %s %s -of%s %s", 
            ver, srcPath, libPath, binPath, flags);

        final switch(c)
        {
            case Compiler.DMD:
            case Compiler.GDMD:
                auto opt = optimized ? "-O -inline -release" : "";
                shellf("%s %s -version=%s -version=%s", 
                    dcpath, opt, simdStr , common);
                break;

            case Compiler.LDC:
                auto opt = optimized ? "-O5 -release" : "";
                shellf("%s %s -d-version=%s -d-version=%s", 
                    dcpath, opt, simdStr, common);
        }
    }
}

void runBenchmarks(Types t)
{
    import std.parallelism;

    foreach(type; t.types)
    {
        if(verbose)
            writefln("Running benchmarks for type %s.", type);

        foreach(i; taskPool.parallel(iota(4,21)))
            shell(fm("./test_%s -s -m 1000 split %s", type, i));
    }
}


void buildDmd(Types t, string dcpath, string ccpath, bool clib)
{
    auto simdStr = to!string(t.simd);
    auto src = sources(t, clib ? ["capi"] : ["stdapi", "splitapi"]);
    auto path = buildPath("lib", "libpfft.a");

    shellf("%s -O -inline -release -lib -of%s -version=%s %s", 
        dcpath, path, simdStr, src);
}

void buildLdc(Types t, string dcpath, string ccpath, bool clib)
{
    enum mattrDict = [SIMD.SSE : "sse2"];

    auto simdStr = to!string(t.simd);
    auto simdStrLC = toLower(simdStr);
    auto llcMattr = mattrDict.get(t.simd, simdStrLC);
    
    auto src = sources(t, clib ? ["capi"] : ["stdapi"]);
    auto path = buildPath("lib", "libpfft.a");

    if(t.simd == SIMD.Scalar)
        shellf("%s -O3 -release -lib -of%s -d-version=%s %s", 
            dcpath, path, simdStr, src);
    else
    {
        execute(
            fm("%s -I.. -O3 -release -singleobj -output-bc -ofpfft.bc -d-version=%s %s", 
                dcpath,  simdStr, src),
            fm("llvm-link %s pfft.bc -o both.bc", 
                buildPath("..", "ldc", simdStrLC ~ ".ll")),
            "opt -O3 -std-link-opts -std-compile-opts both.bc -o both.bc",
            fm("llc both.bc -o both.s -mattr=+%s", llcMattr),
            fm("%s both.s -c", ccpath),
            fm("ar cr %s both.o", path));
    }
}

void buildGdcImpl(Types t, string dcpath, string ccpath, bool clib, string flags)
{
    enum mflagDict = [SIMD.SSE : "sse2", SIMD.Scalar : "sse2"];
    
    auto simdStr = to!string(t.simd);
    auto mflag = mflagDict.get(t.simd, toLower(simdStr));
    auto src = sources(t, clib ? [] : ["stdapi", "splitapi"]);
   
    execute(
        fm("%s -O -inline -release -version=%s -m%s %s %s -ofpfft.o -c", 
            dcpath, simdStr, mflag, flags, src),
        fm("ar cr %s pfft.o %s", 
            clib ? clibPath : libPath, clib ? "dummy.o clib.o" : ""));
}

void buildGdc(Types t, string dcpath, string ccpath, bool pgo, bool clib, string flags)
{
    if(pgo)
    {
        buildGdcImpl(t, dcpath, ccpath, false, "-fprofile-generate");
        buildTests(t, dcpath, Compiler.GDMD, ".", false, "-fprofile-generate");
        runBenchmarks(t);
        buildGdcImpl(t, dcpath, ccpath, clib, fm("-fprofile-use %s", flags));
    }
    else
        buildGdcImpl(t, dcpath, ccpath, clib, flags);
}

void copyIncludes(Types t, bool clib)
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

        foreach(type; t.types)
        {
            auto tmp = replace(iStr, "{type}", typeDict[type]);
            auto s = suffixDict[type];
            tmp = replace(tmp, "{suffix}", s);
            tmp = replace(tmp, "{Suffix}", toUpper(s));
            oStr ~= tmp;
        }
        
        std.file.write(buildPath("include", "pfft.h"), oStr);
    }

    foreach(type; t.types)
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
        buildPath("..", "pfft", "splitapi.d"), 
        buildPath("include", "pfft", "splitapi.d"));
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
                        or with LDC)
  --simd SIMD           SIMD instruction set to use. Must be one of SSE, AVX
                        and Scalar.
  --type TYPE           Arithmetic type that the resulting library will support.
                        TYPE must be one of float, double and real. There can
                        be more than one --type flag. Omitting this flag is 
                        equivalent to --type float --type double --type real.
  --clib                Build a C library
  --tests               Build tests. Executables will be saved to test
                        directory. Can not be used with --clib.
  --no-pgo              Disable profile guided optimization. This flag can
                        only be used with GDMD. Using this flag will result
                        in slightly worse performance, but the build will be 
                        much faster.
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
    auto t = Types(SIMD.SSE, []);
    string dcpath = "";
    string ccpath = "gcc";
    bool clib;
    bool nopgo;
    bool tests;
    bool help;
    string flags = "";
    Compiler dc = Compiler.GDMD;

    getopt(args, 
        "simd", &t.simd, 
        "type", &t.types, 
        "dc-path", &dcpath, 
        "cc-path", &ccpath,
        "clib", &clib,
        "dc", &dc,
        "tests", &tests,
        "no-pgo", &nopgo,
        "dflags", &flags,
        "h|help", &help,
        "v|verbose", &verbose);

    if(help)
    {
        writeln(usage);
        return;
    }
  
    if(tests && clib)
        invalidCmd("Can not build tests for the c library.");

    t.types = array(uniq(sort(t.types)));

    if(dcpath == "")
        dcpath = [
            Compiler.DMD : "dmd", 
            Compiler.GDMD : "gdmd", 
            Compiler.LDC : "ldc2"][dc];
   
    if(t.types == [])
        t.types = ["float", "double", "real"];

    auto buildDir = clib ? "generated-c" : "generated";
    try rmdirRecurse(buildDir); catch{}
    mkdir(buildDir);
    chdir(buildDir);
    mkdir("lib");
    mkdir("include");
    mkdir(buildPath("include", "pfft"));

    copyIncludes(t, clib);

    if(clib)
        buildCObjects(t, dcpath, ccpath);
    
    if(dc == Compiler.GDMD)
        buildGdc(t, dcpath, ccpath, !nopgo, clib, flags);
    else if(dc == Compiler.LDC)
        buildLdc(t, dcpath, ccpath, clib);
    else
        buildDmd(t, dcpath, ccpath, clib);

    if(tests)
        buildTests(t, dcpath, dc, buildPath("..", "test")); 

    foreach(e; dirEntries(".", SpanMode.shallow, false))
        if(e.isFile)
            remove(e.name);
    if(clib)
        deleteDOutput();
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
    }
}
