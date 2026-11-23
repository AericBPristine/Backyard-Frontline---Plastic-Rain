extends RefCounted

const PROPS := preload("res://art/woodland/roadside_property.gd")
const HOUSES := preload("res://art/woodland/props/pine_hollow_houses.glb")
const CLEARING := Rect2(-156.0, -525.0, 97.0, 53.0)

const LANES := [
	[2.12, [Vector2(-42.5, -500.0), Vector2(-52.5, -499.2), Vector2(-66.0, -498.6),
		Vector2(-79.0, -500.2), Vector2(-94.0, -501.6), Vector2(-110.0, -499.7),
		Vector2(-124.0, -499.1), Vector2(-139.0, -501.8), Vector2(-148.8, -502.4),
		Vector2(-152.0, -498.9), Vector2(-151.0, -491.4)]],
	[3.0, [Vector2(-111.5, -499.1), Vector2(-105.0, -500.2)]],
	[2.45, [Vector2(-107.6, -498.5), Vector2(-107.6, -495.5), Vector2(-103.5, -495.4)]],
]

const PRACTICE_ACCESS := [
	[2.1, [Vector2(-96.1, -460.0), Vector2(-96.0, -472.0), Vector2(-94.0, -482.0),
		Vector2(-93.9, -492.0), Vector2(-94.0, -501.6)]],
]

# Each house has a lot position, a front-door offset, and its edge of the lane.
const LOTS := [
	[&"StoneCroft", Vector2(-143.0, -516.1), -4.0, Vector2(0.0, 2.97), -502.2],
	[&"GardenCottage", Vector2(-126.6, -512.5), -10.0, Vector2(1.85, 2.95), -499.6],
	[&"MillHouse", Vector2(-108.2, -514.0), 6.0, Vector2(0.0, 3.45), -499.7],
	[&"VerandaHouse", Vector2(-89.0, -516.0), -5.0, Vector2(0.0, 4.56), -501.3],
	[&"BlueSaltbox", Vector2(-71.6, -511.0), -7.0, Vector2(-1.94, 3.18), -499.1],
	[&"RedHillHouse", Vector2(-139.3, -486.0), 172.0, Vector2(-0.20, 3.09), -501.7],
	[&"TwinGable", Vector2(-121.6, -484.9), 182.0, Vector2(-1.97, 3.06), -499.1],
	[&"SideWingHouse", Vector2(-101.8, -480.3), 187.0, Vector2(0.94, 3.08), -500.9],
	[&"TallGable", Vector2(-83.8, -485.0), 175.0, Vector2(-1.36, 3.42), -500.8],
	[&"Bungalow", Vector2(-66.5, -484.9), 177.0, Vector2(2.55, 2.89), -498.5],
]

const GARDENS := [
	[[&"BrickWall", Vector2(-4.65, 3.32), 90.0], [&"RainBarrel", Vector2(2.6, 3.54), 57.0],
		[&"FarmRail", Vector2(2.7, 6.4), 9.0]],
	[[&"FarmCorner", Vector2(-4.7, 5.8), -65.0], [&"OpenCrate", Vector2(-2.34, 3.02), 18.0],
		[&"TrailMarker", Vector2(3.55, 6.04), 12.0]],
	[[&"BlankSign", Vector2(-1.8, 4.48), -4.0], [&"ShippingPallet", Vector2(3.55, 3.52), 6.0],
		[&"TimberCrate", Vector2(4.9, 3.38), -9.0], [&"OxideDrum", Vector2(5.38, 1.82), 36.0]],
	[[&"RainBarrel", Vector2(4.46, 2.35), 25.0], [&"FarmRail", Vector2(-2.75, 7.2), -11.0],
		[&"BrickWall", Vector2(3.42, 6.56), 6.0]],
	[[&"PlankScreen", Vector2(-4.66, -0.74), -90.0], [&"OliveDrum", Vector2(3.88, 2.60), 4.0],
		[&"SupplyCase", Vector2(2.91, 3.37), -10.0]],
	[[&"FarmRail", Vector2(3.05, 5.7), 10.0], [&"FarmCorner", Vector2(-4.32, 5.28), 74.0],
		[&"RainBarrel", Vector2(2.50, 3.41), 11.0]],
	[[&"BrickWall", Vector2(3.04, 5.89), -7.0], [&"OpenCrate", Vector2(-3.48, 3.48), 6.0],
		[&"PlankScreen", Vector2(4.85, 0.2), -88.0]],
	[[&"ChainLink", Vector2(5.76, 1.07), -90.0], [&"CradledDrum", Vector2(5.0, 2.44), -19.0],
		[&"OpenDrum", Vector2(5.12, 3.43), 14.0], [&"ShippingPallet", Vector2(3.6, 3.27), -4.0]],
	[[&"CartonStack", Vector2(1.70, 3.68), -11.0], [&"BrokenBrick", Vector2(3.15, 1.38), 88.0],
		[&"BlankSign", Vector2(0.43, 4.13), 8.0]],
	[[&"RainBarrel", Vector2(-3.49, 3.23), 6.0], [&"FarmRail", Vector2(-2.3, 5.36), -10.0],
		[&"OpenCrate", Vector2(0.67, 2.96), 14.0]],
]

