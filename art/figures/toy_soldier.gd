extends Node3D

enum Pose { STANDING, KNEELING, UNARMED }
enum Reaction { NONE, DODGE, PRONE, COVER }
enum HitRegion { LIMB, LOWER_TORSO, UPPER_TORSO, HEAD }

const MODELS := preload("res://art/figures/toy_soldier_poses.glb")
const RUNNER := preload("res://art/figures/toy_soldier_run.glb")
const RIFLE := preload("res://art/figures/m16_player_prop.glb")
const TAN_RIFLE := preload("res://art/figures/m16_tan_prop.glb")
const SNIPER_RIFLE := preload("res://art/figures/m40_player_prop.glb")
const SNIPER_RIFLE_FIT := Vector3(0.0, 0.038, -0.079)
const MODEL_NAMES := ["Standing", "Kneeling", "Unarmed"]

static var tan_materials: Dictionary = {}
static var sniper_finishes: Dictionary = {}

var poses: Array[Node3D] = []
var pose := -1
var is_tan := false
var is_sniper := false
var runner: Node3D
var run_player: AnimationPlayer
var run_skeleton: Skeleton3D
var run_head_bone := -1
var chest_bone := -1
var carry_bone := -1
var hips_bone := -1
var grip_arms: Array[Vector3i] = []
var leg_bones: Array[int] = []
var run_rifle: Node3D
var rifle_offset: Transform3D
var run_parts: Dictionary = {}
var run_phase := 0.0
var reaction := Reaction.NONE
var reaction_left := 0.0
var reaction_duration := 0.0
var reaction_cooldown := 0.0
var reaction_goal := Vector3.ZERO
var reaction_prone := 0.0

func setup(tan: bool, stance: Pose, marksman := false) -> void:
	is_tan = tan
	is_sniper = marksman
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
	var asset := RIFLE
	if is_sniper:
		asset = SNIPER_RIFLE
	elif is_tan:
		asset = TAN_RIFLE
	var prop := asset.instantiate() as Node3D
	prop.name = "Rifle"
	if is_sniper:
		pose_transform = pose_transform.translated_local(SNIPER_RIFLE_FIT)
		paint_sniper_rifle(prop)
	prop.transform = pose_transform
	parent.add_child(prop)
	return prop

func equip_rifle(marksman: bool) -> void:
	if is_sniper == marksman:
		return
	var old_fit := SNIPER_RIFLE_FIT if is_sniper else Vector3.ZERO
	is_sniper = marksman
	for sculpture in poses:
		var rifle := sculpture.get_node_or_null("Rifle") as Node3D
		if rifle:
			replace_rifle(rifle, rifle.transform.translated_local(-old_fit))
	if runner:
		run_rifle = replace_rifle(run_rifle, rifle_offset.translated_local(-old_fit))
		rifle_offset = run_rifle.transform

func replace_rifle(rifle: Node3D, mount: Transform3D) -> Node3D:
	var host := rifle.get_parent() as Node3D
	rifle.free()
	return mount_rifle(host, mount)

func paint_sniper_rifle(rifle: Node3D) -> void:
	var shell := rifle as MeshInstance3D
	if not shell:
		shell = rifle.find_child("M40", true, false) as MeshInstance3D
	if not sniper_finishes.has(is_tan):
		var exterior := shell.mesh.surface_get_material(0) as StandardMaterial3D
		var torso := poses[Pose.STANDING].get_node("Standing_Torso") as MeshInstance3D
		var plastic := torso.get_active_material(0).duplicate() as StandardMaterial3D
		plastic.resource_name = "Tan M40" if is_tan else "Green M40"
		plastic.normal_enabled = exterior.normal_enabled
		plastic.normal_texture = exterior.normal_texture
		plastic.normal_scale = exterior.normal_scale
		sniper_finishes[is_tan] = plastic
	shell.material_override = sniper_finishes[is_tan]

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
	run_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	run_skeleton = runner.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	run_head_bone = run_skeleton.find_bone("head")
	chest_bone = run_skeleton.find_bone("chest")
	hips_bone = run_skeleton.find_bone("pelvis")
	carry_bone = run_skeleton.find_bone("carry_prop")
	for side in [".L", ".R"]:
		grip_arms.append(Vector3i(
			run_skeleton.find_bone("upper_arm" + side),
			run_skeleton.find_bone("forearm" + side),
			run_skeleton.find_bone("hand" + side)
		))
		for limb in ["thigh", "shin", "foot"]:
			leg_bones.append(run_skeleton.find_bone(limb + side))
	var missing: String = get_meta("missing_arm", "")
	for part in runner.find_children("*", "MeshInstance3D", true, false):
		run_parts[String(part.name)] = part
		if part.name != &"RunStick" and is_tan:
			tint_tan(part)
		if part.name == missing:
			part.hide()
	run_parts["RunStick"].hide()
	var rest := run_skeleton.get_bone_global_rest(carry_bone)
	var rifle_rest := Transform3D(Basis.looking_at(rest.basis.y, Vector3.UP, true), rest.origin)
	run_rifle = mount_rifle(run_skeleton, rest.affine_inverse() * rifle_rest)
	rifle_offset = run_rifle.transform

