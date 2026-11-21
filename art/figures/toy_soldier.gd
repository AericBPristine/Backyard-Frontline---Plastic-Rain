extends Node3D

enum Pose { STANDING, KNEELING, UNARMED }

const MODELS := preload("res://art/figures/toy_soldier_poses.glb")
const RUNNER := preload("res://art/figures/toy_soldier_run.glb")
const RIFLE := preload("res://art/figures/m16_player_prop.glb")
const MODEL_NAMES := ["Standing", "Kneeling", "Unarmed"]

static var tan_materials: Dictionary = {}

var poses: Array[Node3D] = []
var pose := -1
var is_tan := false
var runner: Node3D
var run_player: AnimationPlayer
var run_skeleton: Skeleton3D
var run_rifle: Node3D
var run_parts: Dictionary = {}
var run_phase := 0.0

func setup(tan: bool, stance: Pose) -> void:
	is_tan = tan
	run_phase = float(get_instance_id() % 13) / 13.0
	var model := MODELS.instantiate() as Node3D
	# Match the local forward direction used by the battlefield units.
	model.rotation.y = PI
	add_child(model)
	for label in MODEL_NAMES:
		var sculpture := model.get_node(label) as Node3D
		poses.append(sculpture)
		sculpture.hide()
		if tan:
			for child in sculpture.get_children():
				if child is MeshInstance3D and not String(child.name).ends_with("_Stick"):
					tint_tan(child)
		var old_prop := sculpture.get_node_or_null(label + "_Stick") as Node3D
		if old_prop:
			old_prop.hide()
			var muzzle := sculpture.get_node(label + "_Muzzle") as Node3D
			var axis := Vector3(0.0, 0.021, 0.65).normalized()
			mount_rifle(sculpture, Transform3D(Basis.looking_at(axis, Vector3.UP, true), muzzle.position - axis * 0.65))
	set_pose(stance)

func mount_rifle(parent: Node3D, pose_transform: Transform3D) -> Node3D:
	var prop := RIFLE.instantiate() as Node3D
	prop.name = "Rifle"
	prop.transform = pose_transform
	parent.add_child(prop)
	return prop

func tint_tan(part: MeshInstance3D) -> void:
	for index in range(part.mesh.get_surface_count()):
		var molded := part.mesh.surface_get_material(index) as StandardMaterial3D
		if molded == null:
			continue
		if not tan_materials.has(molded):
			var tan := molded.duplicate() as StandardMaterial3D
			var shade := clampf(molded.albedo_color.get_luminance() / 0.30, 0.74, 1.0)
			tan.albedo_color = Color("#a88965").darkened((1.0 - shade) * 0.6)
			tan.roughness = maxf(tan.roughness, 0.41)
			tan_materials[molded] = tan
		part.set_surface_override_material(index, tan_materials[molded])

func set_pose(stance: Pose) -> void:
	if pose == stance and not (runner and runner.visible):
		return
	if runner:
		runner.hide()
	if pose >= 0 and pose != stance:
		poses[pose].hide()
	pose = stance
	poses[pose].show()

func prepare_runner() -> void:
	runner = RUNNER.instantiate() as Node3D
	runner.rotation.y = PI
	add_child(runner)
	run_player = runner.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	run_skeleton = runner.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var missing: String = get_meta("missing_arm", "")
	for part in runner.find_children("*", "MeshInstance3D", true, false):
		run_parts[String(part.name)] = part
		if part.name != &"RunStick" and is_tan:
			tint_tan(part)
		if part.name == missing:
			part.hide()
	run_parts["RunStick"].hide()
	var grip := BoneAttachment3D.new()
	grip.bone_name = "carry_prop"
	run_skeleton.add_child(grip)
	var rest := run_skeleton.get_bone_global_rest(grip.bone_idx)
	var rifle_rest := Transform3D(Basis.looking_at(rest.basis.y, Vector3.UP, true), rest.origin)
	run_rifle = mount_rifle(grip, rest.affine_inverse() * rifle_rest)

func run_step(travel: float, armed: bool) -> void:
	if not runner:
		prepare_runner()
	poses[pose].hide()
	runner.show()
	var clip := &"ArmedRun" if armed else &"UnarmedRun"
	if run_player.current_animation != clip:
		run_rifle.visible = armed
		run_player.play(clip, 0.0, 0.0)
	var stride := 1.58 if armed else 2.04
	run_phase = fposmod(run_phase + travel / stride, 1.0)
	run_player.seek(run_player.current_animation_length * run_phase, true)

func muzzle_position() -> Vector3:
	var sculpture := poses[pose]
	var muzzle := sculpture.get_node_or_null(String(sculpture.name) + "_Muzzle") as Node3D
	return muzzle.global_position if muzzle else global_position

func remove_arm(arm: String) -> void:
	set_meta("missing_arm", arm)
	for sculpture in poses:
		var part := sculpture.get_node(String(sculpture.name) + "_" + arm) as MeshInstance3D
		part.hide()
	if run_parts.has(arm):
		run_parts[arm].hide()

func copy_pieces(only_arm := "") -> Node3D:
	if runner and runner.visible:
		return copy_running_pieces(only_arm)
	var source := Node3D.new()
	var sculpture := poses[pose]
	var prefix := String(sculpture.name) + "_"
	for item in sculpture.get_children():
		if item.name == &"Rifle" or not item is MeshInstance3D or not item.visible:
			continue
		var part := String(item.name).trim_prefix(prefix)
		if part == "Stick" or (not only_arm.is_empty() and part != only_arm):
			continue
		var piece := item.duplicate() as MeshInstance3D
		piece.transform = global_transform.affine_inverse() * item.global_transform
		piece.name = part
		source.add_child(piece)
	return source

func copy_running_pieces(only_arm: String) -> Node3D:
	var source := Node3D.new()
	run_skeleton.force_update_all_bone_transforms()
	for name in run_parts:
		var part: MeshInstance3D = run_parts[name]
		if name == "RunStick" or not part.visible or (not only_arm.is_empty() and name != only_arm):
			continue
		var piece := MeshInstance3D.new()
		piece.name = name
		piece.mesh = part.bake_mesh_from_current_skeleton_pose()
		piece.transform = global_transform.affine_inverse() * part.global_transform
		if piece.mesh:
			for surface in range(piece.mesh.get_surface_count()):
				piece.set_surface_override_material(surface, part.get_surface_override_material(surface))
			source.add_child(piece)
		else:
			piece.free()
	return source
