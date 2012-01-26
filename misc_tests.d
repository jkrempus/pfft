import std.stdio, std.array, std.range;
import pfft.bitreverse;

void test_bit_reverse_simple_small()
{
    auto a = array(iota(32));
    
    bit_reverse_simple_small!3(a.ptr, 3);
    writeln(a);
    bit_reverse_simple(a.ptr, 3);
    writeln(a);
    writeln("");
    
    bit_reverse_simple_small!4(a.ptr, 4);
    writeln(a);
    bit_reverse_simple(a.ptr, 4);
    writeln(a);
    writeln("");
    
    bit_reverse_simple_small!5(a.ptr, 5);
    writeln(a);
    bit_reverse_simple(a.ptr, 5);
    writeln(a);
    writeln("");
}

void main()
{
    test_bit_reverse_simple_small();
}
