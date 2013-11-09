//          Copyright Jernej Krempuš 2013
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module buildutils;

public import std.file : dirEntries, SpanMode;
public import std.string : format;
public import std.stdio, std.algorithm, std.uuid, std.conv, std.range,
    std.getopt, std.regex, std.exception, std.typecons;

import std.process, std.uuid;
import std.path : absolutePath, buildPath;

static import std.file;

alias std.range.repeat repeat; 

version(Windows)
    enum isWindows = true;
else
    enum isWindows = false;

version(linux)
    enum isLinux = true;
else 
    enum isLinux = false;

version(OSX)
    enum isOSX = true;
else 
    enum isOSX = false;

version(ARM)
    enum isARM = true;
else 
    enum isARM = false;

enum Compiler { DMD, GDC, LDC }

bool verbose = false;

private template staticIota(int n, T...)
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
    import std.path;

    auto s = pathSplitter(path.replace("/", dirSeparator));
    auto name = s.back();
    s.popBack();

    return buildPath(buildPath(s.array), prefix ~ name ~ suffix).absolutePath;
}

private string fn(string path, string suffix = "")
{
    import std.path;

    return absolutePath(path.replace("/", dirSeparator) ~ suffix);
}

void rm(string path, string flags = "")
{
    import std.path, std.file;
    path = fn(path);
    if(verbose)
        stderr.writeln(`rm("`~path~`", "`~flags~`")`);
    try
    {
        if(isDir(path))
        {
            if(flags.canFind('r'))
                rmdirRecurse(path);
            else
                rmdir(path);
        }
        else
            remove(path);
    }
    catch(Exception e)
        if(!flags.canFind('f'))
            throw e;
}

void cp(string src, string dst, string flags = "")
{
    import std.path, std.file;
    src = fn(src);
    dst = fn(dst);

    if(verbose)
        stderr.writeln(`cp("`~src~`", "`~dst~`", "`~flags~`")`);
    
    if(exists(dst) && isDir(dst))
        dst = buildPath(dst, baseName(src));

    try
    {
        if(isDir(src))
        {
            enforce(flags.canFind('r'), new FileException(src, "is a directory"));

            if(!exists(dst))
                mkdir(dst);

            enforce(isDir(dst), new FileException(dst,
                "cannot copy a directory to a non-directory"));

            void recurse(string src, string dst)
            {
                foreach(DirEntry s; dirEntries(src, SpanMode.shallow, true))
                {
                    auto d = baseName(s.name).absolutePath(dst);

                    if(isDir(s))
                    {
                        if(!exists(d))
                            std.file.mkdir(d);

                        recurse(s, d);
                    }
                    else
                        copy(s, d);
                }
            }
            recurse(src, dst);
        }
        else
            copy(src, dst); 
    }
    catch(Exception e)
        if(!flags.canFind('f'))
            throw e;
}

void cp(string[] src, string dst, string flags = "")
{
    foreach(s; src)
        cp(s, dst, flags);
}

void cd(string path)
{
    path = fn(path);
    if(verbose)
        stderr.writeln(`cd("`~path~`")`);

    std.file.chdir(path); 
}

void mkdir(string path, string flags = "")
{
    path = fn(path);
    if(verbose)
        stderr.writeln(`mkdir("`~path~`", "`~flags~`")`);

    if(flags.canFind('p'))
        std.file.mkdirRecurse(path);
    else
        std.file.mkdir(path);
}

string fixSeparators(string s) { return fn(s); }

auto randomFileName()
{
    auto dir = std.file.tempDir();
    return buildPath(dir, "_" ~ randomUUID().toString().replace("-", ""));
}

string libName(Compiler c, string value)
{
    return isWindows && c == Compiler.DMD ? 
        fn(value, ".lib") : fn("lib", value, ".a");
}

string dynlibName(Compiler c, string value)
{
    return 
	isWindows ? fn(value, ".dll") :
	isOSX ? fn("lib", value, ".dylib") : fn("lib", value, ".so");
}

string objName(Compiler c, string value)
{
    return isWindows && c == Compiler.DMD ? 
        fn(value, ".obj") : fn(value, ".o");
}

string exeName(Compiler c, string value)
{
    return isWindows ? fn(value, ".exe") : fn(value);
}

private string outputFlag(Compiler c){ return c == Compiler.GDC ? "-o " : "-of"; }

private struct Arg
{
    enum Type
    {
        // arguments that don't use value
        none,
        noOutput,
        inline,
        release,
        optimize,
        noboundscheck,
        debug_,
        g,
        genObj,
        genLib,
        genDynlib,
        pic,
        noDefaultLib,
        doc,
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
        exclude, // used to exclude a module from auto dependencies
        docFile,
        docDir,
        docInclude,
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
                case dynlib: return libName(dc, value);
                default: {};
            }

