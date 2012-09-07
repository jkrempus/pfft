#!/usr/bin/env rdmd
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.process, std.string, std.range, std.algorithm, 
    std.conv, std.file, std.format, std.exception, std.parallelism, 
    std.getopt, std.path : absolutePath;

alias format fm;

@property p(string[] a){ return taskPool.parallel(a); }

auto verbose = 1;

auto vshell(string cmd, int vcmd, int vout)
{
    if(verbose >= vcmd) 
        writeln(cmd); 
   
    auto r = shell(cmd);
    if(verbose >= vout)
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

        auto err = to!double(strip(vshell(cmd, 3, 4)));
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
    vshell(fm("rdmd build.d %s", flags), 2, 2);
    vshell(fm("rdmd build.d --tests %s", flags), 2, 2);
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
            f("--dc GDMD --no-pgo", ["sse", "scalar"]) ~
            f("--dc DMD",  ["scalar"]) ~
            f(`--dc GDMD --no-pgo --dflags "-m32"`, ["sse", "scalar"]);
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
        if(verbose)
		writefln("Successfully ran tests for build flags %s.", e);
    }
}

void main(string[] args)
{
    getopt(args, "v", &verbose);

    if(args[1 .. $] == ["all"])
        all();
    else
        test();
}
