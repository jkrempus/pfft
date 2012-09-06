#!/usr/bin/env rdmd
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.process, std.string, std.range, std.algorithm, std.conv,
    std.file, std.format, std.exception, std.parallelism, std.path : absolutePath;

alias format fm;

@property p(string[] a){ return taskPool.parallel(a); }

auto verbose = true;

auto shellf(A...)(A a)
{
    auto cmd = fm(a);
    if(verbose) 
        writeln(cmd); 
   
    auto r = shell(cmd);
    if(verbose)
        write(r);

    return r; 
}


void test()
{
    auto toleratedError = [
        "float" : 1e-6,
        "double": 2e-15,
        "real"  : 2e-18];

    foreach(flags;  ["", "-r", "-i", "-i -r"].p)
    foreach(impl;   ["pfft", "c", "std"].p)
    foreach(type;   ["float", "double", "real"])
    foreach(log2n;  iota(1, 21))
    {
        auto path =  absolutePath(fm("test_%s", type));
        auto cmd = fm(`%s %s %s "%s"`, path, flags, impl, log2n);
        scope(failure)
            writefln("Error when executing %s.", cmd);

        auto err = to!double(strip(shellf(cmd)));
        auto tolerated = toleratedError[type];

        enforce(err < tolerated, fm(
            "Command %s returned relative error %s, but only %s is tolerated for type %s",
            cmd, err, tolerated, type));
    }
}

void build(string flags)
{
    scope(failure)
        writefln("Error when building with flags: %s", flags);

    auto dir = getcwd();
    chdir("..");
    auto out1 = shellf("rdmd build.d %s", flags);
    auto out2 = shellf("rdmd build.d --tests %s", flags);
    enforce(out1 == "" && out2 == "");
    chdir(dir); 
}

void all()
{
    auto f = (string prepend, string[] simd) =>
        simd.map!(a => fm("%s --simd %s", prepend, a))().array();

    version(linux)
    {
        auto flags = 
            f("--dc GDMD", ["avx", "sse-avx", "sse", "scalar"]) ~
            f("--dc LDC",  ["avx", "sse", "scalar"]) ~
            f("--dc DMD",  ["sse", "scalar"]) ~
            f(`--dc DMD --dflags "-m32"`,  ["scalar"]) ~
            f(`--dc GDMD --dflags "-m32"`, ["avx", "sse-avx", "sse", "scalar"]);
    }
    else version(OSX)
    {
        auto flags = 
            f("--dc DMD",  ["sse", "scalar"]);
    }
    else version(Windows)
    {
        auto flags = 
            f("--dc GDMD", ["sse", "scalar"]) ~
            f("--dc DMD",  ["scalar"]) ~
            f(`--dc GDMD --dflags "-m32"`, ["sse", "scalar"]);
    }
    else
        static assert("Not supported on this platform.");
    
    foreach(e; flags)
    {
        build(e);
        scope(failure)
            writefln(
                "Error when running tests for executables built with %s", e);
                
        test();
        writefln("Successfully ran tests for build flags %s.", e);
    }
}

void main(string[] args)
{
    if(args[1 .. $] == ["all"])
        all();
    else
        test();
}
