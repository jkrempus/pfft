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