        with(Type) switch(type)
        {
            case exclude: return ""; 
            case genObj: return "-c";
            case genDynlib: return "-shared";
            case src: return fn(value,
                value.endsWith(".d") || value.endsWith(".di") ?  "" : ".d");

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
                case doc: return "-fdoc";
                case docFile: return "-fdoc-file="~fn(value);
                case docDir: return "-fdoc-dir="~fn(value);
                case noDefaultLib: return "-nophoboslib";
                case pic: return "-fPIC";
                case version_: return "-fversion="~value;
                case ipath: return "-I "~fn(value);
                case lpath: return "-L "~fn(value);
                case linkTo: return "-l"~value;
                case noOutput: return "-fsyntax-only";
                case inline: return "-finline-functions";
                case release: return "-frelease";
                case optimize: return "-O3";
                case noboundscheck: return "-fno-bounds-check";
                case debug_: return "-fdebug";
                case deps: return "-fdeps="~fn("", value, "");
                case docInclude: return "-fdoc-inc="~fn(value);
                default: enforce(0, "str() does not suport arg type "~
                    type.to!string~" for compiler "~dc.to!string);
            }

        if(dc == Compiler.LDC)
            with(Type) switch(type)
            {
                case docFile: return "-Df="~fn(value);
                case docDir: return "-Dd="~fn(value);
                case noDefaultLib: return "-nodefaultlib";
                case version_: return "-d-version="~value;
                case optimize: return "-O3";
                case noboundscheck: return "-disable-boundscheck";
                case debug_: return "-d-debug";
                case inline: return "-enable-inlining";
                case pic: return "-relocation-model=pic";
                default: {}
            }

        with(Type) switch(type)
        {
            case doc: return "-D";
            case docFile: return "-Df"~fn(value);
            case docDir: return "-Dd"~fn(value);
            case docInclude: return fn(value);
            case pic: return "-fPIC";
            case deps: return "-deps="~value;
            case linkTo: return "-L-l"~value;
            case version_: return "-version="~value;
            case optimize: return "-O";
            case noboundscheck: return "-noboundscheck";
            case inline: return "-inline";
            case release: return "-release";
            case debug_: return "-debug";
            case ipath: return "-I"~fn(value);
            case lpath: return "-L-L"~fn(value);
            case noOutput: return "-o-";
            case genLib: return "-lib";
            default: enforce(0, "str() does not suport arg type "~
                type.to!string~" for compiler "~dc.to!string);
        }

        assert(0);
    }
}

bool ofType(haystack...)(Arg needle)
{
    foreach(h; haystack)
        if(h == needle.type)
            return true;

    return false;
}

template filterType(haystack...)
{
    auto filterType(R)(R r)
    {
        return r.filter!(ofType!haystack);
    }
}

