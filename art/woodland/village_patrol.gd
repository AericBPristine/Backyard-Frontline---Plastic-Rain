extends RefCounted

enum Activity { ROAM, ALERT, SEEK_COVER, WAIT_IN_COVER, PEEK }

const CELL_SIZE := 2.0
const COVER_SEARCH_RADIUS := 22.0
const SIGHT_RANGE_SQUARED := 70.0 * 70.0
const SIGHT_CONE_COSINE := 0.34

var walk_obstacles: Array[Rect2] = []
var sight_obstacles: Array[AABB] = []
var cover_spots: Array[Vector2] = []
var grid := AStarGrid2D.new()

func setup(area: Rect2, props: Node3D, player_radius: float) -> void:
	var start := cell_at(area.position)
	var finish := cell_at(area.end)
	grid.region = Rect2i(start, finish - start + Vector2i.ONE)
	grid.cell_size = Vector2.ONE * CELL_SIZE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for prop: MeshInstance3D in props.find_children("*", "MeshInstance3D", true, false):
		var bounds: AABB = prop.global_transform * prop.get_aabb()
		if bounds.size.y < 0.36:
			continue
		sight_obstacles.append(bounds)
		var footprint := Rect2(Vector2(bounds.position.x, bounds.position.z),
			Vector2(bounds.size.x, bounds.size.z)).grow(player_radius)
		walk_obstacles.append(footprint)
		var padded := footprint.grow(CELL_SIZE * 0.5)
		var cells := Rect2i(cell_at(padded.position), cell_at(padded.end) - cell_at(padded.position) + Vector2i.ONE)
		grid.fill_solid_region(cells.intersection(grid.region))
		if bounds.size.y >= 1.65:
			var center := footprint.get_center()
			var border := footprint.size * 0.5 + Vector2.ONE * (CELL_SIZE * 1.4)
			for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				cover_spots.append(center + Vector2(direction) * border)

func cell_at(at: Vector2) -> Vector2i:
	return Vector2i((at / CELL_SIZE).round())

func open_cell(at: Vector2) -> Vector2i:
	var center := cell_at(at).clamp(grid.region.position, grid.region.end - Vector2i.ONE)
	if not grid.is_point_solid(center):
		return center
	var closest := center
	var best := INF
	for x in range(-4, 5):
		for y in range(-4, 5):
			var candidate := center + Vector2i(x, y)
			var distance := at.distance_squared_to(Vector2(candidate) * CELL_SIZE)
			if distance < best and grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate):
				closest = candidate
				best = distance
	return closest

func route(from: Vector2, destination: Vector2) -> PackedVector2Array:
	var start := open_cell(from)
	var end := open_cell(destination)
	if grid.is_point_solid(start) or grid.is_point_solid(end):
		return PackedVector2Array()
	var path := grid.get_point_path(start, end)
	if not path.is_empty():
		# Follow every leg when the unit is away from the center of its starting cell.
		if from.distance_squared_to(path[0]) < 0.04:
			path.remove_at(0)
	return path

func sees_player(unit: Node3D, player: Node3D) -> bool:
	var offset := player.global_position - unit.global_position
	var across := Vector2(offset.x, offset.z)
	var facing := Vector2(-unit.global_basis.z.x, -unit.global_basis.z.z)
	if offset.length_squared() > SIGHT_RANGE_SQUARED or facing.dot(across.normalized()) < SIGHT_CONE_COSINE:
		return false
	var eyes := unit.global_position + Vector3.UP * 1.48
	return clear_view(eyes, player.global_position + Vector3.UP * 1.25)

func route_to_cover(unit: Node3D, player: Node3D) -> PackedVector2Array:
	var origin := Vector2(unit.position.x, unit.position.z)
	var target := player.global_position + Vector3.UP * 1.25
	var best_distance := COVER_SEARCH_RADIUS * COVER_SEARCH_RADIUS
	var best_path := PackedVector2Array()
	for spot in cover_spots:
		var cell := cell_at(spot)
		if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell):
			continue
		var candidate := Vector2(cell) * CELL_SIZE
		var distance := origin.distance_squared_to(candidate)
		if distance >= best_distance or distance < 1.0:
			continue
		if clear_view(Vector3(candidate.x, unit.position.y + 1.48, candidate.y), target):
			continue
		var path := route(origin, candidate)
		if not path.is_empty():
			best_distance = distance
			best_path = path
	return best_path

func clear_view(from: Vector3, to: Vector3) -> bool:
	for obstruction in sight_obstacles:
		if obstruction.intersects_segment(from, to) != null:
			return false
	return true
