import std.stdio, std.process, std.string, std.array, std.algorithm, 
       std.conv, std.range, std.getopt, std.file, std.path : buildPath;

enum SIMD{ AVX, SSE, Scalar }
enum Compiler{ DMD, GDC, LDC }

struct Types{ SIMD simd; string[] types; }

alias format fm;

auto shellf(A...)(A a){writeln(fm(a)); return shell(fm(a)); }

enum libPath = buildPath("lib", "libpfft.a");
enum clibPath = buildPath("lib", "libpfft-c.a");

void execute(Cmds...)(Cmds cmds)
{
    foreach(c; cmds)
    {
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
            case Compiler.GDC:
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
        buildGdcImpl(t, dcpath, ccpath, clib, "-fprofile-generate");
        buildTests(t, dcpath, Compiler.GDC, ".", false, "-fprofile-generate");
        runBenchmarks(t);
        buildGdcImpl(t, dcpath, ccpath, clib, fm("-fprofile-use %s", flags));
    }
    else
        buildGdcImpl(t, dcpath, ccpath, clib, flags);
}

void copyIncludes()
{
    foreach(type; ["float", "double", "real"])
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

enum usage = "";

void invalidCmd(string message = "")
{
    if(message != "")
        stderr.writefln("Invalid command line: %s", message);
    
    stderr.writeln(usage); 
    core.stdc.stdlib.abort();
}

void main(string[] args)
{
    auto t = Types(SIMD.SSE, []);
    string dcpath = "";
    string ccpath = "gcc";
    auto clib = false;
    bool nopgo = false;
    bool tests = false;
    string flags = "";
    Compiler dc = Compiler.GDC;

    getopt(args, 
        "simd", &t.simd, 
        "type", &t.types, 
        "dc-path", &dcpath, 
        "cc-path", &ccpath,
        "clib", &clib,
        "dc", &dc,
        "tests", &tests,
        "no-pgo", &nopgo,
        "flags", &flags);
  
    if(tests && clib)
        invalidCmd("Can not build tests for the c library.");

    if(dcpath == "")
        dcpath = [
            Compiler.DMD : "dmd", 
            Compiler.GDC : "gdmd", 
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

    copyIncludes();

    if(clib)
        buildCObjects(t, dcpath, ccpath);
    
    if(dc == Compiler.GDC)
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
}
