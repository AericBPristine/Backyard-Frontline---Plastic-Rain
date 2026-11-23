extends RefCounted

# Fictional toy-round tuning, in game-space units.
const LAUNCH_SPEED := 700.0
const SLOWDOWN := 0.27
const DOWNWARD_PULL := 13.5
const TRACER_LEAD := 0.35
const CYCLE_SECONDS := 0.88
const KICK_SECONDS := 0.27
const FADE_AFTER := 4.5
const NPC_TRACER_SPEED := 900.0
# At higher speeds, keep stray rounds inside the original gameplay travel distance.
const NPC_TRACER_LIFE := 179.2 / NPC_TRACER_SPEED
const MAX_NPC_TRACERS := 48
const FLYBY_RADIUS_SQUARED := 5.0 * 5.0
const M16_RECOVERY := 0.23
const M16_CAPACITY := 30
const M40_CAPACITY := 5
const M16_RELOAD_SECONDS := 3.0
const M40_RELOAD_SECONDS := 5.0
const LOADOUT := preload("res://art/figures/player_loadout.gd")
const TERRAIN_LAYER := preload("res://art/figures/fallen_figure.gd").GROUND_PHYSICS_LAYER

enum Surface { DIRT, COVER }
enum Action { READY, SPENT, CYCLING }
enum RoundKind { PLAYER, GREEN, TAN, PLAYER_M16 }

var rounds: Array[Dictionary] = []
var cover: Array[Dictionary] = []
var action := Action.READY
var cycle_left := 0.0
var kick_left := 0.0
var m16_recovery_left := 0.0
var m16_ammo := M16_CAPACITY
var m40_ammo := M40_CAPACITY
var reload_weapon := LOADOUT.Item.EMPTY
var reload_left := 0.0
var tracer: CylinderMesh

func reset(world: Node3D, stations: Array[Vector2], ground: Callable) -> void:
	clear()
	cover.clear()
	for child in world.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			add_cover(child)
	for child in world.get_node("Map Props").find_children("*", "MeshInstance3D", true, false):
		if not String(child.name).ends_with("Tower"):
			add_cover(child)
	for station in stations:
		var height: float = ground.call(station)
		var bounds := AABB(Vector3(station.x - 4.75, height, station.y - 0.19), Vector3(9.5, 0.54, 0.38))
		cover.append({"bounds": bounds, "impact_material": &"sandbag"})

func add_cover(model: MeshInstance3D) -> void:
	var impact_material: StringName = model.get_meta("impact_material", &"")
	var face_ranges := PackedInt32Array()
	var face_materials: Array[StringName] = []
	var face_count := 0
	if impact_material.is_empty():
		var mesh := model.mesh as ArrayMesh
		if mesh == null:
			impact_material = material_impact(model.get_active_material(0))
		else:
			for surface in range(mesh.get_surface_count()):
				var count := mesh.surface_get_array_index_len(surface)
				if count == 0:
					count = mesh.surface_get_array_len(surface)
				match mesh.surface_get_primitive_type(surface):
					Mesh.PRIMITIVE_TRIANGLES:
						face_count += floori(count / 3.0)
					Mesh.PRIMITIVE_TRIANGLE_STRIP:
						face_count += maxi(0, count - 2)
					_:
						continue
				face_ranges.append(face_count)
				face_materials.append(material_impact(model.get_active_material(surface)))
	cover.append({
		"bounds": model.global_transform * model.get_aabb(),
		"model": model,
		"world_to_local": model.global_transform.affine_inverse(),
		"impact_material": impact_material,
		"face_ranges": face_ranges,
		"face_materials": face_materials
	})

static func material_impact(material: Material) -> StringName:
	if not material:
		return &""
	var label := material.resource_name.to_lower()
	if "sandbag" in label or "canvas" in label:
		return &"sandbag"
	if ("concrete" in label or "masonry" in label or "brick" in label
			or "limestone" in label or "stucco" in label):
		return &"concrete"
	if ("timber" in label or "wood" in label or "boards" in label or "siding" in label
			or "shutters" in label or "door paint" in label or "brown door" in label):
		return &"wood"
	return &""

static func cover_impact(solid: Dictionary, face_index: int) -> StringName:
	var impact_material: StringName = solid.impact_material
	if not impact_material.is_empty():
		return impact_material
	var ranges: PackedInt32Array = solid.face_ranges
	for index in range(ranges.size()):
		if face_index < ranges[index]:
			return solid.face_materials[index]
	return &""

func clear() -> void:
	for shot in rounds:
		shot.visual.queue_free()
	rounds.clear()
	action = Action.READY
	cycle_left = 0.0
	kick_left = 0.0
	m16_recovery_left = 0.0
	m16_ammo = M16_CAPACITY
	m40_ammo = M40_CAPACITY
	cancel_reload()

func magazine_size(weapon: LOADOUT.Item) -> int:
	match weapon:
		LOADOUT.Item.M16: return M16_CAPACITY
		LOADOUT.Item.M40: return M40_CAPACITY
	return 0

