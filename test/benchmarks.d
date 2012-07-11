#!/usr/bin/env rdmd
import std.stdio, std.process, std.string, std.range, std.algorithm, std.conv,
    std.file, std.format;
import plot2kill.all;

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
    auto cmd = (string ver, string type) => format("./test_%s_%s", type, ver);

    auto prefix = args[1];

    auto log2nRange = iota(1, 23);
    auto xTickLabels = log2nRange.map!(to!string)().array();

    auto test = Test(prefix);

    void makePlot(string fileName, string flags, string type, string[] impls, string[] versions)
    {
        auto fig = Figure();
         
        foreach(i, impl; impls)
            foreach(j, ver; versions) 
            {
                auto gflops = log2nRange.map!(
                    log2n => test.run(cmd(ver, type), flags, impl, log2n))();
                 
                auto p = LineGraph(log2nRange, gflops)
                    .legendText(implNames[impl] ~ " " ~ ver)
                    .lineColor(colors[j + i * versions.length]);
                
                fig.addPlot(p);  
            }

        fig
            .title("Title")
            .xLabel("log2(n)")
            .yLabel("speed[GFLOPS]")
            .xTickLabels(log2nRange, xTickLabels.array())
            .legendLocation(LegendLocation.right)
            .saveToFile(prefix ~ fileName);
    }

    auto versions = ["avx", "sse"];

    makePlot("pfft-fftw-float.png", "-s", "float", ["pfft", "fftw"], versions);
    makePlot("pfft-fftw-double.png", "-s", "double", ["pfft", "fftw"], versions);
    makePlot("pfft-fftw-real-float.png", "-s -r", "float", ["pfft", "fftw"], versions);
    makePlot("pfft-fftw-real-double.png", "-s -r", "double", ["pfft", "fftw"], versions);
    
    makePlot("pfft-std-phobos-float-scalar.png", "-s", "float", ["pfft", "std", "phobos"], ["scalar"]);
}
