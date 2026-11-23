extends Node3D

const DUST_SHADER := preload("res://art/effects/impact_sprite.gdshader")
const DURATION := 1.10
const TOY_DURATION := 1.55

enum Style { COVER, DIRT, TAN_TOY, GREEN_TOY }

var style := Style.COVER
var normal := Vector3.UP
var plastic_ground_y := 0.0
var plastic_chips := true
var elapsed := 0.0
var puffs: Array[Dictionary] = []
var chips: Array[Dictionary] = []

func _ready() -> void:
	var quad := QuadMesh.new()
	if is_toy_hit():
		add_toy_spray(quad)
		return
	var ground_hit := style == Style.DIRT
	var core := Color("#9d805c") if ground_hit else Color("#aca9a2")
	var edge := Color("#594934") if ground_hit else Color("#666765")
	for index in range(4):
		var drift := normal * randf_range(0.35, 0.76) + scatter() * 0.35
		add_puff(quad, core, edge, drift + Vector3.UP * 0.18,
			randf_range(0.32, 0.54), 0.027 * index, randf_range(0.62, 1.0))

	if ground_hit:
		var soil := BoxMesh.new()
		soil.size = Vector3(0.035, 0.058, 0.040)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#674d31")
		soil.material = material
		for index in range(7):
			var chip := MeshInstance3D.new()
			chip.mesh = soil
			chip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			chip.rotation = scatter() * TAU
			add_child(chip)
			var velocity := Vector3.UP * randf_range(1.4, 2.4) + scatter() * 1.5
			chips.append({"node": chip, "velocity": velocity})

func is_toy_hit() -> bool:
	return style in [Style.TAN_TOY, Style.GREEN_TOY]

func add_toy_spray(quad: QuadMesh) -> void:
	var tan := style == Style.TAN_TOY
	var core := Color("#d4ae7c") if tan else Color("#85aa63")
	var edge := Color("#9a734d") if tan else Color("#37593c")
	var tangent := normal.cross(Vector3.UP).normalized()
	if tangent.is_zero_approx():
		tangent = Vector3.RIGHT
	add_puff(quad, core, edge, normal * 0.20 + Vector3.UP * 0.09, 0.23, 0.0, 0.29)
	for index in range(9):
		var drift := normal * randf_range(0.23, 0.57)
		drift += tangent * randf_range(-0.39, 0.39) + Vector3.UP * randf_range(-0.05, 0.29)
		add_puff(quad, core, edge, drift, randf_range(0.15, 0.29),
			0.012 * index, randf_range(1.08, 1.46))

	if not plastic_chips:
		return

	var plastic := StandardMaterial3D.new()
	plastic.albedo_color = core.lerp(edge, 0.35)
	plastic.roughness = 0.36
	var fragment := PrismMesh.new()
	fragment.left_to_right = 0.26
	fragment.material = plastic
	var fall := maxf(0.0, global_position.y - plastic_ground_y - 0.035)
	for index in range(9):
		var chip := MeshInstance3D.new()
		chip.mesh = fragment
		chip.scale = Vector3(randf_range(0.040, 0.092), randf_range(0.025, 0.065), randf_range(0.015, 0.050))
		chip.rotation = Vector3(randf(), randf(), randf()) * TAU
		chip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(chip)
		var velocity := normal * randf_range(1.1, 3.2) + tangent * randf_range(-1.5, 1.5)
		velocity += Vector3.UP * randf_range(1.4, 2.7)
		var air_time := (velocity.y + sqrt(velocity.y * velocity.y + 19.6 * fall)) / 9.8
		chips.append({"node": chip, "velocity": velocity, "air_time": air_time,
			"spin": Vector3(randf_range(-11.0, 11.0), randf_range(-14.0, 14.0), randf_range(-8.0, 8.0))})

func add_puff(quad: QuadMesh, core: Color, edge: Color, drift: Vector3,
		width: float, delay: float, life: float) -> void:
	var puff := MeshInstance3D.new()
	puff.mesh = quad
	puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = DUST_SHADER
	material.set_shader_parameter("inner_color", core)
	material.set_shader_parameter("outer_color", edge)
	material.set_shader_parameter("variation", randf_range(2.0, 80.0))
	material.set_shader_parameter("opacity", 0.0)
	puff.material_override = material
	add_child(puff)
	puffs.append({"node": puff, "material": material, "drift": drift, "width": width, "delay": delay, "life": life})

func scatter() -> Vector3:
	return Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))

func _process(delta: float) -> void:
	elapsed += delta
	var toy_mist := is_toy_hit()
	if elapsed >= (TOY_DURATION if toy_mist else DURATION):
		queue_free()
		return
	var camera := get_viewport().get_camera_3d()
	for puff in puffs:
		var node: MeshInstance3D = puff.node
		var age: float = elapsed - puff.delay
		var phase: float = age / puff.life
		node.visible = phase > 0.0 and phase < 1.0
		if not node.visible:
			continue
		node.position = puff.drift * (1.0 - exp(-age * (5.8 if toy_mist else 3.0)))
		if camera and node.global_position.distance_squared_to(camera.global_position) > 0.01:
			node.look_at(camera.global_position)
		var width: float = puff.width * lerpf(0.55, 1.55, phase)
		node.scale = Vector3(width, width, 1.0)
		var fade := smoothstep(0.0, 0.10, phase) * (1.0 - smoothstep(0.19, 1.0, phase))
		if toy_mist:
			fade = smoothstep(0.0, 0.045, age) * exp(-age * 1.55) * (1.0 - smoothstep(0.55, 1.0, phase))
		puff.material.set_shader_parameter("opacity", fade * 0.74)
	for chip in chips:
		var node: MeshInstance3D = chip.node
		var time := minf(elapsed, chip.air_time) if toy_mist else elapsed
		node.position = chip.velocity * time + Vector3.DOWN * (4.9 * time * time)
		if toy_mist:
			if elapsed < chip.air_time:
				node.rotation += Vector3(chip.spin) * delta
		else:
			node.visible = node.position.y >= 0
			if node.visible:
				node.rotate_x(delta * 9.0)
