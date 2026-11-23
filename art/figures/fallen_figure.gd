extends Node3D

const SECONDS_VISIBLE := 75.0
const GROUND_PHYSICS_LAYER := 1 << 5
const HELMET_SURFACE := 1
const SOLDIER := preload("res://art/figures/toy_soldier.gd")

var random := RandomNumberGenerator.new()

func drop(figure: Node3D, origin: Vector3, scatter_count: int) -> void:
	random.randomize()
	var source: Node3D = figure.copy_pieces()
	add_child(source)
	var parts: Array[MeshInstance3D] = []
	var limbs: Array[MeshInstance3D] = []
	for child in source.get_children():
		if child is MeshInstance3D:
			parts.append(child)
			if String(child.name).begins_with("Left") or String(child.name).begins_with("Right"):
				limbs.append(child)
	limbs.shuffle()
	if scatter_count >= parts.size():
		var whole: Array[MeshInstance3D] = parts.duplicate()
		for piece in whole:
			drop_group([piece], figure.global_transform, origin, true, scatter_count)
	else:
		for index in range(mini(scatter_count, limbs.size())):
			var piece := limbs[index]
			parts.erase(piece)
			drop_group([piece], figure.global_transform, origin, true, scatter_count)
		if not parts.is_empty():
			drop_group(parts, figure.global_transform, origin, false, scatter_count)
	source.queue_free()
	start_cleanup()

func drop_limp(figure: Node3D, travel: Vector3, pop_helmet: bool) -> void:
	random.randomize()
	var source: Node3D = figure.copy_pieces()
	add_child(source)
	var pose := figure.global_transform
	var torso_mesh := source.get_node_or_null("Torso") as MeshInstance3D
	if not torso_mesh:
		source.queue_free()
		start_cleanup()
		return
	var torso_bounds := torso_mesh.transform * torso_mesh.get_aabb()
	var drift := Vector3(travel.x, 0.0, travel.z).normalized() * 0.72
	drift += pose.basis.x * random.randf_range(-0.28, 0.28)
	var tip := Vector3.UP.cross(drift)
	var running: bool = figure.runner and figure.runner.visible
	if running or figure.pose == SOLDIER.Pose.KNEELING:
		# A split stance needs a sideways tip to fall over the planted foot or knee.
		var side := 1.0 if drift.dot(pose.basis.x) >= 0.0 else -1.0
		drift += pose.basis.x * side * (0.92 if running else 0.65)
		tip = Vector3.UP.cross(pose.basis.x * side) * (2.3 if running else 1.9)
	var torso := make_body([torso_mesh], pose)
	torso.name = "Torso"
	torso.mass = 3.6
	torso.linear_velocity = drift + Vector3.DOWN * 0.55
	torso.angular_velocity = tip * 3.0
	for part in source.get_children():
		if not part is MeshInstance3D:
			continue
		var part_name := String(part.name)
		var bounds: AABB = part.transform * part.get_aabb()
		if part_name == "Head" and pop_helmet:
			launch_helmet(part, pose, drift)
		var limb := make_body([part], pose)
		limb.name = part_name
		limb.linear_velocity = drift
		limb.angular_velocity = tip
		var anchor := torso_bounds.get_center()
		var swing := 46.0
		if part_name == "Head":
			anchor = bounds.get_center()
			anchor.y = bounds.position.y + 0.025
			limb.mass = 0.55
			swing = 25.0
		elif part_name.ends_with("Arm"):
			anchor.x = -0.22 if part_name.begins_with("Left") else 0.22
			anchor.y = torso_bounds.end.y - 0.18
			limb.mass = 0.74
			swing = 62.0
		else:
			anchor.x = -0.11 if part_name.begins_with("Left") else 0.11
			anchor.y = torso_bounds.position.y + 0.045
			limb.mass = 1.25
		var joint := ConeTwistJoint3D.new()
		joint.name = part_name + " Joint"
		add_child(joint)
		var pivot := pose * anchor
		var axis := (limb.global_position - pivot).normalized()
		joint.global_transform = Transform3D(Basis(Quaternion(Vector3.RIGHT, axis)), pivot)
		joint.swing_span = deg_to_rad(swing)
		joint.twist_span = deg_to_rad(swing * 0.55)
		joint.node_a = joint.get_path_to(torso)
		joint.node_b = joint.get_path_to(limb)
	source.queue_free()
	start_cleanup()

