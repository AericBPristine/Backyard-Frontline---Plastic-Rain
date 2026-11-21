extends RefCounted

const SIDES := 12
const NEEDLES := [Color("#203b2c"), Color("#294532"), Color("#2b4d33"), Color("#22402d")]
const TIER_BOTTOMS := [0.19, 0.29, 0.40, 0.51, 0.62, 0.74]
const TIER_WIDTHS := [0.219, 0.197, 0.167, 0.139, 0.108, 0.082]

static func build(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 36901 + variant
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.95
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	surface.set_material(material)

	var bark := Color("#574631")
	for side in range(7):
		var a := radial(side * TAU / 7.0, 0.033, 0.0)
		var b := radial((side + 1) * TAU / 7.0, 0.033, 0.0)
		var c := Vector3(b.x * 0.38, 0.61, b.z * 0.38)
		var d := Vector3(a.x * 0.38, 0.61, a.z * 0.38)
		var outside := Vector3(a.x + b.x, 0, a.z + b.z)
		var shade := bark.darkened(rng.randf_range(0.0, 0.25))
		face(surface, a, b, c, outside, shade)
		face(surface, a, c, d, outside, shade)

	var tint: Color = NEEDLES[variant % NEEDLES.size()]
	var width_scale := rng.randf_range(0.82, 1.14)
	for tier in range(TIER_BOTTOMS.size()):
		var base: float = TIER_BOTTOMS[tier]
		var width: float = TIER_WIDTHS[tier] * width_scale
		var rotation := rng.randf_range(0, TAU)
		var lean := Vector3(rng.randf_range(-0.022, 0.022), 0, rng.randf_range(-0.022, 0.022))
		var shoulder := PackedVector3Array()
		var tips := PackedVector3Array()
		var tip_top := lean + Vector3.UP * (base + 0.26)
		var tip_bottom := lean + Vector3.UP * (base - 0.024)
		for side in range(SIDES):
			var angle := rotation + side * TAU / SIDES + rng.randf_range(-0.07, 0.07)
			var spread := rng.randf_range(0.73, 1.12)
			var branch := spread * (1.0 if side % 2 == 0 else 0.74)
			tips.append(lean + radial(angle, width * branch, base + rng.randf_range(-0.034, 0.019)))
			shoulder.append(lean + radial(angle, width * spread * 0.52, base + rng.randf_range(0.08, 0.13)))
		for side in range(SIDES):
			var next := (side + 1) % SIDES
			var outward := (tips[side] + tips[next]) * 0.5 - lean - Vector3.UP * base
			var color := tint.lightened(rng.randf_range(-0.12, 0.12) + tier * 0.018)
			face(surface, tips[side], tips[next], shoulder[next], outward, color.darkened(0.08))
			face(surface, tips[side], shoulder[next], shoulder[side], outward, color)
			face(surface, shoulder[side], shoulder[next], tip_top, outward, color.lightened(0.08))
			face(surface, tips[side], tip_bottom, tips[next], Vector3.DOWN, color.darkened(0.33))
	return surface.commit()

static func radial(angle: float, radius: float, height: float) -> Vector3:
	return Vector3(cos(angle) * radius, height, sin(angle) * radius)

static func face(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3, color: Color) -> void:
	var normal := (c - a).cross(b - a).normalized()
	if normal.dot(outward) < 0.0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	surface.set_color(color)
	surface.set_normal(normal)
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)

