extends RefCounted

const RIDGE_STEPS := 112

static func build(world: Node3D, map_center: Vector3, map_size: float, floor_material: ShaderMaterial,
		open_fields := false, practice_field := false) -> void:
	var half := map_size * 0.5
	const OUTER_GROUND := 1450.0
	var skirt_width := OUTER_GROUND - half
	var skirt_mid := (half + OUTER_GROUND) * 0.5
	ground_strip(world, map_center + Vector3(0, 0, -skirt_mid), Vector2(OUTER_GROUND * 2.0, skirt_width), floor_material)
	ground_strip(world, map_center + Vector3(0, 0, skirt_mid), Vector2(OUTER_GROUND * 2.0, skirt_width), floor_material)
	for side in [-1.0, 1.0]:
		ground_strip(world, map_center + Vector3(side * skirt_mid, 0, 0), Vector2(skirt_width, map_size), floor_material)
	var ridge_scale := 0.64 if open_fields else 1.0
	var round_east := not practice_field
	add_ridgeline(world, map_center, Vector3(810, 1090, 1440), 310.0 * ridge_scale, Color("#7d8c94"), Color("#687882"), 50, round_east)
	add_ridgeline(world, map_center, Vector3(540, 740, 1100), 182.0 * ridge_scale, Color("#6c8084"), Color("#506770"), 119, round_east)
	add_ridgeline(world, map_center, Vector3(535, 586, 685), 35.0 * ridge_scale, Color("#71837b"), Color("#556966"), 243, round_east)
	if practice_field:
		return

	var north_trees: Array[Transform3D] = []
	var valley_trees: Array[Transform3D] = []
	var random := RandomNumberGenerator.new()
	random.seed = 13978
	for row in range(1 if open_fields else 4):
		for column in range(0, 79, 3 if open_fields else 1):
			var x := -351.0 + column * 9.0 + random.randf_range(-3.8, 3.8)
			if absf(x + 28.0) < 7.0 or absf(x) < 6.0 or absf(x - 29.0) < 7.0:
				continue
			var z := -half + 4.6 + row * 6.5 + random.randf_range(-2.5, 2.5)
			var height := random.randf_range(8.0, 19.0)
			north_trees.append(pine_transform(map_center + Vector3(x, 0, z), height, random.randf() * TAU))
	for index in range(77 if open_fields else 375):
		var angle := random.randf() * TAU
		var direction := Vector2(cos(angle), sin(angle))
		var map_edge := half / maxf(absf(direction.x), absf(direction.y))
		var distance := map_edge + random.randf_range(8.0, 62.0)
		var at := map_center + Vector3(direction.x * distance, -0.04, direction.y * distance)
		valley_trees.append(pine_transform(at, random.randf_range(8.0, 21.0), random.randf() * TAU))
	add_pines(world, north_trees, Color("#527968"), "North Tree Line")
	add_pines(world, valley_trees, Color("#749b88"), "Far Pines")

static func ground_strip(world: Node3D, center: Vector3, size: Vector2, material: ShaderMaterial) -> void:
	var tile := PlaneMesh.new()
	tile.size = size
	var strip := MeshInstance3D.new()
	strip.mesh = tile
	strip.position = center - Vector3.UP * 0.025
	strip.material_override = material
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(strip)

static func add_ridgeline(world: Node3D, center: Vector3, rings: Vector3,
		height: float, valley: Color, summit: Color, seed: int, round_east: bool) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 0.016
	var coordinates: Array[PackedVector3Array] = []
	var colors: Array[PackedColorArray] = []
	for fraction in [0.0, 0.24, 1.0, 0.44, 0.0]:
		var loop := PackedVector3Array()
		var paint := PackedColorArray()
		for step in range(RIDGE_STEPS):
			var angle := step * TAU / RIDGE_STEPS
			var axis := Vector2(cos(angle), sin(angle))
			var dome := noise.get_noise_2dv(axis * 255.0)
			var folds := noise.get_noise_2dv(axis * 680.0 + Vector2(24, 53))
			var peak := clampf(0.46 + dome * 0.52 + absf(folds) * 0.28, 0.11, 1.0)
			var radial := rings.y + dome * 42.0 + folds * 21.0
			if round_east:
				var east := smoothstep(0.08, 0.50, axis.x)
				var broad := noise.get_noise_2dv(axis * 124.0)
				peak = lerpf(peak, (0.51 + broad * 0.46) * 0.60, east)
				radial = lerpf(radial, rings.y + broad * 42.0, east)
			if coordinates.size() < 2:
				radial = lerpf(rings.x, radial, coordinates.size() * 0.5)
			elif coordinates.size() > 2:
				radial = lerpf(radial, rings.z, (coordinates.size() - 2) * 0.5)
			loop.append(Vector3(axis.x * radial, height * peak * fraction - 0.06, axis.y * radial))
			var shade := clampf(fraction * 0.78 + folds * 0.22, 0.0, 1.0)
			paint.append(valley.lerp(summit, shade))
		coordinates.append(loop)
		colors.append(paint)
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for band in range(coordinates.size() - 1):
		for step in range(RIDGE_STEPS):
			var next := (step + 1) % RIDGE_STEPS
			for sample in [Vector2i(band, step), Vector2i(band + 1, step), Vector2i(band + 1, next),
					Vector2i(band, step), Vector2i(band + 1, next), Vector2i(band, next)]:
				builder.set_color(colors[sample.x][sample.y])
				builder.add_vertex(coordinates[sample.x][sample.y])
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.disable_fog = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	builder.set_material(material)
	var ridge := MeshInstance3D.new()
	ridge.name = "Distant Ridgeline"
	ridge.mesh = builder.commit()
	ridge.position = center
	ridge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(ridge)