func launch_helmet(head: MeshInstance3D, pose: Transform3D, drift: Vector3) -> void:
	if head.mesh.get_surface_count() <= HELMET_SURFACE:
		return
	var helmet := MeshInstance3D.new()
	helmet.mesh = copy_head_surface(head, HELMET_SURFACE)
	helmet.transform = head.transform
	head.get_parent().add_child(helmet)
	head.mesh = copy_head_surface(head, 0)
	var rigid := make_body([helmet], pose)
	rigid.name = "Loose Helmet"
	rigid.mass = 0.25
	rigid.linear_velocity = drift * 1.85 + pose.basis.x * random.randf_range(0.35, 0.80) + Vector3.UP * 2.5
	rigid.angular_velocity = Vector3(5.5, random.randf_range(-5.0, 5.0), -7.0)

func copy_head_surface(head: MeshInstance3D, index: int) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := head.mesh.surface_get_arrays(index)
	arrays[Mesh.ARRAY_BONES] = null
	arrays[Mesh.ARRAY_WEIGHTS] = null
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, head.get_active_material(index))
	return mesh

func knock_off_arm(figure: Node3D, origin: Vector3) -> bool:
	random.randomize()
	var arm := "LeftArm" if random.randf() < 0.5 else "RightArm"
	var source: Node3D = figure.copy_pieces(arm)
	if source.get_child_count() == 0:
		source.free()
		return false
	add_child(source)
	var selected := source.get_child(0) as MeshInstance3D
	figure.remove_arm(arm)
	drop_group([selected], figure.global_transform, origin, true, 1)
	source.queue_free()
	start_cleanup()
	return true

func start_cleanup() -> void:
	var timer := Timer.new()
	timer.wait_time = SECONDS_VISIBLE
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(queue_free)
	timer.start()

func drop_group(parts: Array[MeshInstance3D], pose: Transform3D, origin: Vector3, loose: bool,
		strength: int) -> void:
	var rigid := make_body(parts, pose)
	var outward := rigid.global_position - origin
	outward.y = 0
	outward = (outward.normalized() + Vector3(random.randf_range(-0.6, 0.6), 0, random.randf_range(-0.6, 0.6))).normalized()
	var shove := (2.4 + strength * 0.44) * random.randf_range(0.5, 1.2) if loose else 0.75 + strength * 0.18
	var lift := random.randf_range(1.9, 3.9) + strength * 0.35 if loose else 0.65 + strength * 0.21
	rigid.linear_velocity = outward * shove + Vector3.UP * lift
	rigid.angular_velocity = Vector3(
		random.randf_range(2.8, 7.5),
		random.randf_range(-4.5, 4.5),
		random.randf_range(-5.0, 5.0)
	) * (1.0 if loose else 0.52)

func make_body(parts: Array[MeshInstance3D], pose: Transform3D) -> RigidBody3D:
	var bounds := parts[0].transform * parts[0].get_aabb()
	for part in parts:
		bounds = bounds.merge(part.transform * part.get_aabb())
	var center := pose * bounds.get_center()
	var rigid := RigidBody3D.new()
	rigid.collision_layer = 0
	rigid.collision_mask = GROUND_PHYSICS_LAYER
	rigid.continuous_cd = true
	rigid.linear_damp = 0.55
	rigid.angular_damp = 0.85
	var plastic := PhysicsMaterial.new()
	plastic.bounce = 0.25
	plastic.friction = 0.84
	rigid.physics_material_override = plastic
	add_child(rigid)
	rigid.global_transform = Transform3D(pose.basis.orthonormalized(), center)
	var in_body := rigid.global_transform.affine_inverse() * pose
	for part in parts:
		var fitted := in_body * part.transform
		part.reparent(rigid, false)
		part.transform = fitted
	var fitted_bounds := in_body * bounds
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = fitted_bounds.size.max(Vector3.ONE * 0.07)
	collider.shape = shape
	collider.position = fitted_bounds.get_center()
	rigid.add_child(collider)
	return rigid
