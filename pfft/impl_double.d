module impl_double;

version(Scalar)
{
	public import pfft.scalar_double;
}
else
{
	public import pfft.sse_double;
}
