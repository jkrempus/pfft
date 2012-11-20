module interpolate;

import std.stdio, std.format, std.typecons, std.ascii, std.range, 
    std.algorithm, std.exception;

public import std.string: format;

/**
Used for string interpolation. Returns code that interpolates the string.
The returned code is meant to be used in a mixin expression. 

When the returned code is mixed in, any substring of the input string wrapped
that is wrapped in braces  and prefixed with a percent sign (including
the braces and the percent sign) will be replaced with the formated value of
the D expression inside the braces. You can control the formating by prefixing
the opening brace with a format string (see the documentation of std.format),
instead of using just a percent sign. If you want a percent sign in the result, 
use two successive percent signs in the input string. 

Example:
---
    int percentage = 10;
    double part = 0.2;
    string whole = "two"; 
 
    enum s = `%{percentage}%% of %{whole} is %.2f{part}`;
    auto result = "10% of two is 0.20";
    assert(mixin(interpolate(s)) == result);
---
*/
auto interpolate(string s)
{
    auto fm = "";
    auto args = "";
    
    enum State{ text, percent, format, arg }
    
    State state = State.text;
    foreach(dchar c; s)
    final switch(state)
    {
        case State.text:
            fm ~= c; 
            if(c == '%')
                state = State.percent;
            break;

        case State.percent:
            if(c == '%')
            {
                fm ~= '%';
                state = State.text;
            }
            else if(c == '{')
            {
                fm ~= "s";
                state = State.arg;
            }
            else
            {
                fm ~= c;
                state = State.format;
            }
            break;

        case State.format:
            if(c == '{')
                state = State.arg;
            else
                fm ~= c;
            break;
 
        case State.arg:
            if(c == '}')
            {
                args ~= ", ";
                state = State.text;
            }
            else
                args ~= c;
            break;
    }
    enforce(state == State.text, "Can not interpolate the string");   
 
    return "format(`"~fm~"`, "~args~")";
}



unittest
{
    int percentage = 10;
    double part = 0.2;
    string whole = "two"; 
 
    auto s = mixin(interpolate(`%{percentage}%% of %{whole} is %.2f{part}`));
    assert(s == "10% of two is 0.20");
}
