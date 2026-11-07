using System.Collections;

namespace GalaxyGenerator.Core;

struct Point3D: this(float X, float Y, float Z);

struct Star: this(Point3D Position, StarColor Color);
struct StarColor: this(int32 Hex);

enum GaussianGenerator
{
	case Elliptic(Point3D radii, Point3D deviation, Point3D flattening);
	case Spheric(float deviation);
}

enum GalaxyType
{
	case Ring(List<Star> stars);
	case Spiral(List<Star> stars);
}

struct GalaxyCenterConfig: this(
	int NumberOfStars,
	GaussianGenerator Generator
);

struct GalaxyRingConfig: this(
	int NumberOfStars,
	float Radius,
	float Thickness,
	float Height,
	float RadialSpread
);

struct GalaxyArmsConfig: this(
	int NumberOfStars,
	int ArmCount,
	float StartRadius,
	float Growth,
	float Turns,
	float Width,
	float Spread,
	float Height
);

static
{
	public const int32 Red = (int32)0xff0000ff;
	public const int32 Green = (int32)0x00ff00ff;
	public const int32 Blue = (int32)0x0000ffff;
	public const int32 White = (int32)0xffffffff;
}