func magazine_rounds(weapon: LOADOUT.Item) -> int:
	match weapon:
		LOADOUT.Item.M16: return m16_ammo
		LOADOUT.Item.M40: return m40_ammo
	return 0

func reload_duration(weapon: LOADOUT.Item) -> float:
	return M16_RELOAD_SECONDS if weapon == LOADOUT.Item.M16 else M40_RELOAD_SECONDS

func start_reload(weapon: LOADOUT.Item) -> bool:
	if reload_left > 0.0 or magazine_rounds(weapon) >= magazine_size(weapon):
		return false
	if weapon == LOADOUT.Item.M40 and action == Action.CYCLING:
		return false
	reload_weapon = weapon
	reload_left = reload_duration(weapon)
	return true

func cancel_reload() -> void:
	reload_weapon = LOADOUT.Item.EMPTY
	reload_left = 0.0

static func is_player_round(kind: RoundKind) -> bool:
	return kind == RoundKind.PLAYER or kind == RoundKind.PLAYER_M16

func start_cycle() -> void:
	if action == Action.SPENT:
		action = Action.CYCLING
		cycle_left = CYCLE_SECONDS

func animate(delta: float) -> void:
	m16_recovery_left = maxf(0.0, m16_recovery_left - delta)
	kick_left = maxf(0.0, kick_left - delta)
	if action == Action.CYCLING:
		cycle_left = maxf(0.0, cycle_left - delta)
		if cycle_left == 0.0:
			action = Action.READY
	if reload_left > 0.0:
		reload_left = maxf(0.0, reload_left - delta)
		if reload_left == 0.0:
			if reload_weapon == LOADOUT.Item.M16:
				m16_ammo = M16_CAPACITY
			else:
				m40_ammo = M40_CAPACITY
				action = Action.READY
			cancel_reload()

func sight_offsets(spacing: float, count: int) -> PackedFloat32Array:
	# Replay the toy tracer on level ground to line up the scope art.
	var offsets := PackedFloat32Array()
	var step := 1.0 / Engine.physics_ticks_per_second
	var point := Vector3.FORWARD * TRACER_LEAD
	var velocity := Vector3.FORWARD * LAUNCH_SPEED
	for frame in range(ceili(FADE_AFTER / step)):
		var next_velocity := advance_velocity(velocity, step)
		var next := advance_position(point, velocity, next_velocity, step)
		while offsets.size() < count:
			var distance := spacing * float(offsets.size() + 1)
			if -next.z < distance:
				break
			var sample := point.lerp(next, inverse_lerp(-point.z, -next.z, distance))
			offsets.append(atan2(-sample.y, -sample.z))
		if offsets.size() == count:
			break
		point = next
		velocity = next_velocity
	return offsets

func advance_velocity(velocity: Vector3, delta: float, slowdown := SLOWDOWN) -> Vector3:
	return velocity * exp(-slowdown * delta) + Vector3.DOWN * DOWNWARD_PULL * delta

func advance_position(point: Vector3, velocity: Vector3, next_velocity: Vector3, delta: float) -> Vector3:
	return point + (velocity + next_velocity) * (delta * 0.5)

func fire(parent: Node3D, origin: Vector3, forward: Vector3) -> bool:
	if action != Action.READY or m40_ammo <= 0 or reload_left > 0.0:
		return false
	m40_ammo -= 1
	spawn_round(parent, origin, forward, RoundKind.PLAYER)
	action = Action.SPENT
	kick_left = KICK_SECONDS
	return true

func fire_m16(parent: Node3D, origin: Vector3, forward: Vector3) -> bool:
	if m16_recovery_left > 0.0 or m16_ammo <= 0 or reload_left > 0.0:
		return false
	m16_ammo -= 1
	spawn_round(parent, origin, forward, RoundKind.PLAYER_M16)
	m16_recovery_left = M16_RECOVERY
	kick_left = KICK_SECONDS * 0.65
	return true

func fire_npc(parent: Node3D, origin: Vector3, forward: Vector3, tan: bool) -> void:
	if rounds.size() < MAX_NPC_TRACERS:
		spawn_round(parent, origin, forward, RoundKind.TAN if tan else RoundKind.GREEN)

func spawn_round(parent: Node3D, origin: Vector3, forward: Vector3, kind: RoundKind) -> void:
	if not tracer:
		tracer = CylinderMesh.new()
		tracer.top_radius = 0.029
		tracer.bottom_radius = 0.029
		tracer.height = 1.32
		tracer.radial_segments = 5
		tracer.rings = 0
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color("#f5d990")
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		tracer.material = glow
	var visual := MeshInstance3D.new()
	visual.name = "Toy Rifle Tracer" if is_player_round(kind) else "AI Toy Tracer"
	visual.mesh = tracer
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)
	visual.position = origin
	visual.basis = Basis(Quaternion(Vector3.UP, forward))
	var speed := LAUNCH_SPEED if kind == RoundKind.PLAYER else NPC_TRACER_SPEED
	rounds.append({"visual": visual, "point": origin, "velocity": forward * speed, "age": 0.0, "kind": kind})