static func pine_transform(at: Vector3, height: float, turn: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, turn).scaled(Vector3.ONE * height), at)

static func add_pines(world: Node3D, transforms: Array[Transform3D], color: Color, label: String) -> void:
	var pine := SurfaceTool.new()
	pine.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tier in range(3):
		var bottom := 0.10 + tier * 0.19
		var radius := 0.21 - tier * 0.046
		var crown := 0.58 + tier * 0.21
		for side in range(6):
			var a := side * TAU / 6.0
			var b := (side + 1) * TAU / 6.0
			var shade := color.darkened(0.17 * float(side % 3) / 2.0)
			pine.set_color(shade)
			pine.add_vertex(Vector3(sin(a) * radius, bottom, cos(a) * radius))
			pine.set_color(shade.lightened(0.10))
			pine.add_vertex(Vector3(0, crown, 0))
			pine.set_color(shade)
			pine.add_vertex(Vector3(sin(b) * radius, bottom, cos(b) * radius))
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.disable_fog = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	pine.set_material(material)
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = pine.commit()
	instances.instance_count = transforms.size()
	for index in range(transforms.size()):
		instances.set_instance_transform(index, transforms[index])
	var forest := MultiMeshInstance3D.new()
	forest.name = label
	forest.multimesh = instances
	forest.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(forest)

static func add_valley_boulders(world: Node3D, ground_height: Callable) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 72193
	var clusters: Array[Vector2] = [
		Vector2(-74, -143), Vector2(60, -169), Vector2(-67, -258), Vector2(79, -258),
		Vector2(62, -315), Vector2(-81, -335), Vector2(111, -368), Vector2(-62, -410),
		Vector2(64, -446), Vector2(-166, -476), Vector2(73, -509), Vector2(-60, -537),
		Vector2(86, -573), Vector2(-73, -603), Vector2(67, -641), Vector2(-91, -665),
		Vector2(98, -683), Vector2(-57, -696),
	]
	const VARIANTS := 3
	var batches := [[], [], []]
	for index in range(clusters.size()):
		var cluster := clusters[index]
		var rocks := random.randi_range(2, 4)
		var angle := random.randf() * TAU
		var along := Vector2(cos(angle), sin(angle))
		for stone in range(rocks):
			var offset := along * (stone * 3.7) + Vector2(random.randf_range(-2.4, 2.4), random.randf_range(-2.3, 2.3))
			var at := cluster + offset
			at.x = signf(cluster.x) * maxf(absf(at.x), 54.0)
			var size := random.randf_range(3.1, 6.7) if stone == 0 else random.randf_range(1.7, 3.6)
			var scale := Vector3(size * random.randf_range(1.0, 1.31), size * random.randf_range(0.55, 0.79), size * random.randf_range(0.72, 1.16))
			var basis := Basis(Vector3.UP, angle + random.randf_range(-0.5, 0.5)) * Basis.from_scale(scale)
			var height := float(ground_height.call(at))
			batches[(index + stone) % VARIANTS].append(Transform3D(basis, Vector3(at.x, height + scale.y * 0.06, at.y)))
	for variant in range(VARIANTS):
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = build_boulder(variant)
		instances.instance_count = batches[variant].size()
		for stone in range(instances.instance_count):
			instances.set_instance_transform(stone, batches[variant][stone])
		var scatter := MultiMeshInstance3D.new()
		scatter.name = "Valley Boulders %d" % (variant + 1)
		scatter.multimesh = instances
		world.add_child(scatter)

static func build_boulder(variant: int) -> ArrayMesh:
	var random := RandomNumberGenerator.new()
	random.seed = 21630 + variant
	const FACETS := 8
	var rings: Array[PackedVector3Array] = []
	var row := 0
	for profile in [Vector2(-0.32, 0.30), Vector2(-0.13, 0.55), Vector2(0.15, 0.53), Vector2(0.40, 0.29)]:
		var ring := PackedVector3Array()
		for side in range(FACETS):
			var angle := (side + row * 0.12) * TAU / FACETS + random.randf_range(-0.15, 0.15)
			var radius: float = profile.y * random.randf_range(0.78, 1.14)
			ring.append(Vector3(cos(angle) * radius + row * 0.031, profile.x + random.randf_range(-0.062, 0.062), sin(angle) * radius))
		rings.append(ring)
		row += 1
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for band in range(rings.size() - 1):
		for side in range(FACETS):
			var next := (side + 1) % FACETS
			var a := rings[band][side]
			var b := rings[band][next]
			var c := rings[band + 1][next]
			var d := rings[band + 1][side]
			var outward := Vector3(a.x + b.x, 0.2, a.z + b.z)
			var stone := Color("#596053").lerp(Color("#7d7f6d"), (band + random.randf_range(0.1, 0.7)) / 3.0)
			boulder_face(builder, a, b, c, outward, stone)
			boulder_face(builder, a, c, d, outward, stone.lightened(random.randf_range(-0.05, 0.11)))
	var top := Vector3(0.04, 0.51, -0.04)
	for side in range(FACETS):
		boulder_face(builder, rings.back()[side], rings.back()[(side + 1) % FACETS], top,
			Vector3.UP, Color("#767867").lightened(random.randf_range(-0.09, 0.11)))
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.98
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	builder.set_material(material)
	return builder.commit()

static func boulder_face(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		outward: Vector3, color: Color) -> void:
	var normal := (c - a).cross(b - a).normalized()
	if normal.dot(outward) < 0.0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	for vertex in [a, b, c]:
		builder.set_color(color)
		builder.set_normal(normal)
		builder.add_vertex(vertex)
