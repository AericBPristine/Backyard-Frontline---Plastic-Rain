extends RefCounted

const RELEASE_SECONDS := 0.18
const READY_AGAIN_SECONDS := 1.20
const ROUND_HALF_LENGTH := 0.25
const PALM_OFFSET := 0.053

var skeleton: Skeleton3D
var held_round: Node3D
var round_size: Vector3
var parts: Dictionary = {}
var arms: Array[Dictionary] = []
var legs: Array[Dictionary] = []
var pelvis: int
var spine: int
var head: int
var pelvis_rest: Transform3D
var spine_rest: Transform3D
var time_since_press := READY_AGAIN_SECONDS

func _init(figure: Node3D, prop: Node3D) -> void:
	held_round = prop
	round_size = prop.scale
	skeleton = figure.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	for mesh in figure.find_children("*", "MeshInstance3D", true, false):
		parts[mesh.name] = mesh
	parts[&"RunStick"].hide()
	pelvis = skeleton.find_bone("pelvis")
	spine = skeleton.find_bone("spine")
	head = skeleton.find_bone("head")
	pelvis_rest = skeleton.get_bone_global_rest(pelvis)
	spine_rest = skeleton.get_bone_global_rest(spine)
	for side in [".L", ".R"]:
		arms.append(limb("upper_arm" + side, "forearm" + side, "hand" + side))
		var leg := limb("thigh" + side, "shin" + side, "foot" + side)
		# Plant one boot forward of the other.
		leg.foot = leg.end_rest.origin + Vector3(0.0, 0.0, 0.15 if side == ".L" else -0.13)
		legs.append(leg)

func limb(upper: String, lower: String, end: String) -> Dictionary:
	var upper_id := skeleton.find_bone(upper)
	var lower_id := skeleton.find_bone(lower)
	var end_id := skeleton.find_bone(end)
	var upper_rest := skeleton.get_bone_global_rest(upper_id)
	var lower_rest := skeleton.get_bone_global_rest(lower_id)
	var end_rest := skeleton.get_bone_global_rest(end_id)
	return {
		"upper": upper_id, "lower": lower_id, "end": end_id,
		"upper_rest": upper_rest, "lower_rest": lower_rest, "end_rest": end_rest,
		"upper_length": upper_rest.origin.distance_to(lower_rest.origin),
		"lower_length": lower_rest.origin.distance_to(end_rest.origin)
	}

func head_position() -> Vector3:
	return skeleton.to_global(skeleton.get_bone_global_pose(head).origin)

func set_first_person_view(active: bool) -> void:
	parts[&"Head"].visible = not active
	parts[&"Torso"].visible = not active
	parts[&"LeftArm"].visible = not active

func reset() -> void:
	time_since_press = READY_AGAIN_SECONDS

func press() -> void:
	time_since_press = 0.0

