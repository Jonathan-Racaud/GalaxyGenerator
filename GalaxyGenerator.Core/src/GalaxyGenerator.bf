using System;
using System.Collections;

namespace GalaxyGenerator.Core;

abstract class GalaxyGenerator
{
	protected GalaxyCenterConfig coreConfig;
	protected GalaxyCenterConfig centerConfig;

	protected Random random = new .() ~ delete _;

	public this(GalaxyCenterConfig coreConfig, GalaxyCenterConfig centerConfig)
	{
		this.coreConfig = coreConfig;
		this.centerConfig = centerConfig;
	}

	public abstract void Generate(out List<Star> stars);

	protected void GenerateCenter(ref List<Star> stars, GalaxyCenterConfig config)
	{
		for (let i in 0...config.NumberOfStars)
		{
			switch (config.Generator)
			{
			case .Elliptic(let radii, let deviation, let flattening):
				GenerateEllipticalDistribution(ref stars, radii, deviation, flattening);
			case .Spheric(let deviation):
				GenerateSphericalDistribution(ref stars, deviation);
			default:
				break;
			}
		}
	}

	protected float GenerateGaussian()
	{
		let u1 = random.NextFloat();
		let u2 = random.NextFloat();

		return Math.Sqrt(-2.f * Math.Log(u1)) * Math.Cos(2.f * Math.PI_f * u2);
	}

	private void GenerateSphericalDistribution(ref List<Star> stars, float deviation)
	{
		let position = Point3D(
			deviation * GenerateGaussian(),
			deviation * GenerateGaussian(),
			deviation * GenerateGaussian()
		);
		let color = StarColor(White);

		stars.Add(.(position, color));
	}

	private void GenerateEllipticalDistribution(ref List<Star> stars, Point3D radii, Point3D deviation, Point3D flattening)
	{
		let x = GenerateGaussian() * deviation.X * flattening.X;
		let y = GenerateGaussian() * deviation.Y * flattening.Y;
		let z = GenerateGaussian() * deviation.Z * flattening.Z;

		let extentX = (x * x) / (radii.X * radii.X);
		let extentY = (y * y) / (radii.Y * radii.Y);
		let extentZ = (z * z) / (radii.Z * radii.Z);
		let extent = (extentX + extentY + extentZ);

		if (extent < 1.f)
		{
			let position = Point3D(x, y, z);
			let color = StarColor(Red);
			stars.Add(.(position, color));
		}
	}
}

class RingGalaxyGenerator: GalaxyGenerator
{
	List<GalaxyRingConfig> ringsConfig = new .() ~ delete _;

	public this(GalaxyCenterConfig coreConfig, GalaxyCenterConfig centerConfig, params GalaxyRingConfig[] ringsConfig) : base(coreConfig, centerConfig)
	{
		this.ringsConfig.AddRange(ringsConfig);
	}

	public override void Generate(out List<Star> stars)
	{
		stars = new .();

		GenerateCenter(ref stars, coreConfig);
		GenerateCenter(ref stars, centerConfig);
		GenerateWavyRings(ref stars);
	}

	private void GenerateRings(ref List<Star> stars)
	{
		for (let ring in ringsConfig)
		{
			for (let i in 0...ring.NumberOfStars)
			{
				let theta = Math.DegreesToRadians(random.Next(0, 360));
				let r = GenerateGaussianRadius(ring.Radius, ring.Thickness, ring.RadialSpread);

				let radialOffset = Math.Abs(r - ring.Radius);
				let normalizedOffset = radialOffset / (ring.Thickness / 2.f);

				let heightFactor = 1.f - normalizedOffset;
				let maxHeight = ring.Height * heightFactor;

				let h = (float)random.Next(
					(int32)(-maxHeight * 100),
					((int32)maxHeight * 100)
				) / 100.f;

				Point3D position = .(
					r * Math.Cos(theta),
					r * Math.Sin(theta),
					h
				);
				let color = StarColor(Blue);

				stars.Add(.(position, color));
			}
		}
	}

