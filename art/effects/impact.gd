extends Node3D

const SPRITE := preload("res://art/effects/impact_sprite.gdshader")
const EFFECT_SECONDS := 10.0

var camera: Camera3D
var airburst := false
var fragment_spread := 0.0
var floor_height: Callable
var fragment_marks: Array[Dictionary] = []
var random := RandomNumberGenerator.new()
var sprites: Array[Dictionary] = []
var debris: Array[Dictionary] = []
var streaks: Array[Dictionary] = []
var light: OmniLight3D
var elapsed := 0.0

func _ready() -> void:
	random.randomize()
	light = OmniLight3D.new()
	light.position.y = 0.55
	light.light_color = Color("#ffd078")
	light.light_energy = 3.2
	light.omni_range = 10.0
	add_child(light)

	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	add_cloud(quad, Vector3.UP * 0.46, Vector3.UP * 0.84, Color.WHITE, Color("#ff9e27"), 4.25, 0.125, 0.0, 1.0, 0.83, &"flash")
	for index in range(6):
		var angle := random.randf() * TAU
		var axis := Vector3(cos(angle), 0, sin(angle))
		var origin := axis * random.randf_range(0.25, 1.4) + Vector3.UP * 0.55
		var drift := axis * random.randf_range(0.8, 2.25) + Vector3.UP * random.randf_range(2.6, 5.5)
		add_cloud(quad, origin, drift, Color("#ffae35"), Color("#9f230f"),
			random.randf_range(2.5, 3.8), random.randf_range(0.30, 0.48), 0.052 + index * 0.009, 0.99)
	for index in range(3):
		var origin := Vector3((index - 1) * 0.54, 0.70 + index * 0.18, random.randf_range(-0.24, 0.15))
		var drift := Vector3(random.randf_range(-1.3, 1.3), random.randf_range(2.7, 4.8), random.randf_range(-0.8, 0.8))
		add_cloud(quad, origin, drift, Color("#171617"), Color("#4c3028"),
			random.randf_range(1.35, 1.8), 0.66, 0.072 + index * 0.014, 0.92, 1.42, &"soot")

	for index in range(11):
		var angle := index * TAU / 11.0 + random.randf_range(-0.3, 0.3)
		var axis := Vector3(cos(angle), 0, sin(angle))
		var drift := axis * random.randf_range(0.6, 2.4) + Vector3.UP * random.randf_range(3.4, 6.8)
		add_cloud(quad, axis * random.randf_range(0.2, 1.1) + Vector3.UP * 0.5, drift,
			Color("#221f1e"), Color("#62564c"), random.randf_range(2.2, 4.4),
			random.randf_range(1.32, 2.08), random.randf_range(0.09, 0.23), random.randf_range(0.65, 0.91))
	for index in range(4):
		var offset := Vector3((index - 1.5) * 0.36, 1.44 + (index % 2) * 0.40, 0)
		var drift := Vector3((index - 1.5) * 1.45, random.randf_range(5.8, 8.0), random.randf_range(-1.2, 0.85))
		add_cloud(quad, offset, drift, Color("#161519"), Color("#48413b"),
			random.randf_range(1.55, 2.2), random.randf_range(0.89, 1.12), 0.054 + index * 0.021, 0.92, 1.82, &"soot")
	for index in range(0 if airburst else 9):
		var angle := index * TAU / 9.0
		var axis := Vector3(cos(angle), 0, sin(angle))
		var drift := axis * random.randf_range(3.1, 4.8) + Vector3.UP * random.randf_range(0.55, 1.55)
		add_cloud(quad, axis * 0.8 + Vector3.UP * 0.25, drift, Color("#786244"), Color("#a99373"),
			random.randf_range(1.7, 3.1), random.randf_range(0.96, 1.65), random.randf_range(0.016, 0.062), 0.82, 1.0, &"dust")
	for index in range(7):
		var angle := index * TAU / 7.0
		var start := Vector3(cos(angle), 0, sin(angle)) * random.randf_range(0.2, 1.4)
		start.y = random.randf_range(1.0, 3.3)
		var drift := Vector3(random.randf_range(-0.26, 0.30), random.randf_range(0.42, 0.74), random.randf_range(-0.22, 0.28))
		var delay := 0.48 + index * 0.16
		add_cloud(quad, start, drift, Color("#3c3734"), Color("#77716a"),
			random.randf_range(3.2, 4.8), EFFECT_SECONDS - delay, delay, random.randf_range(0.3, 0.54), 1.24, &"linger")

	if airburst:
		add_airburst_marks(quad)
		return

	var chunk := SphereMesh.new()
	chunk.radius = 0.062
	chunk.height = 0.146
	chunk.radial_segments = 5
	chunk.rings = 3
	var soil := StandardMaterial3D.new()
	soil.albedo_color = Color("#3e3628")
	soil.roughness = 1.0
	for index in range(24):
		var chip := MeshInstance3D.new()
		chip.mesh = chunk
		chip.material_override = soil
		chip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		chip.rotation = Vector3(random.randf(), random.randf(), random.randf()) * TAU
		chip.scale = Vector3(random.randf_range(0.55, 1.1), random.randf_range(0.6, 1.45), random.randf_range(0.45, 1.15))
		add_child(chip)
		var angle := random.randf() * TAU
		var reach := random.randf_range(1.2, 5.2)
		var velocity := Vector3(cos(angle) * reach, random.randf_range(5.5, 12.2), sin(angle) * reach)
		debris.append({"node": chip, "velocity": velocity})
	add_streaks()

