import std.stdio, std.conv;
import pfft.pfft;

void main(string[] args)
{
    alias Pfft!float F;

    auto n = to!int(args[1]);
    auto f = new F(n);
    auto re = F.allocate(n);
    auto im = F.allocate(n);

    foreach(i, _; re)
        readf("%s %s\n", &re[i], &im[i]);

    f.fft(re, im);

    foreach(i, _; re)
        writefln("%s %s", re[i], im[i]);
}
