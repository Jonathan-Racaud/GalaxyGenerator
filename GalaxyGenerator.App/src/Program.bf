using System;

using RaylibBeef;
using System.Collections;
using static RaylibBeef.Raylib;
using static RaylibBeef.Rlgl;

using GalaxyGenerator.Core;

namespace GalaxyGenerator;

class GalaxyRenderer
{
	public void Render(List<Star> stars)
	{
		for (let star in stars)
		{
			DrawSphere(
				.(star.Position.X, star.Position.Y, star.Position.Z),
				2.f,
				GetColor(star.Color.Hex)
			);
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

		let arm = GalaxyArmsConfig(
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

		List<Star> ringStars = null;
		defer { delete ringStars; }

		List<Star> spiralStars = null;
		defer { delete spiralStars; }

		ringGalaxyGenerator.Generate(out ringStars);
		spiralGalaxyGenerator.Generate(out spiralStars);

		let galaxyRenderer = scope GalaxyRenderer();

		var selectedStars = GalaxyType.Ring(ringStars);

		var camera = Camera3D(
			.(2000,0,500), // Position
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