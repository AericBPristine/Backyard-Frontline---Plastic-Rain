extends RefCounted

const RIDGE := preload("res://art/woodland/ridge_mesh.gd")
const OUTPOST := preload("res://art/woodland/outpost.gd")
const ROADSIDE := preload("res://art/woodland/roadside_property.gd")
const VILLAGE := preload("res://art/woodland/pine_hollow.gd")
const MASK_SIZE := 1024
const HOLE_OFFSET := 2.45
const HOLE_RADIUS := Vector2(2.28, 1.8)
const HOLE_DEPTH := 0.74
const OBSERVER_POST := Vector2(252, -267)
const OBSERVER_HALF := Vector2(5, 5)
const EAST_RANGE_HEIGHT_SCALE := 0.60
const OBSERVER_POST_HEIGHT := 88.0 * EAST_RANGE_HEIGHT_SCALE
const SUMMIT_HALF := Vector2(6.5, 6.5)
const EAST_FOOTHILLS := 91.0

# Ridge crests and the lower saddles between them, ordered north to south.
const EAST_SPINE: Array[Vector3] = [
	Vector3(300, 77, -734), Vector3(281, 126, -672), Vector3(306, 66, -612),
	Vector3(257, 113, -537), Vector3(288, 63, -462), Vector3(272, 122, -399),
	Vector3(302, 52, -339), Vector3(315, 70, -282), Vector3(293, 52, -220),
	Vector3(268, 112, -147), Vector3(293, 55, -95), Vector3(273, 94, -44),
	Vector3(295, 62, 16),
]

# Roads run along the two sides of the valley. The shorter paths reach the
# south-facing entrances from the original building placement.
const ROAD_PATHS := [
	[2.10, [Vector2(-38,-719), Vector2(-39,-654), Vector2(-42,-592), Vector2(-45,-533), Vector2(-39,-466), Vector2(-39,-416), Vector2(-38,-360), Vector2(-39,-312), Vector2(-30,-261), Vector2(-16,-232)]],
	[1.95, [Vector2(44,-711), Vector2(49,-645), Vector2(43,-593), Vector2(44,-531), Vector2(50,-470), Vector2(47,-422), Vector2(39,-371), Vector2(50,-323), Vector2(55,-274), Vector2(38,-244), Vector2(17,-224)]],
	[1.36, [Vector2(-39,-650), Vector2(-44,-652), Vector2(-48,-656)]],
	[1.23, [Vector2(45,-522), Vector2(48,-523), Vector2(51,-527)]],
	[1.36, [Vector2(-39,-415), Vector2(-43,-417), Vector2(-47,-421)]],
	[1.24, [Vector2(54,-264), Vector2(49,-267), Vector2(46,-271)]],
	[1.75, [Vector2(-30,-261), Vector2(-7,-257), Vector2(12,-254), Vector2(35,-248)]],
]
const HILL_ROADS := [
	[2.35, [Vector2(-16,-232), Vector2(-31,-231), Vector2(-34,-214), Vector2(-26,-199), Vector2(-13,-194), Vector2(0,-196), Vector2(0,-202)]],
	[1.80, [Vector2(17,-224), Vector2(27,-220), Vector2(34,-212), Vector2(30,-201), Vector2(23,-198), Vector2(11,-195), Vector2(0,-196)]],
	[1.50, [Vector2(-30,-205), Vector2(-26,-207), Vector2(-23,-207)]],
	[1.70, [Vector2(-38,-312), Vector2(-21,-319), Vector2(1,-321), Vector2(27,-314), Vector2(39,-312)]],
]

var map_center: Vector2
var half_size: float
var outpost_center: Vector2
var open_fields: bool
var practice_field: bool
var stations: Array[Vector2] = []
var pads: Array[Vector2] = []
var pad_heights := PackedFloat32Array()
var roadside_height: float
var station_heights := PackedFloat32Array()
var paint: Image

func _init(center: Vector2, half: float, outpost: Vector2, lines: Array, props: Array,
		open := false, practice := false) -> void:
	map_center = center
	half_size = half
	outpost_center = outpost
	open_fields = open
	practice_field = practice
	roadside_height = rolling_height(ROADSIDE.CENTER)
	for line in lines:
		for station in line:
			stations.append(station)
			station_heights.append(rolling_height(station))
	for prop in props:
		pads.append(prop[1])
		pad_heights.append(rolling_height(prop[1]))

