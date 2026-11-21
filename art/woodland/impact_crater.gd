extends RefCounted

const RADIUS := 1.75
const MESH_RADIUS := RADIUS * 1.85

static func build(center: Vector2, ground_height: Callable) -> ArrayMesh:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * MESH_RADIUS * 2.0
	plane.subdivide_width = 32
	plane.subdivide_depth = 32
	var geometry := plane.surface_get_arrays(0)
	var positions: PackedVector3Array = geometry[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = geometry[Mesh.ARRAY_NORMAL]
	for index in range(positions.size()):
		var point := Vector2(positions[index].x, positions[index].z)
		positions[index].y = height_at(point, center, ground_height)
		var dx := height_at(point + Vector2(0.07, 0), center, ground_height) - height_at(point - Vector2(0.07, 0), center, ground_height)
		var dz := height_at(point + Vector2(0, 0.07), center, ground_height) - height_at(point - Vector2(0, 0.07), center, ground_height)
		normals[index] = Vector3(-dx, 0.14, -dz).normalized()
	geometry[Mesh.ARRAY_VERTEX] = positions
	geometry[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, geometry)
	return mesh

static func height_at(point: Vector2, center: Vector2, ground_height: Callable) -> float:
	var ground: float = ground_height.call(center + point)
	var distance := point.length() / RADIUS
	var angle := point.angle()
	var edge := 0.76 + sin(angle * 3.0 + center.x) * 0.12 + cos(angle * 5.0 + center.y) * 0.09
	var roughness := sin(point.x * 15.0 + point.y * 7.5) * cos(point.y * 17.0 - point.x * 3.1)
	var scraped := -0.10 * (1.0 - smoothstep(0.09, edge, distance))
	var chips := 0.031 * roughness * (1.0 - smoothstep(0.46, edge + 0.39, distance))
	return ground + scraped + chips + 0.009
