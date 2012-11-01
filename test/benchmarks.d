#!/usr/bin/env rdmd
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.process, std.string, std.range, std.algorithm, std.conv,
    std.file, std.format;
import plot2kill.all;

alias format fm;

struct Test
{
    double[string] cache;
    string filename;

    this(string prefix)
    {
        filename = prefix ~ "cache";
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

        writeln(command);
        auto output = shell(command);
        write(output);
        auto r = to!double(strip(output));
        cache[command]  = r;
        save();
        return r;
    }

}

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
    auto cmd = (string ver, string type, string compiler) =>
        fm("./test_%s_%s%s%s", type, ver, compiler == "" ? "" : "_", compiler);

    auto prefix = args[1];

    auto log2nRange = iota(1, 23);
    auto xTickLabels = log2nRange.map!(to!string)().array();

    auto test = Test(prefix);

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
            .saveToFile(prefix ~ fileName, 640, 360);
    }

    auto versions = ["sse_avx", "sse"];

    makePlot("pfft-fftw-float.png", "-s", "float", ["pfft", "fftw"], versions);
    makePlot("pfft-fftw-double.png", "-s", "double", ["pfft", "fftw"], versions);
    /*makePlot("pfft-fftw-real-float.png", "-s -r", "float", ["pfft", "fftw"], versions);
    makePlot("pfft-fftw-real-double.png", "-s -r", "double", ["pfft", "fftw"], versions);
    
    makePlot("pfft-std-phobos-float-scalar.png", "-s", "float", ["pfft", "std", "phobos"], ["scalar"]);
    makePlot("pfft-std-phobos-float-sse.png", "-s", "float", ["pfft", "std", "phobos"], ["sse"]);
    makePlot("pfft-std-phobos-float-avx.png", "-s", "float", ["pfft", "std", "phobos"], ["sse_avx"]);
    
    makePlot("pfft-float-sse-gdmd-ldc-dmd.png", "-s", "float", ["pfft"], ["sse"], ["gdmd", "ldc", "dmd"]);*/
    
    /*makePlot("fftw-float.png", "-s", "float", ["fftw"], versions);
    makePlot("fftw-double.png", "-s", "double", ["fftw"], versions);
    makePlot("fftw-float.png", "-s -r", "float", ["fftw"], versions);
    makePlot("fftw-float.png", "-s -r", "double", ["fftw"], versions);*/
}