func rolling_height(at: Vector2) -> float:
	if practice_field:
		return 0.0
	var edge := (at - map_center).abs()
	var edge_fade := 1.0 - smoothstep(half_size - 56.0, half_size, maxf(edge.x, edge.y))
	var yard_fade := smoothstep(56.0, 116.0, -at.y)
	var outpost_clearance := smoothstep(19.0, 57.0, at.distance_to(outpost_center))
	var swell := 1.8 + 2.45 * sin(at.x * 0.016 - at.y * 0.009)
	swell += 1.85 * cos(at.y * 0.022 + at.x * 0.008)
	swell += 0.95 * sin(at.x * 0.037 + at.y * 0.029)
	var west := (at - Vector2(-105, -431)) / Vector2(73, 106)
	var east := (at - Vector2(114, -580)) / Vector2(82, 112)
	swell += 5.6 * exp(-west.length_squared() * 2.1)
	swell += 4.4 * exp(-east.length_squared() * 2.2)
	return swell * edge_fade * yard_fade * outpost_clearance * (0.23 if open_fields else 1.0)

func height_at(at: Vector2) -> float:
	if practice_field:
		return 0.0
	var height := rolling_height(at)
	for i in range(pads.size()):
		var distance := at.distance_squared_to(pads[i])
		if distance < 196.0:
			height = lerpf(pad_heights[i], height, smoothstep(47.0, 196.0, distance))
	for i in range(stations.size()):
		var offset := at - stations[i]
		if absf(offset.x) > 7.8 or absf(offset.y + 1.1) > 5.7:
			continue
		var grade := maxf(absf(offset.x), absf(offset.y + 1.1) * 1.35)
		height = lerpf(station_heights[i], height, smoothstep(4.6, 7.7, grade))
		var pocket := Vector2(absf(offset.x) - HOLE_OFFSET, offset.y + 2.48) / HOLE_RADIUS
		height -= HOLE_DEPTH * (1.0 - smoothstep(0.16, 1.0, pocket.length_squared()))
		break
	if not practice_field:
		var yard_edge := (at - ROADSIDE.CENTER).abs() - ROADSIDE.HALF
		if maxf(yard_edge.x, yard_edge.y) < 8.0:
			var blend := smoothstep(0.0, 8.0, yard_edge.max(Vector2.ZERO).length())
			height = lerpf(roadside_height, height, blend)
	var ridge := RIDGE.height_at(at - Vector2(RIDGE.ORIGIN.x, RIDGE.ORIGIN.z))
	var hill := OUTPOST.height_at(at - outpost_center)
	if open_fields:
		ridge *= 0.55
		var foothill := ((at - outpost_center).abs() - Vector2(28.0, 12.0)).max(Vector2.ZERO)
		hill = 17.5 * (1.0 - smoothstep(0.0, 1.0, (foothill / Vector2(53.0, 64.0)).length()))
	var rise := maxf(ridge, hill)
	if not practice_field and at.x >= EAST_FOOTHILLS:
		rise = maxf(rise, east_range_height(at))
		var local := at - OBSERVER_POST
		if absf(local.x) < 117.0 and absf(local.y) < 133.0:
			height *= smoothstep(SUMMIT_HALF.x, 17.0, maxf(absf(local.x), absf(local.y)))
			rise = maxf(rise, observer_mountain_height(local))
	return height + rise

func east_range_height(at: Vector2) -> float:
	var east := map_center.x + half_size
	var north := map_center.y - half_size
	var south := map_center.y + half_size
	var west_foot := 124.0 + 17.0 * sin(at.y * 0.023) - 15.0 * cos(at.y * 0.037)
	if at.x <= west_foot or at.x >= east or at.y <= north or at.y >= south:
		return 0.0

	var segment := 0
	while segment < EAST_SPINE.size() - 2 and at.y > EAST_SPINE[segment + 1].z:
		segment += 1
	var start := EAST_SPINE[segment]
	var end := EAST_SPINE[segment + 1]
	var crest := start.lerp(end, smoothstep(start.z, end.z, at.y))
	var across := at.x - crest.x
	var width := crest.x - west_foot if across < 0.0 else east - crest.x
	var flank := 1.0 - smoothstep(0.0, 1.0, absf(across) / width)
	var ribs := 12.0 * sin(at.y * 0.058 + across * 0.038) + 6.0 * cos(at.y * 0.11 - across * 0.05)
	var end_fade := smoothstep(north, north + 42.0, at.y) * (1.0 - smoothstep(south - 39.0, south, at.y))
	return EAST_RANGE_HEIGHT_SCALE * end_fade * flank * (crest.y + ribs * (1.0 - flank))

