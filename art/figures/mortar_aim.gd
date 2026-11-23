extends RefCounted

# Manual shots use impact_for_aim. A human gunner's mils invert that mapping,
# then call ai_mortar_correction — the tube's existing mil conversion.

const AIM_WIDTH_STEP := 1.55
const AIM_BASE_DISTANCE := 70.0
const AIM_DEPTH_STEP := 7.65
const MILS_PER_TURN := 6400
const AZIMUTH_MILS_PER_STEP := 10
const ELEVATION_MILS_AT_ZERO := 480
const ELEVATION_MILS_PER_STEP := 12

static func impact_for_aim(aim_heading: float, aim_elevation: float) -> Vector3:
	return Vector3(aim_heading * AIM_WIDTH_STEP, 0.3, -AIM_BASE_DISTANCE - aim_elevation * AIM_DEPTH_STEP)

static func aim_for_impact(point: Vector2) -> Vector2:
	return Vector2(point.x / AIM_WIDTH_STEP, (-point.y - AIM_BASE_DISTANCE) / AIM_DEPTH_STEP)

static func signed_azimuth_mils(aim_heading: float) -> int:
	return roundi(aim_heading * AZIMUTH_MILS_PER_STEP)

static func elevation_mils(aim_elevation: float) -> int:
	return ELEVATION_MILS_AT_ZERO + roundi(aim_elevation * ELEVATION_MILS_PER_STEP)

static func ai_mortar_correction(aim_heading: float, aim_elevation: float, from_heading: float, from_elevation: float) -> Vector2i:
	return Vector2i(
		signed_azimuth_mils(aim_heading) - signed_azimuth_mils(from_heading),
		elevation_mils(aim_elevation) - elevation_mils(from_elevation)
	)

static func human_gunner_correction(point: Vector2, from_heading: float, from_elevation: float) -> Vector2i:
	var aim := aim_for_impact(point)
	return ai_mortar_correction(aim.x, aim.y, from_heading, from_elevation)

static func format_correction(deflection: int, elevation_change: int) -> String:
	var parts := PackedStringArray()
	if deflection > 0:
		parts.append("Right %d %s" % [deflection, mil_word(deflection)])
	elif deflection < 0:
		parts.append("Left %d %s" % [-deflection, mil_word(-deflection)])
	if elevation_change > 0:
		parts.append("Up %d %s" % [elevation_change, mil_word(elevation_change)])
	elif elevation_change < 0:
		parts.append("Down %d %s" % [-elevation_change, mil_word(-elevation_change)])
	if parts.is_empty():
		return "On target"
	return ", ".join(parts)

static func mil_word(amount: int) -> String:
	return "mil" if absi(amount) == 1 else "mils"
