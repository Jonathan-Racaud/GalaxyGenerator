using System;

using RaylibBeef;
using System.Collections;
using static RaylibBeef.Raylib;
using static RaylibBeef.Rlgl;

using GalaxyGenerator.Core;

namespace GalaxyGenerator.App;

class App
{
	public delegate void() Update ~ delete _;
	public delegate void() Render ~ delete _;
	public function void() UI;

	public Camera3D Camera;

	public this(StringView title)
	{
		InitWindow(1024, 768, title.Ptr);
		SetTargetFPS(60);

		Camera = Camera3D(
			.(2000,0,500), // Position
			.(0,0,0), // Target
			.(0,0,1), // Up
			45.0f, // FOV
			CameraProjection.CAMERA_PERSPECTIVE
		);
	}

	public ~this()
	{
		CloseWindow();
	}

	public void Run()
	{
		while (!WindowShouldClose())
		{
			Update();

			BeginDrawing();
			ClearBackground(BLACK);
			BeginMode3D(Camera);
			rlSetClipPlanes(0.1f, 5000.f);

			Render();

			EndMode3D();

			UI();
			EndDrawing();
		}
	}
}

static
{
	public static void ShowUI()
	{
		DrawText("Inputs:", 20, 20, 32, RAYWHITE);
		DrawText("	R: Generate a ring galaxy", 40, 60, 32, RAYWHITE);
		DrawText("	S: Generate a spiral galaxy", 40, 100, 32, RAYWHITE);
		DrawText(scope $"Stars: {Program.Stars?.Count ?? 0}", 20, 160, 32, RAYWHITE);
	}
}

class Program
{
	public static List<Star> Stars = null ~ delete _;

	public static int Main(String[] args)
	{
		let app = scope App("Galaxy Generator");

		app.Update = new () => {
			UpdateCamera(&app.Camera, .CAMERA_ORBITAL);

			if (IsKeyPressed(.KEY_R))
			{
				Generate(.Ring);
			}
			else if (IsKeyPressed(.KEY_S))
			{
				Generate(.Spiral);
			}
		};

		app.Render = new => Render;

		app.UI = => ShowUI;

		app.Run();

		return 0;
	}

	protected static void Generate(GalaxyType type)
	{
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
			NumberOfStars: 1000,
			Radius: 700,
			Thickness: 200,
			Height: 80,
			RadialSpread: 20f
		);

		let arm = GalaxyArmsConfig(
			NumberOfStars: 1000,
			ArmCount: 2,
			StartRadius: 120,
			Growth: 0.3f,
			Turns: 2,
			Width: 100,
			Spread: 0.15f,
			Height: 12
		);

		GalaxyGenerator generator;

		switch (type)
		{
		case .Ring:
			generator = new RingGalaxyGenerator(core, center, ring);
		case .Spiral:
			generator = new SpiralGalaxyGenerator(core, center, arm);
		}
		defer { delete generator; }

		SafeDeleteAndNullify!(Stars);

		generator.Generate(out Stars);
	}

	protected static void Render()
	{
		if (Stars == null)
		{
			return;
		}

		for (let star in Stars)
		{
			DrawSphere(
				.(star.Position.X, star.Position.Y, star.Position.Z),
				2.f,
				GetColor(star.Color.Hex)
			);
		}
	}

	protected static mixin SafeDeleteAndNullify(var container)
	{
		if (container != null)
		{
			delete container;
			container = null;
		}
	}
}