func advance(delta: float, space: PhysicsDirectSpaceState3D, greens: Array[Node3D], tans: Array[Node3D],
		shooter: Node3D, on_travel: Callable, listener := Vector3.INF) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var all_units := greens + tans
	for index in range(rounds.size() - 1, -1, -1):
		var shot := rounds[index]
		var kind: RoundKind = shot.kind
		var player_round := is_player_round(kind)
		var marksman_round := kind == RoundKind.PLAYER
		var from: Vector3 = shot.point
		var velocity: Vector3 = shot.velocity
		var travel_time := delta if marksman_round else minf(delta, NPC_TRACER_LIFE - float(shot.age))
		var slowdown := SLOWDOWN if marksman_round else 0.0
		var next_velocity := advance_velocity(velocity, travel_time, slowdown)
		shot.velocity = next_velocity
		var to := advance_position(from, velocity, next_velocity, travel_time)
		var targets := all_units if marksman_round else (greens if kind == RoundKind.TAN else tans)
		var hit := trace(from, to, space, targets, shooter if player_round else null)
		if kind != RoundKind.TAN:
			on_travel.call(from, to if hit.is_empty() else Vector3(hit.point))
		if not hit.is_empty():
			hit.kind = kind
			results.append(hit)
			shot.visual.queue_free()
			rounds.remove_at(index)
			continue
		if not player_round and listener.is_finite():
			record_flyby(shot, from, to, listener)
		shot.age += delta
		if shot.age >= (FADE_AFTER if marksman_round else NPC_TRACER_LIFE):
			if shot.has("flyby_point"):
				results.append({"point": shot.flyby_point, "flyby": true})
			shot.visual.queue_free()
			rounds.remove_at(index)
			continue
		shot.point = to
		var visual: MeshInstance3D = shot.visual
		visual.position = to
		visual.basis = Basis(Quaternion(Vector3.UP, Vector3(shot.velocity).normalized()))
	return results

static func record_flyby(shot: Dictionary, from: Vector3, to: Vector3, listener: Vector3) -> void:
	var travel := to - from
	var projection := (listener - from).dot(travel)
	# Only consider rounds that cross the listener's plane during this step.
	if projection <= 0.0 or projection > travel.length_squared():
		return
	var closest := from + travel * (projection / travel.length_squared())
	var distance := closest.distance_squared_to(listener)
	if distance < float(shot.get("flyby_distance", FLYBY_RADIUS_SQUARED)):
		shot.flyby_point = closest
		shot.flyby_distance = distance

func trace(from: Vector3, to: Vector3, space: PhysicsDirectSpaceState3D,
		units: Array[Node3D], shooter: Node3D) -> Dictionary:
	var direction := (to - from).normalized()
	var terrain := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, TERRAIN_LAYER))
	var end := to
	var hit: Dictionary = {}
	if not terrain.is_empty():
		end = terrain.position
		hit = {"point": end, "normal": terrain.normal, "surface": Surface.DIRT, "impact_material": &"dirt"}
	for solid in cover:
		var bounds: AABB = solid.bounds
		var broad_contact: Variant = bounds.intersects_segment(from, end)
		if broad_contact == null:
			continue
		var point: Vector3 = broad_contact
		var normal: Vector3
		var impact_material: StringName = solid.impact_material
		if solid.has("model"):
			var model: MeshInstance3D = solid.model
			var inverse: Transform3D = solid.world_to_local
			var triangles := model.mesh.generate_triangle_mesh()
			if not triangles:
				continue
			var contact := triangles.intersect_segment(inverse * from, inverse * end)
			if contact.is_empty():
				continue
			point = model.global_transform * Vector3(contact.position)
			normal = (inverse.basis.transposed() * Vector3(contact.normal)).normalized()
			impact_material = cover_impact(solid, contact.face_index)
		else:
			normal = box_face_normal(bounds, point)
		end = point
		hit = {"point": point, "normal": normal, "surface": Surface.COVER, "impact_material": impact_material}
	for unit in units:
		if unit == shooter or unit.is_queued_for_deletion():
			continue
		var contact: Dictionary = unit.trace_shot(from, end)
		if contact.is_empty() or (not hit.is_empty() and from.distance_squared_to(contact.point) >= from.distance_squared_to(end)):
			continue
		end = contact.point
		hit = contact
		hit.unit = unit
		hit.direction = direction
	return hit

func box_face_normal(bounds: AABB, point: Vector3) -> Vector3:
	var offset := point - bounds.get_center()
	var gap := bounds.size * 0.5 - offset.abs()
	var axis := gap.min_axis_index()
	var normal := Vector3.ZERO
	normal[axis] = -1.0 if offset[axis] < 0.0 else 1.0
	return normal

