module impl_float;

version(Scalar)
{
	public import pfft.scalar;
}
else version(Neon)
{
	public import pfft.neon;
}
else
{
	public import pfft.sse;
}
