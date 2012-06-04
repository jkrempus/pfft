import std.stdio, std.process, std.string, std.array, std.algorithm, 
       std.conv, std.range, std.getopt, std.file, std.path : buildPath;

enum SIMD{ AVX, SSE, Scalar }
enum Compiler{ DMD, GDC, LDC }

alias format fm;

auto shellf(A...)(A a){writeln(fm(a)); return shell(fm(a)); }

enum libPath = buildPath("lib", "libpfft.a");

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

string sources(SIMD simd, string[] additional)
{
    auto moduleName(string a)
    {
        return simdModuleName(simd, a);
    }

    auto types = ["float", "double", "real"];

    auto m = 
        array(map!moduleName(types)) ~ 
        array(map!q{"impl_" ~ a}(types)) ~
        ["fft_impl", "bitreverse"] ~
        additional; 

    auto fileName(string a)
    {
        return buildPath("..", "pfft", fm("%s.d", a));
    }

    return join(map!fileName(m), " "); 
}

void buildDummy(string ccpath)
{
    shellf("%s %s -c", ccpath, buildPath("..", "c", "dummy.c")); 
}

void buildTests(SIMD simd, string dcpath, Compiler c, string outDir, 
    bool optimized = true, string flags = "")
{
    auto srcPath = buildPath("..", "test", "test.d");
    auto simdStr = to!string(simd);

    auto f(string type)
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

    f("float"); f("real"); f("double");
}

void runBenchmarks()
{
    void f(string type)
    {
        foreach(i; 4 .. 21)
            system(fm("./test_%s -s -m 1000 split %s", type, i));
    }
    
    f("float"); f("real"); f("double");
}


void buildDmd(SIMD simd, string dcpath, string ccpath, bool clib)
{
    auto simdStr = to!string(simd);
    auto src = sources(simd, clib ? ["capi"] : ["stdapi", "splitapi"]);
    auto path = buildPath("lib", "libpfft.a");

    shellf("%s -O -inline -release -lib -of%s -version=%s %s", 
        dcpath, path, simdStr, src);
}

void buildLdc(SIMD simd, string dcpath, string ccpath, bool clib)
{
    enum mattrDict = [SIMD.SSE : "sse2"];

    auto simdStr = to!string(simd);
    auto simdStrLC = toLower(simdStr);
    auto llcMattr = mattrDict.get(simd, simdStrLC);
    
    auto src = sources(simd, clib ? ["capi"] : ["stdapi"]);
    auto path = buildPath("lib", "libpfft.a");

    if(simd == SIMD.Scalar)
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

void buildGdcImpl(SIMD simd, string dcpath, string ccpath, string flags, bool clib)
{
    enum mflagDict = [SIMD.SSE : "sse2", SIMD.Scalar : "sse2"];
    
    auto simdStr = to!string(simd);
    auto mflag = mflagDict.get(simd, toLower(simdStr));
    auto src = sources(simd, clib ? ["capi"] : ["stdapi", "splitapi"]);
    
    execute(
        fm("%s -O -inline -release -version=%s -m%s %s %s -ofpfft.o -c", 
            dcpath, simdStr, mflag, flags, src),
        fm("ar cr %s pfft.o", libPath));
}

void buildGdc(SIMD simd, string dcpath, string ccpath, bool pgo, bool clib)
{
    if(pgo)
    {
        buildGdcImpl(simd, dcpath, ccpath, "-fprofile-generate", false);
        buildTests(simd, dcpath, Compiler.GDC, ".", false, "-fprofile-generate");
        runBenchmarks();
        buildGdcImpl(simd, dcpath, ccpath, "-fprofile-use", clib);
    }
    else
        buildGdcImpl(simd, dcpath, ccpath, "", clib);
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

void main(string[] args)
{
    SIMD simd = SIMD.SSE;
    string dcpath = "";
    string ccpath = "gcc";
    auto clib = false;
    bool nopgo = false;
    bool tests = false;
    Compiler dc = Compiler.GDC;

    getopt(args, 
        "simd", &simd, 
        "dc-path", &dcpath, 
        "cc-path", &ccpath,
        "clib", &clib,
        "dc", &dc,
        "tests", &tests,
        "no-pgo", &nopgo);
    
    if(dcpath == "")
        dcpath = [
            Compiler.DMD : "dmd", 
            Compiler.GDC : "gdmd", 
            Compiler.LDC : "ldc2"][dc];
    
    auto buildDir = clib ? "generated-c" : "generated";
    try rmdirRecurse(buildDir); catch{}
    mkdir(buildDir);
    chdir(buildDir);
    mkdir("lib");
    mkdir("include");
    mkdir(buildPath("include", "pfft"));

    if(clib)
    {
        buildDummy(ccpath);
    }
    else
        copyIncludes();

    if(dc == Compiler.GDC)
        buildGdc(simd, dcpath, ccpath, !nopgo, clib);
    else if(dc == Compiler.LDC)
        buildLdc(simd, dcpath, ccpath, clib);
    else
        buildDmd(simd, dcpath, ccpath, clib);

    if(!clib && tests)
        buildTests(simd, dcpath, dc, buildPath("..", "test")); 

    foreach(e; dirEntries(".", SpanMode.shallow, false))
        if(e.isFile)
            remove(e.name);
}
