#!/usr/bin/env rdmd
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.process, std.string, std.range, std.algorithm, std.conv,
    std.file, std.format, std.exception, std.parallelism, std.path : absolutePath;

alias format fm;

@property p(string[] a){ return taskPool.parallel(a); }

void main()
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
        auto cmd = fm("%s %s %s %s", path, flags, impl, log2n);
        auto err = to!double(strip(shell(cmd)));
        auto tolerated = toleratedError[type];

        enforce(err < tolerated, fm(
            "Command %s returned relative error %s, but only %s is tolerated for type %s",
            cmd, err, tolerated, type));
    }
}