func run_step(travel: float, armed: bool, flinch := 0.0) -> void:
	show_runner(armed)
	var stride := 1.58 if armed else 2.04
	run_phase = fposmod(run_phase + travel / stride, 1.0)
	run_skeleton.reset_bone_poses()
	run_player.seek(run_player.current_animation_length * run_phase, true)
	if armed:
		if flinch > 0.0:
			var chest := run_skeleton.get_bone_global_pose(chest_bone)
			chest.origin.y -= flinch * 0.035
			chest.basis = Basis.from_euler(Vector3(0.18, 0.0, 0.09) * flinch) * chest.basis
			run_skeleton.set_bone_global_pose(chest_bone, chest)
		var swing := sin(run_phase * TAU)
		var hold := run_skeleton.get_bone_global_pose(carry_bone)
		var tilt := Basis.from_euler(Vector3(0.28 + absf(swing) * 0.06, swing * 0.20, 0.04 * swing))
		move_grip(Transform3D(tilt * hold.basis, hold.origin + Vector3(swing * 0.055, -0.10, 0.065)))

func show_runner(armed: bool) -> void:
	if not runner:
		prepare_runner()
	poses[pose].hide()
	runner.show()
	var clip := &"ArmedRun" if armed else &"UnarmedRun"
	if run_player.current_animation != clip:
		run_rifle.visible = armed
		run_player.play(clip, 0.0, 0.0)

func rifle_pose(raised: float, prone := 0.0, kick := 0.0) -> void:
	show_runner(true)
	run_skeleton.reset_bone_poses()
	run_player.seek(0.0, true)
	for bone in leg_bones:
		run_skeleton.reset_bone_pose(bone)
	var hips := run_skeleton.get_bone_global_pose(hips_bone)
	# Rotate the same skinned figure so hits and ragdolls use the visible pose.
	var lowered := Basis(Vector3.RIGHT, prone * 1.42)
	run_skeleton.set_bone_global_pose(hips_bone, Transform3D(
		lowered * hips.basis,
		Vector3(0.0, lerpf(0.914, 0.255, prone), lerpf(-0.018, -0.34, prone))
	))
	var hold := run_skeleton.get_bone_global_pose(carry_bone)
	var level := Basis.looking_at(Vector3.FORWARD, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5)
	var upright := hold.origin + Vector3(-0.015, lerpf(-0.10, 0.25, raised), 0.08 - kick * 0.04)
	var low := Vector3(-0.10, 0.28, hold.origin.z + 0.14)
	var turn := Basis.from_euler(Vector3(lerpf(0.30, -0.03, raised) - kick * 0.13, 0.0, 0.04))
	move_grip(Transform3D(turn * level, upright.lerp(low, prone)))
	var head := run_skeleton.get_bone_global_pose(run_head_bone)
	head.basis = Basis(Vector3.RIGHT, 0.14 * raised - 1.22 * prone) * head.basis \
		* Basis(Vector3.FORWARD, raised * -0.14)
	run_skeleton.set_bone_global_pose(run_head_bone, head)

