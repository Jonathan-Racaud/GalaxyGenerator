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

struct Star: this(Vector3 Position, Color Color);

enum GaussianGenerator
{
	case Elliptic(Vector3 radii, Vector3 deviation, Vector3 flattening);
	case Spheric(float deviation);
}

class RingGalaxyGenerator
{
	public int StarCount { get => stars?.Count ?? 0; };

	List<Star> stars = new .() ~ delete _;

	public void Generate(GalaxyCenterConfig coreConfig, GalaxyCenterConfig centerConfig, params GalaxyRingConfig[] ringsConfig)
	{
		stars.Clear();
		GenerateCenter(coreConfig);
		GenerateCenter(centerConfig);
		GenerateRings(ringsConfig);
	}

	private void GenerateCenter(GalaxyCenterConfig config)
	{
		for (let i in 0...config.NumberOfStars)
		{
			switch (config.Generator)
			{
			case .Elliptic(let radii, let deviation, let flattening):
				GenerateEllipticalDistribution(radii, deviation, flattening);
			case .Spheric(let deviation):
				GenerateSphericalDistribution(deviation);
			default:
				break;
			}
		}
	}

	/*private void GenerateSphereCenter(radius)
	{
		// NOTE: this can maybe used to place points that act as moon around a planet which would be their center.
		let r = (float)GetRandomValue(0, (int32)radius * 100) / 100.f;
		var theta = (float)GetRandomValue(0, 18000) / 100.f;
		var phi = (float)GetRandomValue(0, 36000) / 100.f;

		theta *= DEG2RAD;
		phi *= DEG2RAD;

		stars.Add(
			.(
				r * Math.Sin(theta) * Math.Cos(phi),
				r * Math.Sin(theta) * Math.Sin(phi),
				r * Math.Cos(theta)
			)
		);
	}*/

	private void GenerateSphericalDistribution(float deviation)
	{
		let position = Vector3(
			deviation * GenerateGaussian(),
			deviation * GenerateGaussian(),
			deviation * GenerateGaussian()
		);
		let color = WHITE;


		stars.Add(.(position, color));
	}

	private void GenerateEllipticalDistribution(Vector3 radii, Vector3 deviation, Vector3 flattening)
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

	private void GenerateRings(GalaxyRingConfig[] config)
	{
		for (let ring in config)
		{
			for (let i in 0...ring.NumberOfStars)
			{
				let theta = (float)GetRandomValue(0, 360) * DEG2RAD;
				let r = GenerateGaussianRadius(ring.Radius, ring.Thickness, ring.RadialSpread);

				let radialOffset = Math.Abs(r - ring.Radius);
				let normalizedOffset = radialOffset / (ring.Thickness / 2.f);

				let heightFactor = 1.f - normalizedOffset;
				let maxHeight = ring.Height * heightFactor;

				let h = (float)GetRandomValue(
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

	private float GenerateGaussian()
	{
		let u1 = (float)GetRandomValue(1, 10000) / 10000.f;
		let u2 = (float)GetRandomValue(0, 10000) / 10000.f;
	
		return Math.Sqrt(-2.f * Math.Log(u1)) * Math.Cos(2.f * PI * u2);
	}	

	private float GenerateGaussianRadius(float radius, float thickness, float radialSpread)
	{
		let innerRadius = radius - (thickness / 2);
		let outerRadius = radius + (thickness / 2);

		while (true)
		{
			let u1 = (float)GetRandomValue(1, 10000) / 10000.f;
			let u2 = (float)GetRandomValue(0, 10000) / 10000.f;

			let z = Math.Sqrt(-2.f * Math.Log(u1)) * Math.Cos(2.f * PI * u2);
			let sigma = thickness * radialSpread;
			let r = radius + sigma * z;

			if (r >= innerRadius && r <= outerRadius)
			{
				return r;
			}
		}
	}

	public void Render()
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
		DisableCursor();
		SetTargetFPS(60);

		let generator = scope RingGalaxyGenerator();
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

		generator.Generate(
			core,
			center,
			ring
		);

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

			BeginDrawing();
			ClearBackground(BLACK);

			rlSetClipPlanes(0.1f, 5000.f);
			BeginMode3D(camera);

			generator.Render();

			EndMode3D();

			DrawText(scope $"Stars: {generator.StarCount}", 20, 20, 32, RAYWHITE);

			EndDrawing();
		}

		CloseWindow();
		return 0;
	}
}