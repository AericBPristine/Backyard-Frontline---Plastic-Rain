extends RefCounted

const KIT := preload("res://art/woodland/props/field_props.glb")
const HOUSE := preload("res://art/woodland/props/one_story_cottage.glb")
const SHED := preload("res://art/woodland/props/tool_shed.glb")

const CENTER := Vector2(75.0, -354.0)
const HALF := Vector2(17.0, 13.0)
const SPURS := [
	[1.75, [Vector2(42.6, -353.0), Vector2(50.0, -354.2), Vector2(60.2, -354.0),
		Vector2(68.2, -354.0), Vector2(75.0, -353.5), Vector2(80.5, -351.9),
		Vector2(84.8, -347.7), Vector2(87.0, -348.8)]],
	[0.92, [Vector2(71.5, -353.8), Vector2(72.8, -355.0), Vector2(74.4, -356.2),
		Vector2(75.0, -357.0)]],
]

# Coordinates are east and south offsets from the center of the yard.
const FIXTURES := [
	[&"FieldRoad", Vector2(-28.5, 3.35), 19.0],
	[&"DepotArrow", Vector2(-20.1, -1.95), -18.0],
	[&"TrailMarker", Vector2(-22.0, 2.95), 24.0],
	[&"ConcreteBarrier", Vector2(-24.6, -3.1), 14.0],
	[&"SandbagWall", Vector2(-23.5, 3.95), -16.0],
	[&"FarmCorner", Vector2(-16.2, 11.6), -90.0],
	[&"BlankSign", Vector2(-2.45, -1.85), -8.0],
	[&"BrickWall", Vector2(5.0, -6.25), -90.0],
	[&"BrokenBrick", Vector2(-5.5, -6.55), 90.0],
	[&"RainBarrel", Vector2(-3.55, -2.18), 15.0],
	[&"KeepOut", Vector2(8.4, 8.6), 23.0],
	[&"TimberCrate", Vector2(13.75, 4.12), -13.0],
	[&"OpenCrate", Vector2(12.26, 4.82), 8.0],
	[&"SupplyCase", Vector2(13.7, 5.6), -4.0],
	[&"ShippingPallet", Vector2(13.2, 7.35), 7.0],
	[&"CartonStack", Vector2(10.4, 4.75), 10.0],
	[&"OliveDrum", Vector2(14.12, 4.68), 5.0],
	[&"OxideDrum", Vector2(14.72, 4.88), -21.0],
	[&"OpenDrum", Vector2(14.29, 7.33), 12.0],
	[&"CradledDrum", Vector2(14.0, 0.2), 72.0],
	[&"SandbagCorner", Vector2(7.27, 4.5), 32.0],
]

const FARM_RUNS := [
	[Vector2(-16.2, -12.4), Vector2(-16.2, -2.5)],
	[Vector2(-16.2, 2.5), Vector2(-16.2, 10.15)],
	[Vector2(-16.2, -12.4), Vector2(-4.5, -12.4)],
	[Vector2(4.5, -12.4), Vector2(15.8, -12.4)],
	[Vector2(15.8, -12.4), Vector2(15.8, -0.7)],
	[Vector2(-14.75, 11.6), Vector2(4.8, 11.6)],
]

static func inside_clearing(at: Vector2) -> bool:
	var offset := (at - CENTER).abs()
	return offset.x <= HALF.x + 4.0 and offset.y <= HALF.y + 4.0

static func build(parent: Node3D, height_at: Callable) -> void:
	var site := Node3D.new()
	site.name = "Field Road Property"
	parent.add_child(site)

	var kit := KIT.instantiate()
	add_building(HOUSE, "Roadside Cottage", site, Vector2(0.0, -6.95), -4.0, height_at)
	add_building(SHED, "Roadside Tool Shed", site, Vector2(11.35, 1.9), 0.0, height_at)

	for fixture in FIXTURES:
		place(kit, site, fixture[0], CENTER + fixture[1], fixture[2], height_at)
	for run in FARM_RUNS:
		fence_run(kit, site, &"FarmRail", run[0], run[1], 3.073, height_at)
	fence_run(kit, site, &"PlankScreen", Vector2(-4.5, -12.4), Vector2(4.5, -12.4), 3.00, height_at)
	fence_run(kit, site, &"ChainLink", Vector2(15.8, -0.7), Vector2(15.8, 9.25), 2.78, height_at)
	fence_run(kit, site, &"ChainLink", Vector2(15.8, 9.25), Vector2(8.9, 9.25), 2.78, height_at)

	for side in [-1.0, 1.0]:
		var hinge := Vector2(-16.2, 2.5 * side)
		place(kit, site, &"FarmGatePost", CENTER + hinge, 0.0, height_at)
		# Both leaves point into the yard, away from the driveway center.
		place(kit, site, &"FarmGateLeaf", CENTER + hinge, -13.0 * side, height_at)
	kit.free()

static func add_building(model: PackedScene, label: String, parent: Node3D,
		offset: Vector2, yaw: float, height_at: Callable) -> void:
	var building := model.instantiate() as Node3D
	building.name = label
	building.position = world_position(CENTER + offset, height_at)
	building.rotation_degrees.y = yaw
	parent.add_child(building)

static func fence_run(kit: Node, parent: Node3D, style: StringName,
		start: Vector2, end: Vector2, model_length: float, height_at: Callable) -> void:
	var delta := end - start
	var count := maxi(1, roundi(delta.length() / model_length))
	var yaw := rad_to_deg(atan2(-delta.y, delta.x))
	var stretch := delta.length() / (count * model_length)
	for section in range(count):
		var offset := start.lerp(end, (section + 0.5) / count)
		var panel := place(kit, parent, style, CENTER + offset, yaw, height_at)
		panel.scale.x = stretch

static func place(kit: Node, parent: Node3D, prop: StringName,
		at: Vector2, yaw: float, height_at: Callable) -> MeshInstance3D:
	var template := kit.get_node(NodePath(prop)) as MeshInstance3D
	var instance := MeshInstance3D.new()
	instance.name = prop
	instance.mesh = template.mesh
	instance.position = world_position(at, height_at)
	instance.rotation_degrees.y = yaw
	parent.add_child(instance, true)
	return instance

static func world_position(at: Vector2, height_at: Callable) -> Vector3:
	return Vector3(at.x, float(height_at.call(at)), at.y)