func add_airburst_marks(quad: QuadMesh) -> void:
	var glint := CylinderMesh.new()
	glint.top_radius = 0.057
	glint.bottom_radius = 0.012
	glint.height = 1.0
	glint.radial_segments = 4
	var ember := StandardMaterial3D.new()
	ember.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember.albedo_color = Color("#ffc57f")
	const STREAKS := 72
	for index in range(STREAKS):
		var angle := (index + random.randf_range(-0.95, 0.95)) * TAU / STREAKS
		var axis := Vector3(cos(angle), 0.0, sin(angle))
		var strike := axis * fragment_spread * random.randf_range(0.26, 0.96)
		strike.y = float(floor_height.call(Vector2(position.x + strike.x, position.z + strike.z))) - position.y + 0.12
		var skip := strike + axis * random.randf_range(1.0, 3.0)
		skip.y = float(floor_height.call(Vector2(position.x + skip.x, position.z + skip.z))) - position.y + 0.10
		var arrival := random.randf_range(0.27, 0.53)
		var chip := MeshInstance3D.new()
		chip.mesh = glint
		chip.material_override = ember
		chip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		chip.hide()
		add_child(chip)
		fragment_marks.append({"node": chip, "strike": strike, "skip": skip, "arrival": arrival})
		if index % 4 == 0:
			add_cloud(quad, strike + Vector3.UP * 0.2, axis * 1.05 + Vector3.UP * 2.8,
				Color("#ac9472"), Color("#71614c"), random.randf_range(1.75, 3.0), 1.15, arrival, 0.88, 1.75, &"dust")
		if index % 12 == 0:
			add_cloud(quad, skip + Vector3.UP * 0.18, axis * 1.2 + Vector3.UP * 1.8,
				Color("#9b805f"), Color("#6f604d"), 1.15, 0.75, arrival + 0.22, 0.72, 1.25, &"dust")

func update_airburst_marks() -> void:
	for mark in fragment_marks:
		var node: MeshInstance3D = mark.node
		var strike: Vector3 = mark.strike
		var skip: Vector3 = mark.skip
		var arrival: float = mark.arrival
		node.visible = elapsed > 0.07 and elapsed < arrival + 0.22
		if not node.visible:
			continue
		if elapsed < arrival:
			var flight := smoothstep(0.04, arrival, elapsed)
			node.position = strike * flight
			node.quaternion = Quaternion(Vector3.UP, strike.normalized())
			node.scale.y = 1.5
		else:
			var hop := (elapsed - arrival) / 0.22
			node.position = strike.lerp(skip, hop) + Vector3.UP * sin(hop * PI) * 0.62
			node.quaternion = Quaternion(Vector3.UP, (skip - strike + Vector3.UP * cos(hop * PI)).normalized())
			node.scale.y = lerpf(0.72, 0.16, hop)

func add_cloud(plane: QuadMesh, origin: Vector3, drift: Vector3, inner: Color, outer: Color, size: float,
		life: float, delay: float, strength: float, stretch := 1.0, style: StringName = &"burst") -> void:
	var cloud := MeshInstance3D.new()
	cloud.mesh = plane
	cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = SPRITE
	material.set_shader_parameter("inner_color", inner)
	material.set_shader_parameter("outer_color", outer)
	material.set_shader_parameter("variation", random.randf_range(2, 80))
	material.set_shader_parameter("white_flash", style == &"flash")
	if style == &"flash":
		material.render_priority = 2
	elif style == &"soot":
		material.render_priority = 1
	cloud.material_override = material
	cloud.visible = false
	add_child(cloud)
	var rotation := random.randf_range(-0.29, 0.29) if stretch > 1.0 else random.randf() * TAU
	sprites.append({
		"node": cloud, "material": material, "origin": origin, "drift": drift, "size": size,
		"life": life, "delay": delay, "strength": strength, "angle": rotation, "stretch": stretch, "style": style
	})