func move_grip(desired: Transform3D) -> void:
	var grip := run_skeleton.get_bone_global_pose(carry_bone)
	var change := desired * grip.affine_inverse()
	for arm in grip_arms:
		var shoulder := run_skeleton.get_bone_global_pose(arm.x)
		var elbow := run_skeleton.get_bone_global_pose(arm.y)
		var wrist := run_skeleton.get_bone_global_pose(arm.z)
		var upper := shoulder.origin.distance_to(elbow.origin)
		var lower := elbow.origin.distance_to(wrist.origin)
		var wanted := change * wrist
		var reach := wanted.origin - shoulder.origin
		if reach.is_zero_approx():
			continue
		var axis := reach.normalized()
		var distance := clampf(reach.length(), absf(upper - lower) + 0.001, upper + lower - 0.001)
		var bend := (elbow.origin - shoulder.origin).slide(axis).normalized()
		var offset := (upper * upper + distance * distance - lower * lower) / (2.0 * distance)
		var joint := shoulder.origin + axis * offset + bend * sqrt(maxf(0.0, upper * upper - offset * offset))
		wanted.origin = shoulder.origin + axis * distance
		shoulder.basis = Basis(Quaternion(shoulder.basis.y.normalized(), shoulder.origin.direction_to(joint))) * shoulder.basis
		run_skeleton.set_bone_global_pose(arm.x, shoulder)
		elbow.origin = joint
		elbow.basis = Basis(Quaternion(elbow.basis.y.normalized(), joint.direction_to(wanted.origin))) * elbow.basis
		run_skeleton.set_bone_global_pose(arm.y, elbow)
		run_skeleton.set_bone_global_pose(arm.z, wanted)
	run_rifle.transform = desired * rifle_offset

func muzzle_position() -> Vector3:
	if runner and runner.visible and run_rifle.visible:
		run_skeleton.force_update_all_bone_transforms()
		return run_rifle.to_global(Vector3(0.0, 0.0, 0.65))
	var sculpture := poses[pose]
	var muzzle := sculpture.get_node_or_null(String(sculpture.name) + "_Muzzle") as Node3D
	return muzzle.global_position if muzzle else global_position

func head_bounds() -> AABB:
	if runner and runner.visible:
		var part: MeshInstance3D = run_parts["Head"]
		var rest := run_skeleton.get_bone_global_rest(run_head_bone)
		var pose_transform := run_skeleton.get_bone_global_pose(run_head_bone)
		var skeleton_transform := run_skeleton.global_transform
		var skin_offset := skeleton_transform * pose_transform * rest.affine_inverse() * skeleton_transform.affine_inverse()
		return (skin_offset * part.global_transform) * part.get_aabb()
	var sculpture := poses[pose]
	var head := sculpture.get_node(String(sculpture.name) + "_Head") as MeshInstance3D
	return head.global_transform * head.get_aabb()

func trace_shot(from: Vector3, to: Vector3) -> Dictionary:
	var bounds := AABB(global_position + Vector3(-1.22, -0.15, -1.22), Vector3(2.44, 2.15, 2.44))
	if bounds.intersects_segment(from, to) == null:
		return {}
	var running := is_instance_valid(runner) and runner.visible
	var parts: Array = run_parts.values() if running else poses[pose].get_children()
	if running:
		run_skeleton.force_update_all_bone_transforms()
	var hit: Dictionary = {}
	var end := to
	for part in parts:
		if not part is MeshInstance3D or not part.visible:
			continue
		var mesh_part := part as MeshInstance3D
		var is_head := String(mesh_part.name).ends_with("Head")
		if running and is_head and head_bounds().grow(0.03).intersects_segment(from, end) == null:
			continue
		var inverse := mesh_part.global_transform.affine_inverse()
		var start_local := inverse * from
		var end_local := inverse * end
		var mesh := mesh_part.bake_mesh_from_current_skeleton_pose() if running else mesh_part.mesh
		if not mesh or mesh.get_aabb().intersects_segment(start_local, end_local) == null:
			continue
		var triangles := mesh.generate_triangle_mesh()
		if not triangles:
			continue
		var contact := triangles.intersect_segment(start_local, end_local)
		if not contact.is_empty():
			end = mesh_part.global_transform * Vector3(contact.position)
			var region := HitRegion.HEAD if is_head else HitRegion.LIMB
			if String(mesh_part.name).ends_with("Torso"):
				var torso_up := Vector3.UP
				if running:
					var pelvis := run_skeleton.get_bone_global_pose(hips_bone).origin
					var head := run_skeleton.get_bone_global_pose(run_head_bone).origin
					torso_up = inverse.basis * run_skeleton.global_basis * (head - pelvis).normalized()
				var offset := Vector3(contact.position) - mesh.get_aabb().get_center()
				region = HitRegion.UPPER_TORSO if offset.dot(torso_up) >= 0.0 else HitRegion.LOWER_TORSO
			hit = {"point": end, "helmet_pop": is_head, "region": region}
	return hit

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
