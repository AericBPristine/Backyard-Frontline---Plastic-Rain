extends CanvasLayer

var stage: SubViewport
var camera: Camera3D
var rig: Node3D
var model: Node3D
var step_phase := 0.0
var sway := 0.0
var iron_sights := false
var iron_front := Vector3.ZERO
var iron_basis := Basis.IDENTITY
const WALK_SWAY_RATE := 2.85
const BASE_FOV := 64.0

func _ready() -> void:
	layer = 0
	var display := SubViewportContainer.new()
	display.stretch = true
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(display)
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	stage = SubViewport.new()
	stage.transparent_bg = true
	stage.own_world_3d = true
	stage.handle_input_locally = false
	stage.render_target_update_mode = SubViewport.UPDATE_DISABLED
	display.add_child(stage)

	camera = Camera3D.new()
	camera.fov = BASE_FOV
	camera.near = 0.035
	stage.add_child(camera)

	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("#d3d8d4")
	environment.environment.ambient_light_energy = 0.73
	stage.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-37.0, -32.0, 0.0)
	key.light_color = Color("#dce3eb")
	key.light_energy = 0.75
	stage.add_child(key)

	rig = Node3D.new()
	stage.add_child(rig)
	hide()

func equip(standing: Node3D, use_iron_sights := false) -> void:
	clear()
	model = Node3D.new()
	model.rotation.y = PI
	model.position.y = -1.44
	rig.add_child(model)
	var rifle := standing.get_node("Rifle").duplicate() as Node3D
	model.add_child(rifle)
	iron_sights = use_iron_sights
	if iron_sights:
		var sleeve := standing.get_node("Standing_LeftArm") as MeshInstance3D
		add_m16_forearms(rifle, sleeve.get_active_material(0))
		# Line up the first-person artwork using two points on the toy prop.
		var rear := Vector3(0.0, 0.054095, 0.100831)
		iron_front = rig.to_local(rifle.to_global(Vector3(0.0, 0.054227, 0.501642)))
		var rear_point := rig.to_local(rifle.to_global(rear))
		iron_basis = Basis(Quaternion(rear_point.direction_to(iron_front), Vector3.FORWARD))
	else:
		for piece_name in [&"Standing_LeftArm", &"Standing_RightArm"]:
			model.add_child(standing.get_node(NodePath(piece_name)).duplicate())
	step_phase = 0.0
	sway = 0.0
	pose(0.0, 0.0, 0.0, 0.0)

func set_view(offset: Basis) -> void:
	camera.basis = offset

func add_m16_forearms(rifle: Node3D, plastic: Material) -> void:
	var right_wrist := Vector3(0.040, -0.111, 0.056)
	var left_wrist := Vector3(-0.047, -0.098, 0.374)
	toy_forearm(rifle, Vector3(0.175, -0.243, 0.043), right_wrist, 0.038, plastic)
	toy_forearm(rifle, Vector3(-0.156, -0.222, 0.095), left_wrist, 0.037, plastic)
	toy_forearm(rifle, right_wrist, Vector3(0.011, -0.087, 0.100), 0.030, plastic)
	toy_forearm(rifle, left_wrist, Vector3(-0.021, -0.040, 0.414), 0.028, plastic)

func toy_forearm(parent: Node3D, from: Vector3, to: Vector3, radius: float, plastic: Material) -> void:
	var part := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = from.distance_to(to) + radius
	capsule.radial_segments = 9
	capsule.rings = 4
	capsule.material = plastic
	part.mesh = capsule
	part.position = from.lerp(to, 0.5)
	part.basis = Basis(Quaternion(Vector3.UP, from.direction_to(to)))
	parent.add_child(part)

func clear() -> void:
	if is_instance_valid(model):
		model.queue_free()
		model = null
	set_active(false)

func set_active(active: bool) -> void:
	if visible == active:
		return
	visible = active
	stage.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE if active else SubViewport.UPDATE_DISABLED

func pose(delta: float, travel: float, kick: float, cycle: float, raised := 0.0) -> void:
	if not is_instance_valid(model):
		return
	if travel > 0.0:
		step_phase = fposmod(step_phase + travel * WALK_SWAY_RATE, TAU)
	sway = move_toward(sway, 1.0 if travel > 0.0 else 0.0, delta * 6.0)
	var step := sin(step_phase) * sway * (1.0 - raised)
	var carry_position := Vector3(0.20 + step * 0.022 + cycle * 0.024,
		-0.09 - sway * 0.048 - absf(step) * 0.010 - cycle * 0.052, -0.18 + kick * 0.10)
	var carry_rotation := Vector3(-0.12 - sway * 0.078 + kick * 0.15 - cycle * 0.15,
		0.09 - step * 0.043 - cycle * 0.13, 0.035 + step * 0.025 + cycle * 0.12)
	if iron_sights:
		var aimed := Basis(Vector3.RIGHT, kick * 0.12) * iron_basis
		var target := Vector3(0.0, -0.002, -0.510 + kick * 0.08) - aimed * iron_front
		rig.position = carry_position.lerp(target, raised)
		rig.basis = Basis.from_euler(carry_rotation).slerp(aimed, raised)
	else:
		rig.position = carry_position.lerp(Vector3(0.07, 0.09, -0.18 + kick * 0.10), raised)
		rig.rotation = carry_rotation.lerp(Vector3(kick * 0.15 - cycle * 0.15,
			0.09 - cycle * 0.13, 0.035 + cycle * 0.12), raised)