func add_streaks() -> void:
	var glint := CylinderMesh.new()
	glint.top_radius = 0.027
	glint.bottom_radius = 0.004
	glint.height = 1.0
	glint.radial_segments = 4
	for index in range(12):
		var streak := MeshInstance3D.new()
		streak.mesh = glint
		streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		streak.hide()
		var ember := StandardMaterial3D.new()
		ember.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ember.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var color := Color("#ffe2a0").lerp(Color("#f4934a"), random.randf() * 0.75)
		ember.albedo_color = color
		streak.material_override = ember
		add_child(streak)
		var angle := index * TAU / 12.0 + random.randf_range(-0.28, 0.26)
		var outward := random.randf_range(4.7, 9.8)
		var speed := Vector3(cos(angle) * outward, random.randf_range(4.9, 10.7), sin(angle) * outward)
		streaks.append({
			"node": streak, "material": ember, "color": color, "velocity": speed,
			"delay": random.randf_range(0.01, 0.07), "life": random.randf_range(0.16, 0.35)
		})

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= EFFECT_SECONDS:
		queue_free()
		return
	light.light_energy = maxf(0.0, 1.0 - elapsed / 0.14) * 3.2
	if airburst:
		update_airburst_marks()
	for cloud in sprites:
		var age: float = elapsed - cloud.delay
		var phase: float = age / cloud.life
		var sprite: MeshInstance3D = cloud.node
		sprite.visible = phase > 0.0 and phase < 1.0
		if not sprite.visible:
			continue
		var drift: Vector3 = cloud.drift
		var displacement := drift * (age / (1.0 + 0.48 * age))
		if cloud.style == &"linger":
			displacement.y = drift.y * age
		sprite.position = cloud.origin + displacement
		if is_instance_valid(camera) and sprite.global_position.distance_squared_to(camera.global_position) > 0.01:
			sprite.look_at(camera.global_position)
			sprite.rotate_object_local(Vector3.BACK, cloud.angle + age * 0.19)
		sprite.scale = Vector3(1.0, cloud.stretch, 1.0) * cloud.size * (0.52 + phase * 0.68)
		var envelope := smoothstep(0.0, 0.14, phase) * (1.0 - smoothstep(0.22, 1.0, phase))
		if cloud.style == &"flash":
			envelope = 1.0 - smoothstep(0.16, 0.92, phase)
		elif cloud.style == &"soot":
			envelope = smoothstep(0.0, 0.085, phase) * (1.0 - smoothstep(0.53, 1.0, phase))
		elif cloud.style == &"dust":
			envelope = smoothstep(0.0, 0.034, phase) * (1.0 - smoothstep(0.18, 1.0, phase))
		elif cloud.style == &"linger":
			envelope = smoothstep(0.0, 0.20, phase) * (1.0 - smoothstep(0.30, 1.0, phase))
		cloud.material.set_shader_parameter("opacity", envelope * cloud.strength)

	for chip in debris:
		var node: MeshInstance3D = chip.node
		var toss: Vector3 = chip.velocity
		node.position = Vector3.UP * 0.18 + toss * elapsed - Vector3.UP * 7.5 * elapsed * elapsed
		node.visible = node.position.y > 0.0
		if node.visible:
			node.rotation += Vector3(3.2, 5.1, 1.1) * delta

	for streak in streaks:
		var age: float = elapsed - streak.delay
		var phase: float = age / streak.life
		var node: MeshInstance3D = streak.node
		node.visible = phase > 0.0 and phase < 1.0
		if not node.visible:
			continue
		var velocity: Vector3 = streak.velocity
		node.position = Vector3.UP * 0.38 + velocity * age - Vector3.UP * 6.5 * age * age
		var heading := (velocity - Vector3.UP * 13.0 * age).normalized()
		node.quaternion = Quaternion(Vector3.UP, heading)
		node.scale.y = lerpf(0.66, 0.17, phase)
		var color: Color = streak.color
		color.a = 1.0 - smoothstep(0.25, 1.0, phase)
		streak.material.albedo_color = color

