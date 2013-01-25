module buildutils;

import std.stdio, std.process, std.string, std.array, std.algorithm, std.uuid, 
       std.conv, std.range, std.getopt, std.file, std.regex, std.exception,
       std.path : absolutePath, dirSeparator, buildPath, pathSplitter;

version(Windows)
    enum isWindows = true;
else
    enum isWindows = false;

enum Compiler { DMD, GDC, LDC }

bool verbose = false;

template staticIota(int n, T...)
{
    static if(n)
        alias staticIota!(n-1, n-1, T) staticIota;
    else
        alias T staticIota;
}

auto vshell(string cmd)
{
    if(verbose)
        stderr.writeln(cmd);

    auto r = shell(cmd);

    if(verbose)
        stderr.writeln(r);

    return r;
}

private string fn(string prefix, string path, string suffix)
{
    auto s = path.replace("/", dirSeparator).pathSplitter();
    auto name = s.back();
    s.popBack();

    return buildPath(reduce!buildPath("", s), prefix ~ name ~ suffix); 
}

auto randomFileName()
{
    return buildPath(tempDir(), "_" ~ randomUUID().toString().replace("-", ""));
}

private string fn(string path, string suffix = "")
{
    return path.replace("/", dirSeparator) ~ suffix;
}

string libName(Compiler c, string value)
{
    return isWindows && c == Compiler.DMD ? 
        fn(value, ".lib") : fn("lib", value, ".a");
}

string dynlibName(Compiler c, string value)
{
    return isWindows && c == Compiler.DMD ? 
        fn(value, ".lib") : fn("lib", value, ".so");
}

string objName(Compiler c, string value)
{
    return isWindows && c == Compiler.DMD ? 
        fn(value, ".obj") : fn(value, ".o");
}

string outputFlag(Compiler c){ return c == Compiler.GDC ? "-o " : "-of"; }

string exeName(Compiler c, string value)
{
    return isWindows ? fn(value, ".exe") : fn(value);
}

struct Arg
{
    enum Type
    {
        // arguments that don't use value
        none,
        noOutput,
        inline,
        release,
        optimize,
        debug_,
        g,
        genObj,
        genLib,
        genDynlib,
        pic,
        noDefaultLib,
        // arguments that use value
        version_,
        ipath,
        lpath,
        path,
        compileCmd,
        src,
        raw,
        lib,
        obj,
        dynlib,
        linkTo,
        deps,
        module_,
        output,
    }

    template hasValue(Type type){ enum hasValue = type >= Type.version_; }

    Type type;
    string value;

    string str(Compiler dc) const
    {
        if(isWindows && dc == Compiler.DMD)
            with(Type) switch(type)
            {
                case linkTo: return value~".lib";
                case lpath: enforce(0, "lpath is not supported with DMD on Windows");
                default: {};
            }

        with(Type) switch(type)
        {
            case genObj: return "-c";
            case genDynlib: return "-shared";
            case src: return fn(value, value.endsWith(".d") ? "" : ".d");

            case raw: return value;
            case lib: return libName(dc, value);
            case dynlib: return dynlibName(dc, value);
            case obj: return objName(dc, value);
            case g: return "-g";
            case path: return fn(value);
            default: {}
        }

        if(dc == Compiler.GDC)
            with(Type) switch(type)
            {
                case noDefaultLib: return "-nophoboslib";
                case pic: return "-fPIC";
                case version_: return "-fversion="~value;
                case ipath: return "-I "~value;
                case lpath: return "-L "~value;
                case linkTo: return "-l"~value;
                case noOutput: return "-fsyntax-only";
                case inline: return "-finline-functions";
                case release: return "-frelease";
                case optimize: return "-O3";
                case debug_: return "-fdebug";
                case deps: return "-fdeps="~fn("", value, "");
                default: enforce(0, "str() does not suport arg type "~
                    type.to!string~" for compiler "~dc.to!string);
            }

        if(dc == Compiler.LDC)
            with(Type) switch(type)
            {
                case noDefaultLib: return "-nodefaultlib";
                case version_: return "-d-version="~value;
                case optimize: return "-O3";
                case inline: return "-enable-inlining";
                case pic: return "-relocation-model=pic";
                default: {}
            }

        with(Type) switch(type)
        {
            case pic: return "-fPIC";
            case deps: return "-deps="~value;
            case linkTo: return "-L-l"~value;
            case version_: return "-version="~value;
            case optimize: return "-O";
            case inline: return "-inline";
            case release: return "-release";
            case debug_: return "-debug";
            case ipath: return "-I"~value;
            case lpath: return "-L-L"~value;
            case noOutput: return "-o-";
            case genLib: return "-lib";
            default: enforce(0, "str() does not suport arg type "~
                type.to!string~" for compiler "~dc.to!string);
        }

        assert(0);
    }
}

