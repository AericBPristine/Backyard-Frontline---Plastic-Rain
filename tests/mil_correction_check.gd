extends SceneTree

const AIM := preload("res://art/figures/mortar_aim.gd")

func _init() -> void:
	var failures: Array[String] = []
	check_formula(failures)
	check_example(failures)
	check_grid(failures)
	check_zero_crossing(failures)
	if failures.is_empty():
		print("mil correction check passed")
		quit(0)
		return
	for failure in failures:
		print("FAIL: " + failure)
	quit(1)

func check_formula(failures: Array[String]) -> void:
	var headings: Array[float] = [-30.0, -4.2, -0.4, 0.0, 0.4, 4.0, 12.5, 30.0]
	var elevations: Array[float] = [18.0, 40.0, 55.0, 56.25, 70.5, 88.0]
	for heading in headings:
		for elevation in elevations:
			var literal := Vector3(heading * AIM.AIM_WIDTH_STEP, 0.3, -AIM.AIM_BASE_DISTANCE - elevation * AIM.AIM_DEPTH_STEP)
			var produced: Vector3 = AIM.impact_for_aim(heading, elevation)
			if produced != literal:
				failures.append("impact formula drifted at %s, %s" % [heading, elevation])

func check_example(failures: Array[String]) -> void:
	var impact: Vector3 = AIM.impact_for_aim(4.0, 56.25)
	var human: Vector2i = AIM.human_gunner_correction(Vector2(impact.x, impact.z), 0.0, 55.0)
	var ai: Vector2i = AIM.ai_mortar_correction(4.0, 56.25, 0.0, 55.0)
	if human != ai:
		failures.append("example human %s != ai mortar %s" % [human, ai])
	if human != Vector2i(40, 15):
		failures.append("example mils %s, expected (40, 15)" % human)
	expect_format(failures, human.x, human.y, "Right 40 mils, Up 15 mils")
	expect_format(failures, -25, -24, "Left 25 mils, Down 24 mils")
	expect_format(failures, 10, 0, "Right 10 mils")
	expect_format(failures, 0, -1, "Down 1 mil")
	expect_format(failures, 0, 0, "On target")

func expect_format(failures: Array[String], deflection: int, elevation_change: int, expected: String) -> void:
	var text: String = AIM.format_correction(deflection, elevation_change)
	if text != expected:
		failures.append("format (%d, %d) = \"%s\", expected \"%s\"" % [deflection, elevation_change, text, expected])

func check_grid(failures: Array[String]) -> void:
	var headings: Array[float] = [-30.0, -4.2, -0.4, 0.0, 0.4, 3.0, 12.5, 30.0]
	var elevations: Array[float] = [18.0, 40.0, 55.0, 56.25, 70.5, 88.0]
	var origins: Array[Vector2] = [Vector2(0.0, 55.0), Vector2(-6.0, 40.0), Vector2(11.0, 80.0)]
	for heading in headings:
		for elevation in elevations:
			var impact: Vector3 = AIM.impact_for_aim(heading, elevation)
			var recovered: Vector2 = AIM.aim_for_impact(Vector2(impact.x, impact.z))
			if not is_equal_approx(recovered.x, heading) or not is_equal_approx(recovered.y, elevation):
				failures.append("round trip %s, %s -> %s" % [heading, elevation, recovered])
				continue
			for origin in origins:
				var human: Vector2i = AIM.human_gunner_correction(Vector2(impact.x, impact.z), origin.x, origin.y)
				var ai: Vector2i = AIM.ai_mortar_correction(heading, elevation, origin.x, origin.y)
				if human != ai:
					failures.append("human %s != ai %s for aim %s, %s from %s" % [human, ai, heading, elevation, origin])

func check_zero_crossing(failures: Array[String]) -> void:
	var impact: Vector3 = AIM.impact_for_aim(0.4, 55.0)
	var human: Vector2i = AIM.human_gunner_correction(Vector2(impact.x, impact.z), -0.4, 55.0)
	var ai: Vector2i = AIM.ai_mortar_correction(0.4, 55.0, -0.4, 55.0)
	if human != ai or human != Vector2i(8, 0):
		failures.append("zero crossing human %s ai %s, expected (8, 0)" % [human, ai])
	expect_format(failures, human.x, human.y, "Right 8 mils")
