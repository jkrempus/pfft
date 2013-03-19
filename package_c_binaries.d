import buildutils;

enum Arch { x86, x86_64 }

void main(string[] args)
{
    auto arch = Arch.x86_64;
    getopt(args, "arch", &arch, "verbose", &verbose);
    vshell("dmd build buildutils");
    auto build = absolutePath("build");
    vshell(build~" --clib" ~ (arch == Arch.x86 ? " --flag m32" : ""));
    vshell(build~" --doc");
    
    auto name = "pfft-c-" ~ 
	(isLinux ? "linux" : isWindows ? "win" : isOSX ? "osx" : "unknown") ~
	arch.to!string;

    cp("generated-c", name, "r");
    cp("doc", name, "r");
    rm(name~"/doc/ddoc", "r");
    auto compress = isWindows ? "7z a %s.zip %s" : "tar czf %s.tar.gz %s";
    vshell(format(compress, name, name));
    rm(name, "r");
}
