extends Node3D

const PUFF_SHADER := preload("res://art/effects/impact_sprite.gdshader")
const DURATION := 0.98

var camera: Camera3D
var direction := Vector3.UP
var elapsed := 0.0
var sprites: Array[Dictionary] = []
var light: OmniLight3D

func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var across := direction.cross(Vector3.RIGHT).normalized()
	add_puff(quad, direction * 0.17, direction * 4.2, Color.WHITE, Color("#ff942c"), 0.79, 0.0, 0.10, true)
	add_puff(quad, direction * 0.19 + across * 0.11, direction * 3.5, Color("#ffd87d"), Color("#b4461a"), 0.64, 0.022, 0.17)
	add_puff(quad, direction * 0.09 - across * 0.16, direction * 2.65, Color("#ffd597"), Color("#a84724"), 0.57, 0.031, 0.16)
	for index in range(4):
		var offset := float(index) - 1.5
		var drift := direction * (0.22 + index * 0.16) + across * offset * 0.2 + Vector3.UP * 0.40
		add_puff(quad, direction * 0.16 + across * offset * 0.072, drift,
			Color("#8d867a"), Color("#aea495"), 0.65 + index * 0.11, 0.046 + index * 0.035, 0.69 + index * 0.031)
	light = OmniLight3D.new()
	light.position = direction * 0.27
	light.light_color = Color("#ffe0ae")
	light.light_energy = 2.9
	light.omni_range = 3.6
	add_child(light)

func add_puff(quad: QuadMesh, at: Vector3, drift: Vector3, core: Color, edge: Color,
		width: float, delay: float, lifetime: float, white_flash := false) -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = PUFF_SHADER
	material.set_shader_parameter("inner_color", core)
	material.set_shader_parameter("outer_color", edge)
	material.set_shader_parameter("variation", 12.0 + sprites.size() * 7.1)
	material.set_shader_parameter("white_flash", white_flash)
	material.render_priority = 2 if white_flash else 0
	mesh.material_override = material
	mesh.hide()
	add_child(mesh)
	sprites.append({
		"node": mesh, "material": material, "origin": at, "drift": drift, "width": width,
		"delay": delay, "lifetime": lifetime, "flame": lifetime < 0.2, "flash": white_flash
	})

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= DURATION:
		queue_free()
		return
	light.light_energy = maxf(0.0, 1.0 - elapsed / 0.109) * 2.9
	for puff in sprites:
		var age: float = elapsed - puff.delay
		var phase: float = age / puff.lifetime
		var node: MeshInstance3D = puff.node
		node.visible = phase > 0.0 and phase < 1.0
		if not node.visible:
			continue
		node.position = puff.origin + puff.drift * age
		if is_instance_valid(camera) and node.global_position.distance_squared_to(camera.global_position) > 0.01:
			node.look_at(camera.global_position)
			node.rotate_object_local(Vector3.BACK, puff.delay * 18.0 + age * 0.32)
		var size: float = puff.width * (0.64 + phase * 0.77)
		node.scale = Vector3(size, size * (1.20 if puff.flame else 0.91), 1.0)
		var envelope := 1.0 - smoothstep(0.15, 1.0, phase)
		if not puff.flash:
			envelope *= smoothstep(0.0, 0.14, phase)
		if not puff.flame:
			envelope *= 0.60
		puff.material.set_shader_parameter("opacity", envelope)