static func observer_mountain_height(local: Vector2) -> float:
	var skirt := (local.abs() - SUMMIT_HALF).max(Vector2.ZERO)
	var slope := (skirt / Vector2(108.0, 125.0)).length()
	var shoulder := 1.0 - smoothstep(0.0, 1.0, slope)
	# A rounded lip beside the level post keeps the immediate foreground below the observer.
	var cap := 1.0 - smoothstep(0.0, 0.38, slope)
	var crest := lerpf(shoulder, cap, 0.42)
	var folds := 4.0 * sin(local.x * 0.08 + local.y * 0.057) + 3.0 * cos(local.y * 0.075)
	return crest * OBSERVER_POST_HEIGHT + crest * (1.0 - crest) * folds

func build_mesh() -> ArrayMesh:
	var left := map_center.x - half_size
	var north := map_center.y - half_size
	var x_knots := {}
	var z_knots := {}
	for i in range(133):
		x_knots[lerpf(left, left + half_size * 2.0, i / 132.0)] = true
		z_knots[lerpf(north, north + half_size * 2.0, i / 132.0)] = true
	for station in stations:
		for cell in range(-4, 5):
			x_knots[snappedf(station.x + cell * 1.18, 0.15)] = true
		for cell in range(7):
			z_knots[snappedf(station.y - 4.34 + cell * 0.78, 0.15)] = true
	for cell in range(26):
		z_knots[-55.0 + cell * 1.46] = true
	for cell in range(28):
		z_knots[outpost_center.y - 32.0 + cell * 2.4] = true
	if open_fields:
		for offset in [-28.0, -24.0, 24.0, 28.0]:
			x_knots[outpost_center.x + offset] = true
		z_knots[outpost_center.y - 12.0] = true
		z_knots[outpost_center.y + 12.0] = true
	if not practice_field:
		for lot in VILLAGE.LOTS:
			var center: Vector2 = lot[1]
			x_knots[center.x] = true
			z_knots[center.y] = true
		for side in [-1.0, 1.0]:
			x_knots[ROADSIDE.CENTER.x + side * ROADSIDE.HALF.x] = true
			z_knots[ROADSIDE.CENTER.y + side * ROADSIDE.HALF.y] = true
		for crest in EAST_SPINE:
			x_knots[crest.x] = true
			z_knots[crest.z] = true
		for offset in [-SUMMIT_HALF.x, -5.0, -2.5, 0.0, 2.5, 5.0, SUMMIT_HALF.x]:
			x_knots[OBSERVER_POST.x + offset] = true
			z_knots[OBSERVER_POST.y + offset] = true
	x_knots[0.0] = true
	z_knots[0.0] = true
	var xs := x_knots.keys()
	var zs := z_knots.keys()
	xs.sort()
	zs.sort()
	var width := xs.size()
	var depth := zs.size()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	vertices.resize(width * depth)
	normals.resize(vertices.size())
	indices.resize((width - 1) * (depth - 1) * 6)
	for z in range(depth):
		for x in range(width):
			var at := Vector2(xs[x], zs[z])
			vertices[z * width + x] = Vector3(at.x, height_at(at), at.y)
	var cursor := 0
	for z in range(depth):
		for x in range(width):
			var i := z * width + x
			var x_low := vertices[z * width + maxi(x - 1, 0)]
			var x_high := vertices[z * width + mini(x + 1, width - 1)]
			var z_low := vertices[maxi(z - 1, 0) * width + x]
			var z_high := vertices[mini(z + 1, depth - 1) * width + x]
			normals[i] = (z_high - z_low).cross(x_high - x_low).normalized()
			if x < width - 1 and z < depth - 1:
				indices[cursor] = i
				indices[cursor + 1] = i + 1
				indices[cursor + 2] = i + width
				indices[cursor + 3] = i + 1
				indices[cursor + 4] = i + width + 1
				indices[cursor + 5] = i + width
				cursor += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func paint_texture() -> ImageTexture:
	var pixels := PackedByteArray()
	pixels.resize(MASK_SIZE * MASK_SIZE * 2)
	var pixels_per_unit := MASK_SIZE / (half_size * 2.0)
	var roads := ROAD_PATHS + ROADSIDE.SPURS + VILLAGE.LANES + VILLAGE.footpaths()
	if open_fields:
		roads += HILL_ROADS
	if practice_field:
		roads = VILLAGE.LANES + VILLAGE.footpaths() + VILLAGE.PRACTICE_ACCESS
	for road in roads:
		var curve := Curve2D.new()
		curve.bake_interval = 3.5
		var points: Array = road[1]
		for i in range(points.size()):
			var hint: Vector2 = (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]) / 6.0
			curve.add_point(points[i], -hint, hint)
		var baked := curve.get_baked_points()
		var radius: float = road[0] * pixels_per_unit
		for i in range(baked.size() - 1):
			paint_segment(pixels, world_to_pixel(baked[i]), world_to_pixel(baked[i + 1]), radius)
	for at in stations:
		for side in [-1.0, 1.0]:
			var center := world_to_pixel(at + Vector2(side * HOLE_OFFSET, -2.48))
			var size := (HOLE_RADIUS + Vector2(0.48, 0.40)) * pixels_per_unit
			paint_pocket(pixels, center, size)
	if not practice_field:
		var start := world_to_pixel(OBSERVER_POST + Vector2(0.0, -2.1))
		var stop := world_to_pixel(OBSERVER_POST + Vector2(0.0, 2.1))
		paint_segment(pixels, start, stop, 3.5 * pixels_per_unit)
	paint = Image.create_from_data(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_RG8, pixels)
	paint.generate_mipmaps()
	return ImageTexture.create_from_image(paint)

