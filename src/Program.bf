using System;

using RaylibBeef;
using System.Collections;
using static RaylibBeef.Raylib;
using static RaylibBeef.Rlgl;

namespace GalaxyGenerator;

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

struct GalaxyArmConfig: this(
	int NumberOfStars,
	int ArmCount,
	float StartRadius,
	float Growth,
	float Turns,
	float Width,
	float Spread,
	float Height
);

struct Star: this(Vector3 Position, Color Color);

enum GaussianGenerator
{
	case Elliptic(Vector3 radii, Vector3 deviation, Vector3 flattening);
	case Spheric(float deviation);
}

enum GalaxyType
{
	case Ring(List<Star> stars);
	case Spiral(List<Star> stars);
}

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

		return Math.Sqrt(-2.f * Math.Log(u1)) * Math.Cos(2.f * PI * u2);
	}

	private void GenerateSphericalDistribution(ref List<Star> stars, float deviation)
	{
		let position = Vector3(
			deviation * GenerateGaussian(),
			deviation * GenerateGaussian(),
			deviation * GenerateGaussian()
		);
		let color = WHITE;

		stars.Add(.(position, color));
	}

	private void GenerateEllipticalDistribution(ref List<Star> stars, Vector3 radii, Vector3 deviation, Vector3 flattening)
	{
		let x = GenerateGaussian() * deviation.x * flattening.x;
		let y = GenerateGaussian() * deviation.y * flattening.y;
		let z = GenerateGaussian() * deviation.z * flattening.z;

		let extentX = (x * x) / (radii.x * radii.x);
		let extentY = (y * y) / (radii.y * radii.y);
		let extentZ = (z * z) / (radii.z * radii.z);
		let extent = (extentX + extentY + extentZ);

		if (extent < 1.f)
		{
			let position = Vector3(x, y, z);
			let color = RED;
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
		GenerateRings(ref stars);
	}

	private void GenerateRings(ref List<Star> stars)
	{
		for (let ring in ringsConfig)
		{
			for (let i in 0...ring.NumberOfStars)
			{
				let theta = (float)random.Next(0, 360) * DEG2RAD;
				let r = GenerateGaussianRadius(ring.Radius, ring.Thickness, ring.RadialSpread);

				let radialOffset = Math.Abs(r - ring.Radius);
				let normalizedOffset = radialOffset / (ring.Thickness / 2.f);

				let heightFactor = 1.f - normalizedOffset;
				let maxHeight = ring.Height * heightFactor;

				let h = (float)random.Next(
					(int32)(-maxHeight * 100),
					((int32)maxHeight * 100)
				) / 100.f;

				Vector3 position = .(
					r * Math.Cos(theta),
					r * Math.Sin(theta),
					h
				);
				let color = BLUE;

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
	GalaxyArmConfig armsConfig;

	public this(GalaxyCenterConfig coreConfig, GalaxyCenterConfig centerConfig, GalaxyArmConfig armsConfig) : base(coreConfig, centerConfig)
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

		let maxAngle = armsConfig.Turns * 2.f * PI;
		let sigma = armsConfig.Width * armsConfig.Spread;

		for (let i in 0...armsConfig.NumberOfStars)
		{
			// Distribute the stars evenly between the different arms.
			let armIndex = i % armsConfig.ArmCount;

			// Rotate each arm around the galaxy centre.
			let armOffset = (2.f * PI * armIndex) / armsConfig.ArmCount;

			// Random position along the spiral.
			let randomAngle = (float)GetRandomValue(0, 10000) / 10000.f;
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

			let position = Vector3(x, y, z);
			let color = GREEN;

			stars.Add(.(position, color));
		}
	}
}

class GalaxyRenderer
{
	public void Render(List<Star> stars)
	{
		for (let star in stars)
		{
			DrawSphere(star.Position, 2.f, star.Color);
		}
	}
}

class Program
{
	public static int Main(String[] args)
	{
		InitWindow(1024, 768, scope $"Galaxy Generator");
		SetTargetFPS(60);

		let core = GalaxyCenterConfig(
			1000,
			.Spheric(deviation: 50)
		);

		let center = GalaxyCenterConfig(
			500,
			.Elliptic(
				radii: .(500, 500, 300),
				deviation: .(500, 500, 300),
				flattening: .(1f, 0.5f, 0.2f)
			)
		);

		let ring = GalaxyRingConfig(
			NumberOfStars: 2000,
			Radius: 700,
			Thickness: 300,
			Height: 70,
			RadialSpread: 0.5f
		);

		let arm = GalaxyArmConfig(
			NumberOfStars: 1000,
			ArmCount: 2,
			StartRadius: 120,
			Growth: 0.12f,
			Turns: 2,
			Width: 80,
			Spread: 0.15f,
			Height: 12
		);

		let ringGalaxyGenerator = scope RingGalaxyGenerator(core, center, ring);
		let spiralGalaxyGenerator = scope SpiralGalaxyGenerator(core, center, arm);

		List<Star> ringStars;
		defer { delete ringStars; }

		List<Star> spiralStars;
		defer { delete spiralStars; }

		ringGalaxyGenerator.Generate(out ringStars);
		spiralGalaxyGenerator.Generate(out spiralStars);

		let galaxyRenderer = scope GalaxyRenderer();

		var selectedStars = GalaxyType.Ring(ringStars);

		var camera = Camera3D(
			.(2000,0,2000), // Position
			.(0,0,0), // Target
			.(0,0,1), // Up
			45.0f, // FOV
			CameraProjection.CAMERA_PERSPECTIVE
		);

		while (!WindowShouldClose())
		{
			UpdateCamera(&camera, .CAMERA_ORBITAL);

			if (IsKeyPressed(.KEY_R))
			{
				selectedStars = .Ring(ringStars);
			}
			else if (IsKeyPressed(.KEY_S))
			{
				selectedStars = .Spiral(spiralStars);
			}

			if (IsKeyPressed(.KEY_G))
			{
				DeleteAndNullify!(ringStars);
				DeleteAndNullify!(spiralStars);

				ringGalaxyGenerator.Generate(out ringStars);
				spiralGalaxyGenerator.Generate(out spiralStars);

				if (selectedStars case .Ring)
				{
					selectedStars = .Ring(ringStars);
				}
				else
				{
					selectedStars = .Spiral(spiralStars);
				}
			}

			BeginDrawing();
			ClearBackground(BLACK);

			rlSetClipPlanes(0.1f, 5000.f);
			BeginMode3D(camera);

			var starCount = 0;
			switch (selectedStars)
			{
			case .Ring(let stars):
				galaxyRenderer.Render(stars);
				starCount = stars.Count;
			case .Spiral(let stars):
				galaxyRenderer.Render(stars);
				starCount = stars.Count;
			}

			EndMode3D();

			DrawText(scope $"Stars: {starCount}", 20, 20, 32, RAYWHITE);

			EndDrawing();
		}

		CloseWindow();
		return 0;
	}
}