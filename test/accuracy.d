#!/usr/bin/env rdmd
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.process, std.string, std.range, std.algorithm, 
    std.conv, std.file, std.format, std.exception, std.parallelism, 
    std.getopt, std.path : absolutePath;

alias format fm;

@property p(string[] a)
{
    version(linux)
        return taskPool.parallel(a);
    else
        return a;
}

template Alias(alias a)
{
    alias Alias = a;
}

shared verbose = 1;

auto vshell(string cmd, int vcmd, int vout)
{
    if(verbose >= vcmd)
    { 
        writeln(cmd);
        stdout.flush();
    }
   
    auto r = shell(cmd);
    if(verbose >= vout)
    { 
        writeln(r);
        stdout.flush();
    }

    return r; 
}


void test(string common = "", string api = "")
{
    auto toleratedError = [
        "float" : 1e-6,
        "double": 2e-15,
        "real"  : 2e-18];

    foreach(flags;  ["", "-r", "-i", "-i -r"].p)
    foreach(impl;   (api == "" ? ["pfft", "c", "std"] : [api]).p)
    foreach(type;   ["float", "double", "real"].p)
    foreach(log2n;  iota(1, 21))
    {
        void f(int[] sizes)
        {
            auto path =  absolutePath(fm("test_%s", type));
            auto cmd = fm(`%s %s %s %(%s %) %s`, 
                path, flags, impl, sizes, common);

            scope(failure)
                writefln("Error when executing %s.", cmd);

            auto output = vshell(cmd, 3, 4);
            scope(failure)
                writefln("Command %s has failed with output: %s", cmd, output);

            auto err = to!double(strip(output));
            auto tolerated = toleratedError[type];

            enforce(err < tolerated, fm(
                    "Command %s returned relative error %s, but only %s is tolerated for type %s",
                    cmd, err, tolerated, type));
        }

        f([log2n]);
        if(impl == "std")
            continue;

        if(2 * log2n < 22)
            f([log2n, log2n]);

//        if(3 * log2n < 22)
//            f([log2n, log2n, log2n]);
    }
}

void initBuild()
{
    auto dir = getcwd();
    chdir("..");
    vshell("dmd build buildutils", 2, 2);
    chdir(dir); 
}

void build(string flags, bool dynamicC)
{
    scope(failure)
        writefln("Error when building with flags: %s", flags);

    auto dir = getcwd();
    chdir("..");
    auto path = absolutePath("build");

    auto f = (string fs) => vshell(fm(fs, path, flags), 2, 2); 
    f(dynamicC ? "%s %s --clib" : "%s %s");
    f(dynamicC ? "%s %s --dynamic-tests" : "%s %s --tests --clib");

    chdir(dir); 
}

void all(string commonFlags, bool dynamicC, 
    bool skipDmd = false, bool skipMinGW = false)
{
    auto f = (string prepend, string[] simd) =>
        simd.map!(a => fm("%s --simd %s", prepend, a))().array();

    import cpuid = core.cpuid;
    auto avx = cpuid.avx ? ["avx"] : [];

    version(linux)
    {
        auto flags = 
            f("--dc GDC", avx ~ ["sse-avx", "sse", "scalar"]) ~
            f("--dc LDC", avx ~ ["sse", "scalar"]) ~
            f("--dc DMD",  ["sse", "scalar"]) ~
            f(`--dc DMD --dc-cmd "dmd -m32"`,  ["scalar"]) ~
            f(`--dc GDC --dc-cmd "gdc -m32"`, 
                avx ~ ["sse-avx", "sse", "scalar"]);
    }
    else version(OSX)
    {
        auto flags = 
            f("--dc DMD",  ["sse", "scalar"]) ~
            f("--dc LDC",  avx ~ ["sse-avx", "sse", "scalar"]);
    }
    else version(Windows)
    {
        auto flags = 
            f("--dc GDC --no-pgo", avx ~ ["sse-avx", "sse", "scalar"]) ~
            f("--dc DMD",  ["scalar"]) ~
            f(`--dc GDC --no-pgo --dc-cmd "gdc -m32"`, 
                avx ~ ["sse-avx", "sse", "scalar"]);
    }
    else
        static assert("Not supported on this platform.");
   
    initBuild();

    foreach(e; flags)
    {
        auto flagStr = e ~ " " ~ commonFlags;

        if(skipDmd && flagStr.canFind("DMD"))
            continue;

        version(Windows)
            if(skipMinGW && flagStr.canFind("GDC"))
                continue;

        build(flagStr, dynamicC);
        scope(failure)
            writefln(
                "Error when running tests for executables built with %s", flagStr);

        test("", dynamicC ? "c" : "");
        if(verbose)
            writefln("Successfully ran tests for build flags %s.", flagStr);
    }
}

void main(string[] args)
{
    string api = "";
    string flags = "";
    getopt(args,
        "v", &verbose, 
        "flags", &flags,
        "api", &api);

    if(args[1 .. $] == ["all"])
    {
        all("", false);
        all("--debug", false);
    }
    else if(args[1 .. $] == ["all-dynamic-c"])
    {
        all("", true, true);
        all("--debug", true, true);
    }
    else
        test(flags, api);
}