func world_to_pixel(at: Vector2) -> Vector2:
	return ((at - map_center) / (half_size * 2.0) + Vector2(0.5, 0.5)) * MASK_SIZE - Vector2(0.5, 0.5)

func on_road(at: Vector2) -> bool:
	var px := Vector2i(world_to_pixel(at).round()).clamp(Vector2i.ZERO, Vector2i.ONE * (MASK_SIZE - 1))
	return paint.get_pixelv(px).r > 0.25

static func paint_segment(pixels: PackedByteArray, a: Vector2, b: Vector2, radius: float) -> void:
	var pad := Vector2.ONE * (radius + 1.18)
	var start := Vector2i((a.min(b) - pad).floor()).max(Vector2i.ZERO)
	var stop := Vector2i((a.max(b) + pad).ceil()).min(Vector2i.ONE * (MASK_SIZE - 1))
	var segment := b - a
	var length_squared := maxf(segment.length_squared(), 0.0001)
	for y in range(start.y, stop.y + 1):
		for x in range(start.x, stop.x + 1):
			var delta := Vector2(x, y) - a
			var edge := (delta - segment * clampf(delta.dot(segment) / length_squared, 0.0, 1.0)).length()
			var coverage := roundi((1.0 - smoothstep(radius - 0.65, radius + 0.97, edge)) * 255)
			var index := (y * MASK_SIZE + x) * 2
			pixels[index] = maxi(pixels[index], coverage)

static func paint_pocket(pixels: PackedByteArray, center: Vector2, radius: Vector2) -> void:
	var start := Vector2i((center - radius).floor()).max(Vector2i.ZERO)
	var stop := Vector2i((center + radius).ceil()).min(Vector2i.ONE * (MASK_SIZE - 1))
	for y in range(start.y, stop.y + 1):
		for x in range(start.x, stop.x + 1):
			var distance := ((Vector2(x, y) - center) / radius).length_squared()
			var strength := roundi((1.0 - smoothstep(0.35, 1.0, distance)) * 255)
			var index := (y * MASK_SIZE + x) * 2 + 1
			pixels[index] = maxi(pixels[index], strength)

