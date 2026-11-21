extends RefCounted

const ORIGIN := Vector3(1, 0, -37)

static func height_at(local: Vector2) -> float:
	var edge := 1.0 - pow(local.x / 39.5, 2.0) - pow(local.y / 15.0, 2.0)
	return 6.0 * pow(maxf(edge, 0.0), 1.28)

static func build() -> ArrayMesh:
	return build_surface(Vector2(81, 32), Vector2i(39, 27), height_at)

static func build_surface(size: Vector2, subdivisions: Vector2i, sample_height: Callable) -> ArrayMesh:
	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = subdivisions.x
	plane.subdivide_depth = subdivisions.y
	var data := plane.surface_get_arrays(0)
	var positions: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = data[Mesh.ARRAY_NORMAL]
	for index in range(positions.size()):
		var point := Vector2(positions[index].x, positions[index].z)
		positions[index].y = float(sample_height.call(point)) + 0.009
		var dx := float(sample_height.call(point + Vector2(0.1, 0))) - float(sample_height.call(point - Vector2(0.1, 0)))
		var dz := float(sample_height.call(point + Vector2(0, 0.1))) - float(sample_height.call(point - Vector2(0, 0.1)))
		normals[index] = Vector3(-dx, 0.2, -dz).normalized()
	data[Mesh.ARRAY_VERTEX] = positions
	data[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
	return mesh
