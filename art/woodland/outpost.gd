extends RefCounted

const CONCRETE := Color("#777d66")
const EDGE := Color("#92947b")

static func height_at(local: Vector2) -> float:
	var toe := (local.abs() - Vector2(13.0, 7.0)).max(Vector2.ZERO)
	var slope := (toe / Vector2(25, 24)).length()
	return 8.4 * (1.0 - smoothstep(0.0, 1.0, slope))

static func build(parent: Node3D, center: Vector3, half: Vector2, box: Callable) -> void:
	box.call(parent, center + Vector3(0, 0.026, 0), Vector3(half.x * 2.0, 0.04, half.y * 2.0), Color("#827658"))
	for index in range(10):
		var x := -half.x + (index + 0.5) * 2.0
		wall(parent, center + Vector3(x, 0, -half.y + 0.30), Vector3(1.94, 1.05, 0.58), box)
		if index < 3 or index >= 7:
			wall(parent, center + Vector3(x, 0, half.y - 0.30), Vector3(1.94, 0.88, 0.58), box)
	for side in [-1.0, 1.0]:
		for index in range(5):
			var z := -half.y + (index + 0.5) * 2.0
			wall(parent, center + Vector3(side * (half.x - 0.29), 0, z), Vector3(0.58, 1.0, 1.94), box)
		pillbox(parent, center + Vector3(side * 6.95, 0, -2.05), box)

static func wall(parent: Node3D, at: Vector3, size: Vector3, box: Callable) -> void:
	box.call(parent, at + Vector3.UP * size.y * 0.5, size, CONCRETE)
	box.call(parent, at + Vector3.UP * (size.y - 0.06), Vector3(size.x + 0.04, 0.13, size.z + 0.055), EDGE)

static func pillbox(parent: Node3D, at: Vector3, box: Callable) -> void:
	for x in [-1.66, 1.66]:
		box.call(parent, at + Vector3(x, 1.01, 0), Vector3(0.36, 2.02, 2.45), CONCRETE)
	box.call(parent, at + Vector3(0, 0.47, -1.05), Vector3(3.66, 0.94, 0.36), CONCRETE)
	box.call(parent, at + Vector3(0, 1.84, -1.05), Vector3(3.66, 0.38, 0.36), EDGE)
	box.call(parent, at + Vector3(0, 2.13, 0), Vector3(3.94, 0.27, 2.70), EDGE)
	box.call(parent, at + Vector3(0, 2.30, 0), Vector3(3.52, 0.12, 2.29), CONCRETE)

static func mark_perimeter(parent: Node3D, center: Vector3, half: Vector2, radius: float, ground: Callable) -> void:
	var outline := PackedVector2Array()
	for corner in range(4):
		var center_angle := corner * PI * 0.5
		var diagonal := center_angle + PI * 0.25
		var origin := Vector2(signf(cos(diagonal)) * half.x, signf(sin(diagonal)) * half.y)
		for point in range(10):
			var angle := center_angle + point * PI * 0.5 / 9.0
			outline.append(origin + Vector2(cos(angle), sin(angle)) * radius + Vector2(center.x, center.z))
	var painter := SurfaceTool.new()
	painter.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(outline.size()):
		var from := outline[index]
		var to := outline[(index + 1) % outline.size()]
		var count := maxi(1, ceili(from.distance_to(to) / 2.2))
		var across := (to - from).normalized().orthogonal() * 0.14
		for dash in range(count):
			var a := from.lerp(to, float(dash) / count)
			var b := from.lerp(to, (float(dash) + 0.65) / count)
			for point in [a - across, a + across, b + across, a - across, b + across, b - across]:
				painter.add_vertex(Vector3(point.x, float(ground.call(point)) + 0.035, point.y))
	var marking := StandardMaterial3D.new()
	marking.albedo_color = Color("#bfab61")
	marking.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marking.cull_mode = BaseMaterial3D.CULL_DISABLED
	painter.set_material(marking)
	var perimeter := MeshInstance3D.new()
	perimeter.name = "Outpost Perimeter"
	perimeter.mesh = painter.commit()
	perimeter.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(perimeter)