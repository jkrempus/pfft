//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module impl_float;

version(Scalar)
{
	public import pfft.scalar;
}
else version(Neon)
{
	public import pfft.neon;
}
version(StdSimd)
{
	import pfft.stdsimd;
}
else
{
	public import pfft.sse;
}
