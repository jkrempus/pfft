#!/usr/bin/env rdmd
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.process, std.string, std.range, std.algorithm, std.conv,
    std.file, std.format, std.getopt, std.path : buildPath;
import plot2kill.all;

alias format fm;

struct Test
{
    double[string] cache;
    string filename;

    this(typeof(null) param)
    {
        filename = "cache";
        try load(); catch(FileException e) {}
    }

    void load()
    {
        auto s = readText(filename);
        formattedRead(s, "%s", &cache);
    }

    void save()
    {
        auto a = appender!string();
        formattedWrite(a, "%s", cache);
        std.file.write(filename, a.data);    
    }

    auto run(string cmd, string flags, string impl, int log2n)
    {
        auto command = format("%s %s %s %s", cmd, flags, impl, log2n);
        auto p = command in cache;
        
        if(p)
            return *p;

        auto output = vshell(command, 2, 2);
        auto r = to!double(strip(output));
        cache[command]  = r;
        save();
        return r;
    }

}

shared verbose = 1;

auto vshell(string cmd, int vcmd, int vout)
{
    if(verbose >= vcmd) 
        writeln(cmd); 
   
    auto r = shell(cmd);
    if(verbose >= vout)
        write(r);

    return r; 
}

auto vchdir(string to, int vcmd)
{
    if(verbose >= vcmd)
        writefln("changing directory to %s", to);

    chdir(to); 
}

enum fftwAvxDir = "/opt/fftw/lib";
enum fftwSseDir = "/opt/fftw-sse/lib";

enum implNames = [
    "pfft"          : "pfft.pfft",
    "std"           : "pfft.stdapi",
    "phobos"        : "std.numeric.Fft",
    "fftw"          : "fftw",
    "fftw-measure"  : "fftw-measure"];

enum colors = [
    getColor(0,0,0),
    getColor(255, 0, 0),
    getColor(0, 0, 255),
    getColor(0, 255, 0),
    getColor(130, 130, 0),
    getColor(0, 130, 130),
    getColor(130, 0, 130),
];

void main(string[] args)
{
    getopt(args, "v", &verbose);

    auto projectRoot = buildPath(getcwd(), ".."); //buildPath(getcwd(), args[0], "..");
    auto prefix = buildPath(getcwd(), args[1]) ~ "/";
    if(!exists(prefix))
        mkdir(prefix);

    vchdir(prefix, 1);

    auto cmd(string ver, string type, string compiler)
    {
        auto dir = "executables";
        if(!exists(dir))
            mkdir(dir);

        compiler = compiler == "" ? "gdc" : compiler;

        auto exe = fm("%s/test_%s_%s_%s", dir, type, ver, compiler);

        if(!exists(exe))
        {
            auto fftwDir = ver.canFind("avx") ? fftwAvxDir : fftwSseDir;

            vchdir(projectRoot, 1);
            auto dc = toUpper(compiler);
            vshell(fm(
                "./build.d --dc %s --type %s --simd %s;"
                "./build.d --dc %s --type %s --tests --fftw %s",
                dc, type, ver, dc, type, fftwDir), 1, 1);
            vchdir(prefix, 1);
            vshell(fm("cp %s/test/test_%s %s", projectRoot, type, exe), 1, 1); 
        }

        return exe;
    }

    auto log2nRange = iota(1, 23);
    auto xTickLabels = log2nRange.map!(to!string)().array();

    auto test = Test(null);

    void makePlot(
        string fileName, string flags, string type, 
        string[] impls, string[] versions, string[] compilers = [""])
    {
        auto fig = Figure();
         
        foreach(i, impl; impls)
        foreach(j, ver; versions)
        foreach(k, compiler; compilers)
        {
            auto gflops = log2nRange.map!(
                log2n => test.run(cmd(ver, type, compiler), flags, impl, log2n))();

            auto colorIndex = k + (j + i * versions.length) * compilers.length;
            auto p = LineGraph(log2nRange, gflops)
                .legendText(fm("%s %s %s", implNames[impl], ver, compiler))
                .lineColor(colors[colorIndex]);

            fig.addPlot(p);  
        }

        fig
            .title("")
            .horizontalGrid(true)
            .verticalGrid(true)
            .gridIntensity(cast(ubyte) 80)
            .xLabel("log2(n)")
            .yLabel("speed(GFLOPS)")
            .xTickLabels(log2nRange, xTickLabels.array())
            .legendLocation(LegendLocation.right)
            .saveToFile(fileName, 640, 360);
    }

    auto versions = ["sse-avx", "sse"];

    makePlot("pfft-fftw-float.png", "-s", "float", ["pfft", "fftw"], versions);
    makePlot("pfft-fftw-double.png", "-s", "double", ["pfft", "fftw"], versions);
    makePlot("pfft-fftw-real-float.png", "-s -r", "float", ["pfft", "fftw"], versions);
    makePlot("pfft-fftw-real-double.png", "-s -r", "double", ["pfft", "fftw"], versions);
    
    /*makePlot("pfft-std-phobos-float-scalar.png", "-s", "float", ["pfft", "std", "phobos"], ["scalar"]);
    makePlot("pfft-std-phobos-float-sse.png", "-s", "float", ["pfft", "std", "phobos"], ["sse"]);
    makePlot("pfft-std-phobos-float-avx.png", "-s", "float", ["pfft", "std", "phobos"], ["sse-avx"]);
    
    makePlot("pfft-float-sse-gdmd-ldc-dmd.png", "-s", "float", ["pfft"], ["sse"], ["gdmd", "ldc", "dmd"]);*/
    
    /*makePlot("fftw-float.png", "-s", "float", ["fftw"], versions);
    makePlot("fftw-double.png", "-s", "double", ["fftw"], versions);
    makePlot("fftw-float.png", "-s -r", "float", ["fftw"], versions);
    makePlot("fftw-double.png", "-s -r", "double", ["fftw"], versions);*/
}