	private void GenerateWavyRings(ref List<Star> stars)
	{
	    for (let ring in ringsConfig)
	    {
	        for (let i in 0...ring.NumberOfStars)
	        {
	            let theta = random.NextFloat() * 2.f * Math.PI_f;
	            let r = GenerateGaussianRadius(
	                ring.Radius,
	                ring.Thickness,
	                ring.RadialSpread
	            );

	            let radialOffset = Math.Abs(r - ring.Radius);
	            let normalizedOffset = radialOffset / (ring.Thickness / 2.f);

	            // Reduce the wave amplitude towards the ring edges.
	            let heightFactor = 1.f - normalizedOffset;

	            // Number of complete waves around the ring.
	            let waveCount = 4.f;

	            // Maximum vertical displacement.
	            let amplitude = ring.Height * 1.5f;

	            // Generate the wave.
	            let wave = Math.Sin(theta * waveCount);
				let waveHeight = amplitude * heightFactor * wave;

				let verticalNoise = GenerateGaussian() * 10.f;

				let h = waveHeight + verticalNoise;

	            Point3D position = .(
	                r * Math.Cos(theta),
	                r * Math.Sin(theta),
	                h
	            );

	            let color = StarColor(Blue);
	            stars.Add(.(position, color));
	        }
	    }
	}

	private float GenerateGaussianRadius(float radius, float thickness, float radialSpread)
	{
		let innerRadius = radius - (thickness / 2);
		let outerRadius = radius + (thickness / 2);

		while (true)
		{
			let z = GenerateGaussian();
			let sigma = thickness * radialSpread;
			let r = radius + sigma * z;

			if (r >= innerRadius && r <= outerRadius)
			{
				return r;
			}
		}
	}
}

class SpiralGalaxyGenerator: GalaxyGenerator
{
	GalaxyArmsConfig armsConfig;

	public this(GalaxyCenterConfig coreConfig, GalaxyCenterConfig centerConfig, GalaxyArmsConfig armsConfig) : base(coreConfig, centerConfig)
	{
		this.armsConfig = armsConfig;
	}

	public override void Generate(out List<Star> stars)
	{
		stars = new .();

		GenerateCenter(ref stars, coreConfig);
		GenerateCenter(ref stars, centerConfig);
		GenerateArms(ref stars);
	}

	private void GenerateArms(ref List<Star> stars)
	{
		if (armsConfig.ArmCount <= 0 || armsConfig.NumberOfStars <= 0)
		{
			return;
		}

		let maxAngle = armsConfig.Turns * 2.f * Math.PI_f;
		let sigma = armsConfig.Width * armsConfig.Spread;

		for (let i in 0...armsConfig.NumberOfStars)
		{
			// Distribute the stars evenly between the different arms.
			let armIndex = i % armsConfig.ArmCount;

			// Rotate each arm around the galaxy centre.
			let armOffset = (2.f * Math.PI_f * armIndex) / armsConfig.ArmCount;

			// Random position along the spiral.
			let randomAngle = random.NextFloat();
			let theta = randomAngle * maxAngle;

			// Logarithmic spiral
			let radius = armsConfig.StartRadius * Math.Exp(armsConfig.Growth * theta);

			// Actual angle, including the arm's rotation.
			let angle = theta + armOffset;

			// Position on the ideal spiral curve.
			let centerX = radius * Math.Cos(angle);
			let centerY = radius * Math.Sin(angle);

			// Calculate the tangent to the spiral.
			let dr = armsConfig.Growth * radius;

			let tangentX = dr * Math.Cos(angle) - radius * Math.Sin(angle);
			let tangentY = dr * Math.Sin(angle) + radius * Math.Cos(angle);

			let tangentLength = Math.Sqrt(tangentX * tangentX + tangentY * tangentY);

			// Perpendicular direction (normal).
			let normalX = -tangentX / tangentLength;
			let normalY = tangentX / tangentLength;

			// Gaussian displacement perpendicular to the spiral.
			let offset = GenerateGaussian() * sigma;

			// Reject points outside the maximum arm width.
			if (Math.Abs(offset) > armsConfig.Width / 2.f)
			{
				continue;
			}

			let x = centerX + normalX * offset;
			let y = centerY + normalY * offset;

			// Gaussian vertical distribution.
			let z = GenerateGaussian() * armsConfig.Height;

			let position = Point3D(x, y, z);
			let color = StarColor(Green);

			stars.Add(.(position, color));
		}
	}
}