const COMMON_PROPS := [
	[&"PineHollowSign", Vector2(-54.9, -495.9), 83.0],
	[&"VillageWell", Vector2(-105.1, -495.4), 19.0],
	[&"VillageBench", Vector2(-108.4, -494.3), -81.0],
	[&"VillageBench", Vector2(-102.8, -495.8), 79.0],
	[&"GardenPlanter", Vector2(-106.1, -492.8), 18.0],
]
const HOUSE_PLANTERS := {
	0: Vector2(-2.73, 3.04), 1: Vector2(-0.79, 3.08), 3: Vector2(2.58, 4.73),
	4: Vector2(0.07, 3.11), 5: Vector2(-2.23, 3.13), 8: Vector2(0.95, 3.45),
	9: Vector2(-2.45, 2.90),
}

const PINES := [
	Vector3(-146.5, 6.8, -522.5), Vector3(-136.1, 5.9, -519.9),
	Vector3(-117.4, 7.8, -520.5), Vector3(-99.6, 5.4, -519.0),
	Vector3(-80.0, 7.5, -521.0), Vector3(-64.3, 6.3, -514.6),
	Vector3(-151.4, 6.9, -481.5), Vector3(-130.1, 5.7, -477.9),
	Vector3(-114.8, 6.5, -475.2), Vector3(-92.3, 5.5, -476.9),
	Vector3(-73.5, 6.8, -478.5), Vector3(-59.6, 5.8, -483.8),
	Vector3(-132.3, 4.7, -505.4), Vector3(-94.8, 4.8, -494.5),
]

static func footpaths() -> Array:
	var paths := []
	for lot in LOTS:
		var at: Vector2 = lot[1]
		var entrance: Vector2 = at + lot[3].rotated(-deg_to_rad(lot[2]))
		var curb := Vector2(entrance.x, lot[4])
		var bend := curb.lerp(entrance, 0.54) + Vector2(0.72, 0.0)
		paths.append([0.90, [curb, bend, entrance]])
	return paths

static func build(parent: Node3D, height_at: Callable) -> void:
	var village := Node3D.new()
	village.name = "Pine Hollow Village"
	parent.add_child(village)
	var houses := HOUSES.instantiate()
	var props := PROPS.KIT.instantiate()
	for i in range(LOTS.size()):
		var lot: Array = LOTS[i]
		var at: Vector2 = lot[1]
		var yaw: float = lot[2]
		var home := Node3D.new()
		home.name = lot[0]
		village.add_child(home)
		PROPS.place(houses, home, lot[0], at, yaw, height_at)
		for prop in GARDENS[i]:
			var offset: Vector2 = prop[1]
			var point := at + offset.rotated(-deg_to_rad(yaw))
			PROPS.place(props, home, prop[0], point, yaw + prop[2], height_at)
		if HOUSE_PLANTERS.has(i):
			var planter: Vector2 = HOUSE_PLANTERS[i]
			PROPS.place(houses, home, &"GardenPlanter", at + planter.rotated(-deg_to_rad(yaw)), yaw, height_at)
	for fixture in COMMON_PROPS:
		PROPS.place(houses, village, fixture[0], fixture[1], fixture[2], height_at)
	PROPS.place(props, village, &"TrailMarker", Vector2(-147.9, -499.8), 174.0, height_at)
	houses.free()
	props.free()
