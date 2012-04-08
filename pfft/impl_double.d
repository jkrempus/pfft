//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module impl_double;

version(Scalar)
{
	public import pfft.scalar_double;
}
else
{
	public import pfft.sse_double;
}