func pose(delta: float, muzzle: Vector3, tube_direction: Vector3, round_ready := true) -> void:
	time_since_press = minf(time_since_press + delta, READY_AGAIN_SECONDS)
	var time := time_since_press
	var mouth := skeleton.to_local(muzzle)
	var axis := (skeleton.global_basis.inverse() * tube_direction).normalized()
	var withdrawal := smoothstep(0.10, 0.26, time) * (1.0 - smoothstep(0.42, 0.84, time))
	var recovery := smoothstep(0.61, READY_AGAIN_SECONDS, time)
	var reach := clampf(1.0 - smoothstep(RELEASE_SECONDS, 0.36, time) + (recovery if round_ready else 0.0), 0.0, 1.0)
	var drop := smoothstep(0.0, RELEASE_SECONDS, time)
	var held_height := lerpf(ROUND_HALF_LENGTH + 0.07, 0.07, drop * (1.0 - recovery))
	var staged_round := mouth + axis * held_height
	var beside_round := axis.cross(Vector3.BACK).normalized() * 0.047
	var grip_direction := (Vector3.BACK * 0.48 + axis * 0.67).normalized()
	var staged_wrist := staged_round + beside_round - grip_direction * PALM_OFFSET

	var duck_right := (skeleton.global_basis.inverse() * Vector3.RIGHT).normalized()
	var duck_axis := Vector3.UP.cross(duck_right).normalized()
	var lean := -clampf(mouth.x * 0.28, -0.22, 0.22)
	var presenting := Basis.from_euler(Vector3(0.08, -0.09, lean) * reach)
	var shoulder_turn := Basis(duck_axis, 0.33 * withdrawal) * Basis(Vector3.UP, 1.10 * withdrawal) * presenting
	var shift := Vector3(mouth.x * 0.24, 0.0, 0.15) * reach
	shift += (duck_right * 0.14 - Vector3.UP * 0.18) * withdrawal
	var pivot := spine_rest.origin
	var trunk := Transform3D(shoulder_turn, pivot + shift - shoulder_turn * pivot)
	var arm := arms[1]
	var shoulder: Vector3 = trunk * arm.upper_rest.origin
	var shortfall := maxf(0.0, shoulder.distance_to(staged_wrist) - arm.upper_length - arm.lower_length + 0.009)
	shift += shoulder.direction_to(staged_wrist) * minf(shortfall, 0.14) * reach * (1.0 - withdrawal)
	trunk.origin = pivot + shift - shoulder_turn * pivot

	place_hips(shift)
	skeleton.set_bone_global_pose(spine, trunk * spine_rest)
	skeleton.set_bone_pose_rotation(head, Quaternion.from_euler(Vector3(0.15, 0.47, 0.0) * withdrawal))

	for leg in legs:
		var ankle: Vector3 = leg.foot
		var poses := solve_limb(leg, ankle, Vector3.BACK)
		skeleton.set_bone_global_pose(leg.end, Transform3D(leg.end_rest.basis, poses))

	var brace := trunk * Vector3(0.24, 1.10, 0.24) + Vector3(0.0, 0.10, 0.03) * withdrawal
	var left_wrist := solve_limb(arms[0], brace, Vector3(0.85, -0.68, -0.38))
	aim_bone(arms[0].end, arms[0].end_rest.basis, left_wrist, Vector3(-0.42, -0.17, 0.86).normalized(), -0.31)
	var resting_wrist := trunk * Vector3(-0.265, 1.02, 0.20)
	var right_wrist := solve_limb(arm, resting_wrist.lerp(staged_wrist, reach), Vector3(-0.81, -0.90, -0.42))
	var hand_direction := Vector3(-0.08, -0.35, 0.93).normalized().lerp(grip_direction, reach).normalized()
	aim_bone(arm.end, arm.end_rest.basis, right_wrist, hand_direction, 0.52)
	held_round.visible = round_ready and (time < RELEASE_SECONDS or time >= 0.66)
	var resting_round := right_wrist + hand_direction * PALM_OFFSET - beside_round
	held_round.global_position = skeleton.to_global(resting_round.lerp(staged_round, reach))
	held_round.global_basis = Basis(Quaternion(Vector3.UP, tube_direction)) * Basis.from_scale(round_size)

func place_hips(shift: Vector3) -> void:
	var offset := Vector3(shift.x * 0.56, minf(0.0, shift.y), shift.z * 0.56)
	for leg in legs:
		var limit: float = leg.upper_length + leg.lower_length - 0.012
		var from_ankle: Vector3 = leg.upper_rest.origin + offset - leg.foot
		var side := Vector2(from_ankle.x, from_ankle.z).length_squared()
		var available_height := sqrt(maxf(0.0, limit * limit - side))
		offset.y -= maxf(0.0, from_ankle.y - available_height)
	skeleton.set_bone_global_pose(pelvis, Transform3D(pelvis_rest.basis, pelvis_rest.origin + offset))

func solve_limb(part: Dictionary, target: Vector3, preferred_bend: Vector3) -> Vector3:
	var start := skeleton.get_bone_global_pose(part.upper).origin
	var distance := start.distance_to(target)
	var direction := start.direction_to(target) if distance > 0.0001 else Vector3.BACK
	var upper: float = part.upper_length
	var lower: float = part.lower_length
	distance = clampf(distance, absf(upper - lower) + 0.004, upper + lower - 0.002)
	var along := (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
	var bend := (preferred_bend - direction * direction.dot(preferred_bend)).normalized()
	if bend.is_zero_approx():
		bend = direction.cross(Vector3.UP).normalized()
	var joint := start + direction * along + bend * sqrt(maxf(0.0, upper * upper - along * along))
	var end := start + direction * distance
	aim_bone(part.upper, part.upper_rest.basis, start, start.direction_to(joint))
	aim_bone(part.lower, part.lower_rest.basis, joint, joint.direction_to(end))
	return end

func aim_bone(bone: int, rest: Basis, at: Vector3, direction: Vector3, twist := 0.0) -> void:
	var aim := Quaternion(direction, twist) * Quaternion(rest.y.normalized(), direction)
	skeleton.set_bone_global_pose(bone, Transform3D(Basis(aim) * rest, at))