template excludeType(haystack...)
{
    auto excludeType(R)(R r)
    {
        return r.filter!(a => !ofType!haystack(a));
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
    
    rm(outLibName, "f");

    vshell("ar cr "~outLibName~" "~objs);
    return;
}

private void runCompiler(Compiler dc, immutable(Arg)[] flags)
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
            if(f.ofType!(genLib, genDynlib, genObj))
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

        enforce(outputName !is null, 
            "There must be an argument of type output.");

        if(noOutputFlag)
        {
            auto oflag = outputFlag(dc) ~ fn(outputName);
            vshell(cmd~" "~args~" "~Arg(noOutput, null).str(dc)~" "~oflag);
            return;
        }

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

private alias Tuple!(string, string, string, string) Quad;

auto fixBackslashes(string s)
{
    return isWindows ? s.replace(`\\`, `\`) : s;
}

// Runs the compiler to get the dependency list 
// for given args and parses the list.
private auto generateDeps(immutable(Arg)[] args, Compiler c)
{
    import std.path;
    
    alias immutable(Arg) A;
    alias Arg.Type AT;

    auto modules = args.filterType!(AT.module_);

    args = args.excludeType!(AT.module_, AT.doc, AT.docDir, AT.docFile).array;

    auto depsFile = randomFileName();
    auto srcFile = randomFileName();
    std.file.write(
        srcFile~".d",
        modules.map!(a => "import "~a.value~";\n").join);
    
    runCompiler(c, args ~ [
        A(AT.src, srcFile), A(AT.deps, depsFile), A(AT.noOutput, null)]);

    auto srcModule = baseName(srcFile);
    
    auto re = regex(`^([\w.]+) \(([^\)]+)\) : \w+ : ([\w.]+) \(([^\)]+)\)`, `gm`);

    // calling array on result of match() solves all my problems
    return match(std.file.readText(depsFile).fixBackslashes, re).array
        .map!(capt => Quad(
            capt[1] == srcModule ? "" : capt[1], 
            capt[2], 
            capt[3], 
            capt[4]))
        .array;
}

private auto isExcluded(string s, string[] exclude)
{
    return
        zip(exclude, s.repeat)
        .any!(a => 
            a[1].startsWith(a[0].until('*')) && 
            (a[0].back == '*' || a[0] == a[1]));
}

// Takes dependency list as a parameter and removes all modules that mach
// en entry in the exclude array. It also recursively removes any modules 
// that are only imported from the removed modules. It returns the list of
// files names of the remaining modules.
private auto fileList(Quad[] deps, string[] exclude)
{
    alias Tuple!(string, "name", string, "path") Module;

    size_t[string] indices;
    auto modules = new Module[](0);

    foreach(line; deps)
        foreach(i; staticIota!2)
        {
            auto name = line[2 * i];
            if(name in indices)
                continue;

            indices[name] = modules.length;
            modules ~= Module(name, line[2 * i + 1]);
        }

    auto n = modules.length;

    auto adj = iota(n).map!(_ => new size_t[](0)).array;
    foreach(d; deps)
        adj[indices[d[0]]] ~= indices[d[2]];

    auto isRoot = true.repeat(n).array;
    foreach(e; adj)
        foreach(f; e)
            isRoot[f] = 0;

    auto isReachable = false.repeat(n).array;
    void recurse(size_t i)
    {
        if( isReachable[i] || isExcluded(modules[i].name, exclude))
            return;

        isReachable[i] = true;
        foreach(j; adj[i])
            recurse(j);
    }

    foreach(i; iota(n).filter!(a => isRoot[a]))
        recurse(i);

    return iota(n)
        .filter!(i => isReachable[i] && modules[i].name != "")
        .map!(i => modules[i].path)
        .array;
}

auto set(R)(R r)
{
    bool[ElementType!R] ret;

    foreach(e; r)
        ret[e] = true;

    return ret;
}

struct ArgList
{
    alias Arg.Type Type;
    immutable(Arg)[] args;

    template argType(string name) { enum argType = mixin("Type."~name); }

    ArgList opDispatch(string name)(string[] values...) const
        if(is(typeof(argType!name)) && Arg.hasValue!(argType!name)) 
    {
        ArgList r = this;
        foreach(val; values)
            r.args ~= immutable(Arg)(argType!name, val);

        return r;
    } 

    ArgList opDispatch(string name)() const
        if(is(typeof(argType!name)) && !Arg.hasValue!(argType!name))
    {
        return ArgList(args ~ Arg(argType!name, null));
    }

    ArgList opBinary(string op)(const(ArgList) other) const if(op == "~")
    {
        return ArgList(args ~ other.args);
    }

    ArgList conditional(A...)(A a) const
    {
        foreach(i; staticIota!(A.length / 2))
            if(a[2 * i])
                return this ~ a[2 * i + 1];

        static if(A.length % 2 != 0)
            return this ~ a[$ - 1];

        return this;
    }

    ArgList addDependencies(Compiler c) const
    {
        auto exclude = args
            .filterType!(Type.exclude)
            .map!(a => cast(string) a.value)
            .array;

        exclude ~= [ "std.*", "core.*", "object", "gcc.*", "ldc.*"];

        auto files = fileList(generateDeps(args, c), exclude);

        auto r = ArgList(args
            .excludeType!(Type.src, Type.module_)
            .array);

        return reduce!((a,f) => a.src(f))(r, files);
    }

    ArgList findModules(Compiler c) const
    {
        auto modules = args
            .filterType!(Type.module_)
            .map!(a => a.value)
            .set;

        if(modules.length == 0)
            return this;

        auto r = ArgList(args.excludeType!(Type.module_).array);

        foreach(d; generateDeps(args, c))
        {
            if(d[2] !in modules)
                continue;

            modules.remove(d[2]);
            r = r.src(d[3]); 
        }

        return r; 
    }

    ArgList addOutputArg(Compiler c) const
    {
        import std.path;

        if(!args.any!(a => a.type == Type.output))
        {
            auto firstSource = args.find!(ofType!(Type.src, Type.module_));

            if(firstSource.empty)
            {
                if(args.any!(a => a.type == Type.noOutput))
                    return this.output(randomFileName());
                
                enforce(0, "Can not determine the name of the ouput file");
            }
            else if(firstSource.front.type == Type.src)
                return this.output(baseName(firstSource.front.str(c), ".d"));
            else
                return this.output(firstSource.front.value.splitter('.').back);
        }

        return this;
    }

    void run(Compiler c) const
    {
        runCompiler(c, args);
    }

    void build(Compiler c, bool autoDeps = true)
    {
        auto list = addOutputArg(c);
        
        if(autoDeps)
            list.addDependencies(c).run(c);
        else
            list.findModules(c).run(c); 
    }
}

enum argList = ArgList([]);