private void buildLibGdc(
    string cmd, string outputName)
{
    auto dcCmd = "";
    auto objs = "";
    auto hasSources = false;
    
    foreach(s; cmd.splitter(" "))
    {
        if(s.endsWith(".o"))
            objs ~= " "~s;
        else
            dcCmd ~= " "~s;

        hasSources = hasSources || s.endsWith(".d");
    }

    if(hasSources)
    {
        auto tmpObjName = objName(Compiler.GDC, randomFileName());
        vshell(dcCmd~" -c -o "~tmpObjName);
        objs ~= " "~tmpObjName;
    }

    auto outLibName = libName(Compiler.GDC, outputName);
    
    try remove(outLibName); catch {} 

    vshell("ar cr "~outLibName~" "~objs);
    return;
}

void runCompiler(Compiler dc, immutable(Arg)[] flags)
{
    with(Arg.Type)
    {
        string cmd = 
            dc == Compiler.DMD ? "dmd" :
            dc == Compiler.GDC ? "gdc" : "ldc2";

        string args = "";
        auto outputType = none;
        string outputName = null;
        auto noOutputFlag = false;
        foreach(f; flags) 
        {
            if([genLib, genDynlib, genObj].canFind(f.type))
            {
                enforce(outputType == none, 
                    "there can only be one argument of type genLib, genDynlib, or genObj");
                
                outputType = f.type;
            }
            else if(f.type == noOutput)
                noOutputFlag = true;
            else if(f.type == output)
            {
                enforce(outputName is null, 
                    "there can only be one argument of type output");

                outputName = f.value;
            }
            else if(f.type == compileCmd)
                cmd = f.value;
            else
                args ~= " "~f.str(dc);
        }

        if(dc == Compiler.LDC)
            cmd ~= " -singleobj";

        string tmpObj = null;

        if(noOutputFlag)
        {
            vshell(cmd~" "~args~" "~Arg(noOutput, null).str(dc));
            return;
        }

        enforce(outputName !is null, 
            "Unless there is an argument of type noOutput, there must be an argument of type output.");
    
        if(outputType == genLib && dc == Compiler.GDC)
            return buildLibGdc(cmd~" "~args, outputName);

        if(isWindows && outputType == genDynlib && dc == Compiler.GDC)
            args ~= " -Wl,--output-def="~outputName~".def";

        if(outputType != none)
            args ~= " "~Arg(outputType, null).str(dc);
     
        auto nameFn = 
            outputType == none ? &exeName :
            outputType == genObj ? &objName :
            outputType == genLib ? &libName : 
            outputType == genDynlib ? &dynlibName : null;

        vshell(cmd~" "~args~" "~outputFlag(dc) ~ nameFn(dc, outputName));
    }
} 

struct ArgList
{
    immutable(Arg)[] args;

    template argType(string name) { enum argType = mixin("Arg.Type."~name); }

    ArgList opDispatch(string name)(string[] values...) 
        if(is(typeof(argType!name)) && Arg.hasValue!(argType!name))
    {
        ArgList r = this;
        foreach(val; values)
            r.args ~= immutable(Arg)(argType!name, val);

        return r;
    } 

    ArgList opDispatch(string name)()
        if(is(typeof(argType!name)) && !Arg.hasValue!(argType!name))
    {
        return ArgList(args ~ Arg(argType!name, null));
    }

    ArgList opBinary(string op)(ArgList other) if(op == "~")
    {
        return ArgList(args ~ other.args);
    }

    ArgList conditional(A...)(A a)
    {
        foreach(i; staticIota!(A.length / 2))
            if(a[2 * i])
                return this ~ a[2 * i + 1];

        static if(A.length % 2 != 0)
            return this ~ a[$ - 1];

        return this;
    }

    void run(Compiler c)
    {
        runCompiler(c, args);
    }
}

enum argList = ArgList([]);

ArgList addDependencies(Compiler c, immutable(string)[] modules, ArgList args)
{
    ArgList files;
    int[string] moduleSet;
   
    { 
        auto depsFile = randomFileName();
        auto srcModule = randomFileName();
        std.file.write(
            srcModule~".d", 
            modules.map!(a => "import "~a~";\n").join());
         
        args.src(srcModule).deps(depsFile).noOutput.run(c);

        auto depsLine = regex(`([\w.]+) \(([^\)]+)\)`, `g`);
        foreach(capt; match(readText(depsFile), depsLine))
        {
            auto name = strip(capt[1]);
            auto path = strip(capt[2]);
            
            if(
                name.startsWith("core.") || 
                name.startsWith("std.") || 
                name == srcModule ||
                name == "object") 
            { 
                continue;
            }

            if(name in moduleSet)
                continue;

            writeln(name);

            moduleSet[name] = 1;
            files = files.src(absolutePath(path)); 
        }
    }

    return ArgList(
        args.args.filter!(x => x.type != Arg.Type.src).array ~ files.args);
}

ArgList addDependencies(Compiler c, ArgList args)
{
    return addDependencies(c,
        args.args.filter!(a => a.type == Arg.Type.module_).map!(a => a.value).array,
        ArgList(args.args.filter!(a => a.type != Arg.Type.module_).array));
}

version(none)
void main()
{
    auto files = addDependencies(
        Compiler.DMD, 
        argList
            .ipath("/home/j/razno/d/fft/pfft/")
            .module_("pfft.impl_float")
            .module_("pfft.impl_double"));

    writeln(files);

//    verbose = true;
//    argList.src("random_test").genLib.output("random_test").run(Compiler.GDC);
}
