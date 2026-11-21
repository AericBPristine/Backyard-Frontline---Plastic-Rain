extends Node3D

const SECONDS_VISIBLE := 75.0
const GROUND_PHYSICS_LAYER := 1 << 5

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

	var outward := center - origin
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
