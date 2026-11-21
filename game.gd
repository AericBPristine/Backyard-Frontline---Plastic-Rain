extends Node3D

const TITLE_POSITION := Vector3(78, 92, -48)
const TITLE_LOOK := Vector3(-23, 28, -410)
const GUNNER_POSITION := Vector3(0, 2.55, 4.65)
const GUNNER_LOOK := Vector3(0, 1.32, -5.60)
const FIELD_OF_VIEW := 66.0
const GUNNER_FIRST_PERSON_FOV := 76.0
const FLY_IN_SECONDS := 2.65
const MAP_SIZE := 750.0
const MAP_CENTER := Vector3(0, 0, -359)
const OUTPOST_CENTER := Vector3(0, 0, -207)
const OUTPOST_HALF := Vector2(10, 5)
const BREACH_DISTANCE := 10.0
const GREEN_COUNT := 8
const WAVE_COUNTS := [5, 8, 12, 16, 20]
const INTERMISSION_SECONDS := 10.0
const RUNNER_DETAIL_DISTANCE := 145.0
const RUNNER_STARTS_PER_FRAME := 2
const TAN_START_Z := MAP_CENTER.z - MAP_SIZE * 0.5 + 12.0
const COVER_POSITIONS := [
	[Vector2(-28, -650), Vector2(0, -616), Vector2(29, -584)],
	[Vector2(-35, -501), Vector2(-5, -549), Vector2(31, -518)],
	[Vector2(-27, -438), Vector2(8, -393), Vector2(36, -461)],
	[Vector2(-32, -304), Vector2(0, -345), Vector2(22, -286)],
]
const AIM_WIDTH_STEP := 1.55
const AIM_BASE_DISTANCE := 70.0
const AIM_DEPTH_STEP := 7.65
const MILS_PER_TURN := 6400
const AZIMUTH_MILS_PER_STEP := 10
const ELEVATION_MILS_AT_ZERO := 480
const ELEVATION_MILS_PER_STEP := 12
const IMPACT_VIEW_SECONDS := 2.5
const SHOT_INTERVAL_SECONDS := 3.0
const CRATE_ROUNDS := 6
const RESUPPLY_SECONDS := 10.0
const AIRBURST_STOCK := 10
const AIRBURST_HEIGHT := 10.0
const AIRBURST_SPREAD := 22.0
const OBSERVER_ORIGIN := OUTPOST_CENTER + Vector3(0.8, 0, 2.9)
const OBSERVER_RADIUS := 0.27
const OBSERVER_SPEED := 4.5
const OBSERVER_DEFAULT_PITCH := -0.045
const BINOCULAR_ZOOMS := [2, 3, 4, 6, 8]
const IMPACT_FRAME_DISTANCE := 10.0
const IMPACT_CAMERA_OFFSET := Vector3(5.0, 6.1, 10.0)
const CRATER_SECONDS := 60.0
const MAX_CRATERS := 24
const FOREST_FLOOR := preload("res://art/woodland/forest_floor.tres")
const CRATER_ASSET := preload("res://art/woodland/impact_crater.gd")
const PINE_ASSET := preload("res://art/woodland/pine_mesh.gd")
const RIDGE_ASSET := preload("res://art/woodland/ridge_mesh.gd")
const LANDSCAPE_ASSET := preload("res://art/woodland/landscape.gd")
const OUTPOST_ASSET := preload("res://art/woodland/outpost.gd")
const TOY_SOLDIER := preload("res://art/figures/toy_soldier.gd")
const CREW_MOTION := preload("res://art/figures/crew_motion.gd")
const TOY_ROUND := preload("res://art/figures/toy_round.glb")
const MORTAR_BASE := preload("res://art/figures/mortar_player_mount.glb")
const MORTAR_TUBE := preload("res://art/figures/mortar_player_tube.glb")
const FALLEN_ASSET := preload("res://art/figures/fallen_figure.gd")
const IMPACT_ASSET := preload("res://art/effects/impact.gd")
const MUZZLE_ASSET := preload("res://art/effects/muzzle.gd")
const LAUNCH_SOUND := preload("res://art/effects/launch_close.wav")
const DISTANT_LAUNCH_SOUND := preload("res://art/effects/launch_distant.wav")
const DISTANT_LAUNCH_DELAY := 0.8
const IMPACT_SOUND := preload("res://art/effects/distant_impact.wav")
const CAMERA_IMPACT_SOUND := preload("res://art/effects/impact_camera.wav")
const TUBE_MOUTH := Vector3(0, 1.29, 0)
const BARREL_SEAT := Vector3(0, 0.052, 0)
const RECOIL_SETTLE_SECONDS := 0.28

var rng := RandomNumberGenerator.new()
var visual := RandomNumberGenerator.new()
var debris_random := RandomNumberGenerator.new()
var recoil_random := RandomNumberGenerator.new()
var world: Node3D
var actors: Node3D
var wave_reserve: Node3D
var runner_starts_left := RUNNER_STARTS_PER_FRAME
var runner_detail_distance_squared := RUNNER_DETAIL_DISTANCE * RUNNER_DETAIL_DISTANCE
var camera: Camera3D
var barrel: Node3D
var crew: Node3D
var crew_motion: RefCounted
var mortar_supports: Array[Node3D] = []
var hud: CanvasLayer
var materials: Dictionary = {}
var pine_variants: Array[ArrayMesh] = []
var forest_floor: ShaderMaterial
var crater_floor: ShaderMaterial
var mounds: Array[MeshInstance3D] = []
var craters: Array[Dictionary] = []
var tank_view := true
var heading := 0.0
var elevation := 55.0
var recoil_time := 0.0
var elapsed := 0.0
var cooldown := 0.0
var trigger_time := 0.0
var crate_rounds: Array[Node3D] = []
var rounds_ready := CRATE_ROUNDS
var resupply_time := 0.0
var airburst_left := AIRBURST_STOCK
var airburst_selected := false
var queued_airburst := false
var observer_unit: Node3D
var observing := false
var first_person := false
var binoculars := false
var binocular_zoom_index := 0
var outpost_obstacles: Array[Rect2] = []
var observer_yaw := 0.0
var observer_pitch := OBSERVER_DEFAULT_PITCH
var intermission_left := 0.0
var wave := 0
var kills := 0
var greens: Array[Node3D] = []
var tans: Array[Node3D] = []
var shots: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var follow: Dictionary = {}
var scout_yaw := 0.0
var scout_pitch := 0.0
var report := ""
var at_title := true
var fly_in_time := -1.0
var mouse_mode_before_pause := Input.MOUSE_MODE_VISIBLE
var playing := false
var launch_audio: AudioStreamPlayer
var distant_launch_audio: AudioStreamPlayer3D
var distant_launch_left := 0.0
var impact_audio: AudioStreamPlayer
var camera_impact_audio: AudioStreamPlayer
var rifle_pop: AudioStreamWAV

func _ready() -> void:
	visual.seed = 24321
	debris_random.randomize()
	recoil_random.randomize()
	world = Node3D.new()
	add_child(world)
	actors = Node3D.new()
	add_child(actors)
	wave_reserve = Node3D.new()
	wave_reserve.name = "Wave Reserve"
	wave_reserve.hide()
	add_child(wave_reserve)
	forest_floor = FOREST_FLOOR.duplicate() as ShaderMaterial
	forest_floor.set_shader_parameter("track_center", Vector2(-4.0, -465.0))
	forest_floor.set_shader_parameter("track_half_length", 256.0)
	crater_floor = forest_floor.duplicate() as ShaderMaterial
	crater_floor.set_shader_parameter("crater_surface", true)
	build_world()
	build_debris_floor()
	hud = preload("res://hud.gd").new()
	hud.game = self
	add_child(hud)
	launch_audio = AudioStreamPlayer.new()
	launch_audio.stream = LAUNCH_SOUND
	launch_audio.volume_db = -4.0
	launch_audio.max_polyphony = 3
	add_child(launch_audio)
	distant_launch_audio = AudioStreamPlayer3D.new()
	distant_launch_audio.stream = DISTANT_LAUNCH_SOUND
	distant_launch_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	distant_launch_audio.volume_db = -12.0
	distant_launch_audio.max_polyphony = 2
	add_child(distant_launch_audio)
	impact_audio = AudioStreamPlayer.new()
	impact_audio.stream = IMPACT_SOUND
	impact_audio.max_polyphony = 4
	add_child(impact_audio)
	camera_impact_audio = AudioStreamPlayer.new()
	camera_impact_audio.stream = CAMERA_IMPACT_SOUND
	camera_impact_audio.volume_db = -3.0
	add_child(camera_impact_audio)
	rifle_pop = make_rifle_pop()
	camera.position = TITLE_POSITION
	camera.look_at(TITLE_LOOK)
	hud.sync()

func surface(color: Color) -> StandardMaterial3D:
	if not materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.75
		materials[color] = material
	return materials[color]

func mesh_at(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.material_override = surface(color)
	parent.add_child(instance)
	return instance

func box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh_at(parent, shape, at, color)

func round_mesh(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radial_segments = 12
	shape.rings = 6
	var result := mesh_at(parent, shape, at, color)
	result.scale = size
	return result

func place_model(model: PackedScene, parent: Node3D, at: Vector3) -> Node3D:
	var instance := model.instantiate() as Node3D
	instance.position = at
	parent.add_child(instance)
	return instance

func build_debris_floor() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = FALLEN_ASSET.GROUND_PHYSICS_LAYER
	floor_body.collision_mask = 0
	floor_body.position = MAP_CENTER - Vector3.UP * 0.5
	add_child(floor_body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(MAP_SIZE, 1, MAP_SIZE)
	collision.shape = shape
	floor_body.add_child(collision)

func build_world() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#4899ed")
	sky_mat.sky_horizon_color = Color("#91d0ff")
	sky_mat.ground_horizon_color = Color("#91d0ff")
	sky_mat.ground_bottom_color = Color("#82abc4")
	environment.sky = Sky.new()
	environment.sky.sky_material = sky_mat
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#ecf4ff")
	environment.ambient_light_energy = 0.43
	environment.fog_enabled = true
	environment.fog_light_color = Color("#98b4b0")
	environment.fog_density = 0.0010
	environment.fog_sky_affect = 0.0
	var lighting := WorldEnvironment.new()
	lighting.environment = environment
	add_child(lighting)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -31, 0)
	sun.light_color = Color("#ffedc4")
	sun.light_energy = 0.67
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 210.0
	add_child(sun)
	camera = Camera3D.new()
	camera.fov = FIELD_OF_VIEW
	camera.far = 2200.0
	add_child(camera)
	var field := box(world, MAP_CENTER - Vector3.UP * 0.7, Vector3(MAP_SIZE, 1.4, MAP_SIZE), Color.WHITE)
	field.material_override = forest_floor
	LANDSCAPE_ASSET.build(world, MAP_CENTER, MAP_SIZE, forest_floor)
	for index in range(20):
		var x := visual.randf_range(-113, 113)
		var z := visual.randf_range(-215, 17)
		if z < -105 and absf(x) < 36:
			continue
		var mound := round_mesh(world, Vector3(x, -1.5, z), Vector3(visual.randf_range(15, 32), visual.randf_range(2, 9), visual.randf_range(12, 24)), Color.WHITE)
		mound.material_override = forest_floor
		mounds.append(mound)
	var ridge := mesh_at(world, RIDGE_ASSET.build(), RIDGE_ASSET.ORIGIN, Color.WHITE)
	ridge.material_override = forest_floor
	for variant in range(4):
		pine_variants.append(PINE_ASSET.build(variant))
	for index in range(13):
		var x := -31.0 + index * 5.2
		var z := -37.0 + visual.randf_range(-5.0, 5.0)
		var y := RIDGE_ASSET.height_at(Vector2(x - RIDGE_ASSET.ORIGIN.x, z - RIDGE_ASSET.ORIGIN.z))
		tree(Vector3(x, y, z), visual.randf_range(5.5, 8.8))
	for index in range(162):
		var x := visual.randf_range(-88, 88)
		var z := visual.randf_range(-88, -19)
		if index >= 80:
			x = visual.randf_range(57, 260) * (1 if index % 2 else -1)
			z = visual.randf_range(-706, -92)
		if absf(x + 7) > 5.0:
			tree(Vector3(x, 0, z), visual.randf_range(4.8, 12.4))
	for cluster in [Vector2(-8, -6), Vector2(9, -7), Vector2(-12, -15), Vector2(15, -21), Vector2(-30, -14), Vector2(31, -16)]:
		for index in range(5):
			var at := Vector3(cluster.x + visual.randf_range(-1.3, 1.3), visual.randf_range(-0.03, 0.18), cluster.y + visual.randf_range(-0.9, 0.9))
			var size := Vector3(visual.randf_range(0.45, 1.55), visual.randf_range(0.36, 0.92), visual.randf_range(0.64, 1.25))
			var rock := round_mesh(world, at, size, Color("#6b6959").lerp(Color("#999582"), visual.randf()))
			rock.rotation = Vector3(visual.randf_range(-0.3, 0.3), visual.randf() * TAU, visual.randf_range(-0.28, 0.28))
	for cloud_center in [
		Vector3(-68, 35, -141), Vector3(-27, 38, -167), Vector3(14, 51, -139),
		Vector3(58, 42, -177), Vector3(88, 28, -153), Vector3(-13, 35, -222),
		Vector3(35, 33, -222), Vector3(-63, 49, -301), Vector3(87, 47, -332),
	]:
		cloud(cloud_center, visual.randf_range(0.85, 1.45))
	build_outpost()
	build_cover()
	LANDSCAPE_ASSET.add_valley_boulders(world, ground_height)
	for row in range(2):
		for index in range(10 - row):
			var x := -3.24 + index * 0.72 + row * 0.36
			var bag := round_mesh(world, Vector3(x, 0.138 + row * 0.22, -3.5), Vector3(0.83, 0.28, 0.49), Color("#8f8662"))
			bag.rotation.y = visual.randf_range(-0.13, 0.13)
	build_ammo_crate()
	crew = Node3D.new()
	crew.name = "Mortar Crew"
	crew.position = Vector3(-0.68, 0.0, -0.18)
	world.add_child(crew)
	var figure := place_model(TOY_SOLDIER.RUNNER, crew, Vector3.ZERO)
	figure.rotation.y = PI
	var held_round := place_model(TOY_ROUND, crew, Vector3.ZERO)
	crew_motion = CREW_MOTION.new(figure, held_round)
	var mount := place_model(MORTAR_BASE, world, Vector3.ZERO)
	mortar_supports.assign([mount.get_node("LeftSupport"), mount.get_node("RightSupport")])
	mortar_supports[0].position = Vector3(-0.36, 0.025, -0.57)
	mortar_supports[1].position = Vector3(0.36, 0.025, -0.57)
	barrel = place_model(MORTAR_TUBE, world, BARREL_SEAT)
	update_barrel()
	crew_motion.pose(0.0, barrel.to_global(TUBE_MOUTH), barrel.global_basis.y.normalized())

func build_cover() -> void:
	for line in range(COVER_POSITIONS.size()):
		var section: Array = COVER_POSITIONS[line]
		for lane in range(section.size()):
			var at: Vector2 = section[lane]
			var cover := box(world, Vector3(at.x, 0.62, at.y), Vector3(10.8, 1.24, 1.12), Color("#8f8b73"))
			cover.name = "Cover %d-%d" % [line + 1, lane + 1]
			box(world, Vector3(at.x, 1.28, at.y), Vector3(11.0, 0.16, 1.32), Color("#a69e83"))
		var side := -1.0 if line % 2 == 0 else 1.0
		var flank: Vector2 = section.front() if side < 0.0 else section.back()
		var shed := flank + Vector2(side * 24.0, -11.0 if line < 2 else 13.0)
		box(world, Vector3(shed.x, 2.2, shed.y), Vector3(9, 4.4, 7), Color("#978d71"))
		box(world, Vector3(shed.x, 4.55, shed.y), Vector3(10, 0.55, 8), Color("#6c624e"))

func build_outpost() -> void:
	var hill_mesh := RIDGE_ASSET.build_surface(Vector2(78, 64), Vector2i(60, 42), OUTPOST_ASSET.height_at)
	var hill := mesh_at(world, hill_mesh, OUTPOST_CENTER, Color.WHITE)
	hill.name = "Outpost Hill"
	hill.material_override = forest_floor
	var body := StaticBody3D.new()
	body.collision_layer = FALLEN_ASSET.GROUND_PHYSICS_LAYER
	body.collision_mask = 0
	body.position = OUTPOST_CENTER
	var collision := CollisionShape3D.new()
	collision.shape = hill_mesh.create_trimesh_shape()
	body.add_child(collision)
	world.add_child(body)
	var plateau := OUTPOST_CENTER + Vector3.UP * OUTPOST_ASSET.height_at(Vector2.ZERO)
	var place_outpost_box := func(parent: Node3D, at: Vector3, size: Vector3, color: Color):
		var floor_height := at.y - plateau.y
		if floor_height + size.y * 0.5 > 0.24 and floor_height - size.y * 0.5 < 1.61:
			var footprint := Rect2(Vector2(at.x - size.x * 0.5, at.z - size.z * 0.5), Vector2(size.x, size.z))
			outpost_obstacles.append(footprint.grow(OBSERVER_RADIUS))
		return box(parent, at, size, color)
	OUTPOST_ASSET.build(world, plateau, OUTPOST_HALF, place_outpost_box)
	OUTPOST_ASSET.mark_perimeter(world, OUTPOST_CENTER, OUTPOST_HALF, BREACH_DISTANCE, ground_height)

func build_ammo_crate() -> void:
	var center := Vector3(-1.64, 0.0, 0.54)
	box(world, center + Vector3.UP * 0.21, Vector3(1.18, 0.42, 0.64), Color("#394c32"))
	for z in [-0.25, 0.25]:
		box(world, center + Vector3(0, 0.437, z), Vector3(1.12, 0.045, 0.064), Color("#637351"))
	for index in range(CRATE_ROUNDS):
		var at := center + Vector3((index - 2.5) * 0.168, 0.473, 0.0)
		var round_model := place_model(TOY_ROUND, world, at)
		round_model.rotation.x = -PI / 2.0
		crate_rounds.append(round_model)

func sync_crate() -> void:
	for index in range(crate_rounds.size()):
		crate_rounds[index].visible = index >= CRATE_ROUNDS - rounds_ready

func cloud(at: Vector3, size: float) -> void:
	var base := round_mesh(world, at, Vector3(26, 4, 9) * size, Color("#eef5ff"))
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for index in range(4):
		var offset := Vector3((index - 1.5) * 5.6, visual.randf_range(1.2, 3.6), visual.randf_range(-1.3, 1.3))
		var puff := round_mesh(world, at + offset * size, Vector3(10, visual.randf_range(4.5, 7.5), 8) * size, Color.WHITE)
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func tree(at: Vector3, height: float) -> void:
	var pine := MeshInstance3D.new()
	pine.mesh = pine_variants[visual.randi_range(0, pine_variants.size() - 1)]
	pine.position = at
	pine.scale = Vector3.ONE * height
	pine.rotation.y = visual.randf() * TAU
	world.add_child(pine)

func add_soldier(at: Vector3, tan: bool, armed: bool) -> Node3D:
	var unit := TOY_SOLDIER.new()
	unit.position = at
	actors.add_child(unit)
	unit.setup(tan, TOY_SOLDIER.Pose.STANDING if armed else TOY_SOLDIER.Pose.UNARMED)
	if armed:
		add_rifle_pop(unit)
	return unit

func prepare_wave_soldier(count: int) -> void:
	if wave_reserve.get_child_count() >= count:
		return
	var unit := TOY_SOLDIER.new()
	wave_reserve.add_child(unit)
	unit.setup(true, TOY_SOLDIER.Pose.STANDING)

func deploy_wave_soldier(at: Vector3) -> Node3D:
	if wave_reserve.get_child_count() == 0:
		return add_soldier(at, true, true)
	var unit := wave_reserve.get_child(0) as Node3D
	unit.reparent(actors, false)
	unit.position = at
	add_rifle_pop(unit)
	return unit

func begin_fly_in() -> void:
	if not at_title or fly_in_time >= 0.0:
		return
	fly_in_time = 0.0
	hud.begin_fly_in()

func fly_to_gunner(delta: float) -> void:
	fly_in_time = minf(fly_in_time + delta, FLY_IN_SECONDS)
	var progress := fly_in_time / FLY_IN_SECONDS
	var t := smoothstep(0.0, 1.0, progress)
	camera.position = TITLE_POSITION.bezier_interpolate(Vector3(53, 62, -25), Vector3(13, 14, 16), GUNNER_POSITION, t)
	var wide := Basis.looking_at(TITLE_LOOK - TITLE_POSITION)
	var gunner := Basis.looking_at(GUNNER_LOOK - GUNNER_POSITION)
	camera.basis = wide.slerp(gunner, t)
	hud.fade_title(progress)
	if progress >= 1.0:
		start_game()

func toggle_pause() -> bool:
	if get_tree().paused:
		resume_game()
		return true
	if not playing and not (at_title and fly_in_time >= 0.0):
		return false
	mouse_mode_before_pause = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	hud.show_pause()
	return true

func resume_game() -> void:
	get_tree().paused = false
	hud.hide_pause()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if observing else mouse_mode_before_pause

func quit_to_title() -> void:
	get_tree().paused = false
	playing = false
	at_title = true
	fly_in_time = -1.0
	observing = false
	first_person = false
	set_binoculars(false)
	observer_unit = null
	sync_player_visibility()
	clear_battlefield()
	launch_audio.stop()
	distant_launch_audio.stop()
	distant_launch_left = 0.0
	impact_audio.stop()
	camera_impact_audio.stop()
	camera.position = TITLE_POSITION
	camera.look_at(TITLE_LOOK)
	hud.show_title()
	hud.sync()

func clear_battlefield() -> void:
	for entry in actors.get_children():
		actors.remove_child(entry)
		entry.queue_free()
	greens.clear()
	tans.clear()
	shots.clear()
	effects.clear()
	craters.clear()
	update_cutouts()
	stop_following()

func start_game() -> void:
	at_title = false
	clear_battlefield()
	launch_audio.stop()
	distant_launch_audio.stop()
	distant_launch_left = 0.0
	camera_impact_audio.stop()
	rng.randomize()
	for index in range(GREEN_COUNT):
		var at := OUTPOST_CENTER + Vector3((index - 3.0) * 2.38, 0, -2.58 - (index % 2) * 0.45)
		if index == GREEN_COUNT - 1:
			at = OBSERVER_ORIGIN
		at.y = ground_height(Vector2(at.x, at.z))
		var armed := index < GREEN_COUNT - 1
		var unit := add_soldier(at, false, armed)
		if armed:
			unit.set_pose(TOY_SOLDIER.Pose.KNEELING)
		greens.append(unit)
	observer_unit = greens.back()
	observing = false
	first_person = false
	set_binoculars(false)
	binocular_zoom_index = 0
	observer_yaw = 0.0
	observer_pitch = OBSERVER_DEFAULT_PITCH
	tank_view = true
	heading = 0.0
	elevation = 55
	recoil_time = 0.0
	elapsed = 0.0
	cooldown = 0.0
	trigger_time = 0.0
	rounds_ready = CRATE_ROUNDS
	resupply_time = 0.0
	airburst_left = AIRBURST_STOCK
	airburst_selected = false
	queued_airburst = false
	sync_crate()
	crew_motion.reset()
	intermission_left = 0.0
	wave = 0
	kills = 0
	playing = true
	update_barrel()
	crew_camera(1.0)
	sync_player_visibility()
	hud.show_game()
	start_wave()

func start_wave() -> void:
	wave += 1
	intermission_left = 0.0
	var count: int = WAVE_COUNTS[wave - 1]
	var group_bias := rng.randf_range(-1.6, 1.6)
	for index in range(count):
		var lane := (index + wave - 1) % 3
		var lane_x: float = COVER_POSITIONS[0][lane].x
		var x := lane_x + rng.randf_range(-3.2, 3.2) + group_bias
		var z := TAN_START_Z - floori(index / 3.0) * 1.4 + rng.randf_range(-1.5, 1.5)
		var unit := deploy_wave_soldier(Vector3(x, ground_height(Vector2(x, z)), z))
		unit.rotation.y = PI
		unit.set_meta("kill_feed_label", "Tan rifleman")
		var cover_spread := rng.randf_range(-3.5, 3.5)
		var route: Array[Vector3] = []
		var exits: Array[Vector3] = []
		for section in COVER_POSITIONS:
			var cover: Vector2 = section[lane]
			var cover_z := cover.y - 1.35
			var covered_x := cover.x + cover_spread
			var exit_x := cover.x + (7.0 if cover_spread >= 0.0 else -7.0)
			route.append(Vector3(covered_x, ground_height(Vector2(covered_x, cover_z)), cover_z))
			exits.append(Vector3(exit_x, ground_height(Vector2(exit_x, cover_z)), cover_z))
		unit.set_meta("route", route)
		unit.set_meta("exits", exits)
		unit.set_meta("line", 0)
		unit.set_meta("cover_time", rng.randf_range(20.0, 30.0))
		unit.set_meta("flank", clampf(x * 0.33 + rng.randf_range(-3.0, 3.0), -8.5, 8.5))
		unit.set_meta("speed", rng.randf_range(2.48, 2.86))
		tans.append(unit)
	report = "Tans emerging from the north"
	hud.announce_wave(wave, false)

func azimuth_mils(value: float) -> int:
	return posmod(roundi(value * AZIMUTH_MILS_PER_STEP), MILS_PER_TURN)

func elevation_mils(value: float) -> int:
	return ELEVATION_MILS_AT_ZERO + roundi(value * ELEVATION_MILS_PER_STEP)

func update_barrel() -> void:
	var yaw := -heading * AZIMUTH_MILS_PER_STEP * TAU / MILS_PER_TURN
	var pitch := elevation_mils(elevation) * TAU / MILS_PER_TURN
	var kick := pow(recoil_time / RECOIL_SETTLE_SECONDS, 2.0)
	barrel.rotation = Vector3(pitch - PI * 0.5 + kick * 0.045, yaw, kick * 0.016)
	barrel.position = BARREL_SEAT - barrel.basis.y * (kick * 0.055)
	for support in mortar_supports:
		var side := signf(support.position.x)
		var joint := barrel.transform * Vector3(side * 0.046, 0.58, -0.006)
		var span := joint - support.position
		support.basis = Basis(Quaternion(Vector3.UP, span.normalized())).scaled_local(Vector3(1.0, span.length(), 1.0))
	crew.rotation.y = -0.71 + yaw * 0.72

func aim(change_x: float, change_y: float) -> void:
	if not playing:
		return
	heading = clampf(roundf((heading + change_x) * AZIMUTH_MILS_PER_STEP) / AZIMUTH_MILS_PER_STEP, -30.0, 30.0)
	elevation = clampf(roundf((elevation + change_y) * ELEVATION_MILS_PER_STEP) / ELEVATION_MILS_PER_STEP, 18.0, 88.0)
	update_barrel()

func recoil_offset(value: float, low: float, high: float, limit: int, mils_per_step: int) -> float:
	var offset := float(recoil_random.randi_range(1, limit)) / mils_per_step
	if recoil_random.randf() < 0.5:
		offset = -offset
	if value + offset < low or value + offset > high:
		offset = -offset
	return offset

func settle_after_shot() -> void:
	var elevation_edge := absf(elevation - 53.0) / 35.0
	var vertical_limit := 2 + roundi(elevation_edge * 3.0)
	var horizontal := recoil_offset(heading, -30.0, 30.0, 2, AZIMUTH_MILS_PER_STEP)
	var vertical := recoil_offset(elevation, 18.0, 88.0, vertical_limit, ELEVATION_MILS_PER_STEP)
	recoil_time = RECOIL_SETTLE_SECONDS
	aim(horizontal, vertical)

func set_view(shell_view: bool) -> void:
	if observing:
		return
	tank_view = shell_view
	if not tank_view:
		if not follow.is_empty():
			crew_camera(1.0)
		stop_following()
	elif not shots.is_empty():
		begin_following(shots.back())

func begin_following(shot: Dictionary) -> void:
	follow = shot
	scout_yaw = 0.0
	scout_pitch = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func stop_following() -> void:
	follow = {}
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func set_airburst(selected: bool) -> void:
	if playing and not observing and (not selected or airburst_left > 0):
		airburst_selected = selected

func can_fire() -> bool:
	return (playing and not get_tree().paused and not observing and rounds_ready > 0 and cooldown <= 0.0
		and trigger_time <= 0.0 and follow.is_empty())

func fire() -> void:
	if not can_fire():
		return
	queued_airburst = airburst_selected
	trigger_time = CREW_MOTION.RELEASE_SECONDS
	cooldown = SHOT_INTERVAL_SECONDS
	crew_motion.press()

func release_shot() -> void:
	rounds_ready -= 1
	sync_crate()
	if rounds_ready == 0:
		resupply_time = RESUPPLY_SECONDS
	if queued_airburst:
		airburst_left -= 1
		if airburst_left == 0:
			airburst_selected = false

	var target := Vector3(heading * AIM_WIDTH_STEP, 0.3, -AIM_BASE_DISTANCE - elevation * AIM_DEPTH_STEP)
	target.y = ground_height(Vector2(target.x, target.z)) + (AIRBURST_HEIGHT if queued_airburst else 0.3)
	var muzzle := barrel.to_global(TUBE_MOUTH)
	var launch_direction := barrel.global_basis.y.normalized()
	var visual_origin := muzzle + launch_direction * CREW_MOTION.ROUND_HALF_LENGTH
	var shell := place_model(TOY_ROUND, actors, visual_origin)
	shell.basis = Basis(Quaternion(Vector3.UP, launch_direction))
	# Preserve the gameplay arc and blend out the visual offset from the shorter prop.
	var flight_origin := Vector3(0, 0.3, 0) + barrel.global_basis * Vector3(0, 2.25, 0)
	var distance := Vector2(target.x - flight_origin.x, target.z - flight_origin.z).length()
	var span := clampf(distance / (AIM_BASE_DISTANCE + 88.0 * AIM_DEPTH_STEP), 0.0, 1.0)
	var shot := {
		"shell": shell, "origin": flight_origin, "muzzle_offset": visual_origin - flight_origin,
		"target": target, "time": 0.0, "length": lerpf(4.0, 12.0, span),
		"height": lerpf(44.0, 128.0, span), "airburst": queued_airburst
	}
	shots.append(shot)
	if tank_view and not observing and follow.is_empty():
		begin_following(shot)
	report = "Airburst away" if queued_airburst else "HE-PD away"
	var launch := MUZZLE_ASSET.new()
	launch.name = "Launch Puff"
	launch.position = muzzle
	launch.camera = camera
	launch.direction = launch_direction
	actors.add_child(launch)
	if not observing:
		launch_audio.play()
	distant_launch_audio.global_position = muzzle
	distant_launch_left = DISTANT_LAUNCH_DELAY
	settle_after_shot()

func observer_available() -> bool:
	return is_instance_valid(observer_unit) and greens.has(observer_unit)

func toggle_first_person() -> void:
	if not playing or not follow.is_empty():
		return
	first_person = not first_person
	if observing:
		if binoculars:
			set_binoculars(false)
		observer_camera(0.0)
	else:
		crew_camera(1.0)
	sync_player_visibility()

func sync_player_visibility() -> void:
	var through_eyes := playing and first_person and follow.is_empty()
	var gunner_eyes := through_eyes and not observing
	crew_motion.set_first_person_view(gunner_eyes)
	camera.fov = GUNNER_FIRST_PERSON_FOV if gunner_eyes else FIELD_OF_VIEW
	if binoculars:
		camera.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(FIELD_OF_VIEW * 0.5)) / binocular_zoom()))
	if observer_available():
		observer_unit.visible = not (observing and (through_eyes or binoculars))

func binocular_zoom() -> int:
	return BINOCULAR_ZOOMS[binocular_zoom_index]

func set_binoculars(active: bool) -> void:
	binoculars = active

func toggle_observer() -> void:
	if not playing or not observer_available():
		return
	observing = not observing
	stop_following()
	set_binoculars(false)
	if observing:
		launch_audio.stop()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		observer_camera(0.0)
	else:
		distant_launch_audio.stop()
		move_observer(Vector3.ZERO, 0.0)
		crew_camera(1.0)
	sync_player_visibility()

func observer_camera(delta: float) -> void:
	var look_keys := Vector2(
		float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP))
	)
	look_observer(look_keys * delta * 1.6)
	var movement := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	var facing := Basis(Vector3.UP, observer_yaw)
	move_observer(facing * Vector3(movement.x, 0.0, movement.y).limit_length(), delta)
	var offset := Vector3(0.0, 1.61, 0.0) if first_person or binoculars else Vector3(0.65, 2.9, 3.8)
	camera.position = observer_unit.position + facing * offset
	camera.basis = Basis.from_euler(Vector3(observer_pitch, observer_yaw, 0.0))

func look_observer(amount: Vector2) -> void:
	if binoculars:
		amount /= float(binocular_zoom())
	observer_yaw = wrapf(observer_yaw - amount.x, -PI, PI)
	observer_pitch = clampf(observer_pitch - amount.y, -0.85, 0.62)

func move_observer(direction: Vector3, delta: float) -> void:
	var before := observer_unit.position
	var center := Vector2(OUTPOST_CENTER.x, OUTPOST_CENTER.z)
	var area := Rect2(center - OUTPOST_HALF, OUTPOST_HALF * 2.0).grow(-OBSERVER_RADIUS)
	var current := Vector2(before.x, before.z)
	var desired := (current + Vector2(direction.x, direction.z) * OBSERVER_SPEED * delta).clamp(area.position, area.end)
	var bounded := slide_inside_outpost(current, desired.x, 0)
	bounded = slide_inside_outpost(bounded, desired.y, 1)
	var movement := bounded - current
	observer_unit.position = Vector3(bounded.x, ground_height(bounded), bounded.y)
	if movement.length_squared() > 0.000001:
		observer_unit.rotation.y = atan2(-movement.x, -movement.y)
		observer_unit.run_step(movement.length(), false)
	else:
		observer_unit.rotation.y = observer_yaw
		observer_unit.set_pose(TOY_SOLDIER.Pose.UNARMED)

func slide_inside_outpost(from: Vector2, destination: float, axis: int) -> Vector2:
	var cross_axis := 1 - axis
	for obstacle in outpost_obstacles:
		if from[cross_axis] <= obstacle.position[cross_axis] or from[cross_axis] >= obstacle.end[cross_axis]:
			continue
		if from[axis] <= obstacle.position[axis] and destination > from[axis]:
			destination = minf(destination, obstacle.position[axis])
		elif from[axis] >= obstacle.end[axis] and destination < from[axis]:
			destination = maxf(destination, obstacle.end[axis])
	from[axis] = destination
	return from

func crew_camera(weight: float) -> void:
	var aligned := Basis(Vector3.UP, barrel.rotation.y)
	var desired_position := aligned * GUNNER_POSITION
	var desired_look := aligned * GUNNER_LOOK
	if first_person and playing:
		desired_position = crew_motion.head_position() + aligned * Vector3(-0.035, 0.135, 0.10)
		var toward_tube := desired_position.direction_to(barrel.to_global(TUBE_MOUTH))
		desired_look = desired_position + (aligned * Vector3.FORWARD).lerp(toward_tube, 0.45) + Vector3.DOWN * 0.13
	var desired := Transform3D(Basis.looking_at(desired_look - desired_position), desired_position)
	camera.transform = camera.transform.interpolate_with(desired, weight)

func shot_camera(delta: float) -> void:
	var target: Vector3 = follow.target
	if follow.has("hold"):
		follow.hold -= delta
		if follow.hold <= 0.0:
			stop_following()
			crew_camera(1.0)
			return
		frame_impact(target)
		return
	var shell: Node3D = follow.shell
	if follow.has("framed") or shell.position.distance_to(target) <= IMPACT_FRAME_DISTANCE:
		frame_impact(target)
		return
	var t := clampf(follow.time / follow.length, 0, 1)
	var bearing: Vector3 = target - follow.origin
	bearing.y = 0.0
	bearing = bearing.normalized()
	camera.position = shell.position - bearing * lerpf(2.05, 2.45, t) + Vector3.UP * lerpf(1.13, 1.46, t)
	var look := shell.position + bearing * 0.66 - Vector3.UP * 0.26
	aim_scout_camera(look)

func frame_impact(target: Vector3) -> void:
	if not follow.has("framed"):
		follow.framed = true
		scout_yaw = 0.0
		scout_pitch = 0.0
	if follow.airburst:
		camera.position = target + Vector3(8, 6, 24)
		aim_scout_camera(target - Vector3.UP * 4.0)
	else:
		var terrain := ground_height(Vector2(target.x, target.z))
		camera.position = Vector3(target.x, terrain, target.z) + IMPACT_CAMERA_OFFSET
		aim_scout_camera(target)

func aim_scout_camera(look: Vector3) -> void:
	camera.look_at(look)
	camera.rotate(Vector3.UP, scout_yaw)
	camera.rotate_object_local(Vector3.RIGHT, scout_pitch)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not follow.is_empty() and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			stop_following()
			crew_camera(1.0)
			get_viewport().set_input_as_handled()
		elif observing and playing and observer_available():
			if event.button_index == MOUSE_BUTTON_RIGHT:
				set_binoculars(not binoculars)
				if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				get_viewport().set_input_as_handled()
			elif binoculars and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
				var step := 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1
				binocular_zoom_index = clampi(binocular_zoom_index + step, 0, BINOCULAR_ZOOMS.size() - 1)
				get_viewport().set_input_as_handled()
		return
	if not event is InputEventMouseMotion:
		return
	if observing and playing:
		look_observer(event.screen_relative * 0.004)
	elif not follow.is_empty():
		scout_yaw = clampf(scout_yaw - event.relative.x * 0.0036, -1.75, 1.75)
		scout_pitch = clampf(scout_pitch - event.relative.y * 0.0036, -0.82, 0.95)

func _unhandled_input(event: InputEvent) -> void:
	if observing and playing and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()

func flight(delta: float) -> void:
	for index in range(shots.size() - 1, -1, -1):
		var entry := shots[index]
		entry.time += delta
		var t := clampf(entry.time / entry.length, 0, 1)
		var target: Vector3 = entry.target
		var origin: Vector3 = entry.origin
		var muzzle_offset: Vector3 = entry.muzzle_offset
		var arc := origin.lerp(target, t) + Vector3.UP * (4.0 * t * (1.0 - t) * float(entry.height))
		var shell: Node3D = entry.shell
		var next_position := arc + muzzle_offset * (1.0 - smoothstep(0.0, 0.18, float(entry.time)))
		var travel := next_position - shell.position
		shell.position = next_position
		if not travel.is_zero_approx():
			shell.basis = Basis(Quaternion(Vector3.UP, travel.normalized()))
		if t >= 1.0:
			var watched := follow == entry
			if watched:
				follow.hold = IMPACT_VIEW_SECONDS
			detonate(target, entry.airburst, watched)
			entry.shell.queue_free()
			shots.remove_at(index)

func detonate(at: Vector3, airburst := false, watched := false) -> void:
	if watched and not airburst:
		camera_impact_audio.play()
	else:
		var listener_distance := camera.global_position.distance_to(at)
		impact_audio.volume_db = lerpf(-8.0, -23.0, clampf(listener_distance / 330.0, 0.0, 1.0))
		impact_audio.play()
	var burst := IMPACT_ASSET.new()
	burst.name = "Airburst" if airburst else "Impact"
	var center := Vector2(at.x, at.z)
	burst.position = Vector3(at.x, maxf(at.y, ground_height(center) + 0.1), at.z)
	burst.camera = camera
	burst.airburst = airburst
	if airburst:
		burst.fragment_spread = AIRBURST_SPREAD
		burst.floor_height = ground_height
	else:
		stamp_crater(center)
	actors.add_child(burst)
	var tan_hits := damage(tans, at, airburst)
	var green_hits := damage(greens, at, airburst)
	kills += tan_hits.x
	if tan_hits.x + green_hits.x:
		report = "%d Tans down • %d Greens lost" % [tan_hits.x, green_hits.x]
	elif tan_hits.y + green_hits.y:
		var hit_label := "Fragment hits" if airburst else "Splash hit"
		report = "%s • %d Tan / %d Green" % [hit_label, tan_hits.y, green_hits.y]
	elif tan_hits.z + green_hits.z:
		report = "Fragments chipped plastic"
	else:
		report = "No hits • adjust your aim"

func ground_height(at: Vector2) -> float:
	var top := RIDGE_ASSET.height_at(at - Vector2(RIDGE_ASSET.ORIGIN.x, RIDGE_ASSET.ORIGIN.z))
	top = maxf(top, OUTPOST_ASSET.height_at(at - Vector2(OUTPOST_CENTER.x, OUTPOST_CENTER.z)))
	for mound in mounds:
		var normalized := Vector2(
			(at.x - mound.position.x) / (mound.scale.x * 0.5),
			(at.y - mound.position.z) / (mound.scale.z * 0.5)
		)
		var cap := 1.0 - normalized.length_squared()
		if cap > 0.0:
			top = maxf(top, mound.position.y + sqrt(cap) * mound.scale.y * 0.5)
	return top

func stamp_crater(center: Vector2) -> void:
	for crater in craters:
		if center.distance_squared_to(crater.center) < pow(CRATER_ASSET.RADIUS * 1.15, 2.0):
			crater.time_left = CRATER_SECONDS
			return
	if craters.size() == MAX_CRATERS:
		var earliest := 0
		for index in range(1, craters.size()):
			if craters[index].time_left < craters[earliest].time_left:
				earliest = index
		craters[earliest].node.queue_free()
		craters.remove_at(earliest)
	var bowl := mesh_at(actors, CRATER_ASSET.build(center, ground_height), Vector3(center.x, 0, center.y), Color.WHITE)
	bowl.name = "Impact Crater"
	bowl.material_override = crater_floor
	craters.append({"center": center, "time_left": CRATER_SECONDS, "node": bowl})
	update_cutouts()

func update_cutouts() -> void:
	var openings := PackedVector3Array()
	openings.resize(MAX_CRATERS)
	for index in range(craters.size()):
		var center: Vector2 = craters[index].center
		openings[index] = Vector3(center.x, center.y, CRATER_ASSET.RADIUS)
	forest_floor.set_shader_parameter("crater_cutouts", openings)
	forest_floor.set_shader_parameter("crater_count", craters.size())

func advance_craters(delta: float) -> void:
	var count := craters.size()
	for index in range(count - 1, -1, -1):
		var crater := craters[index]
		crater.time_left -= delta
		if crater.time_left <= 0.0:
			crater.node.queue_free()
			craters.remove_at(index)
	if count != craters.size():
		update_cutouts()

func damage(team: Array[Node3D], at: Vector3, airburst := false) -> Vector3i:
	var hits := Vector3i.ZERO
	var reach := AIRBURST_SPREAD if airburst else 11.0
	for index in range(team.size() - 1, -1, -1):
		var unit := team[index]
		var distance := unit.position.distance_to(at)
		if airburst:
			distance = Vector2(unit.position.x, unit.position.z).distance_to(Vector2(at.x, at.z))
		if distance >= reach:
			if not airburst and maybe_chip_figure(unit, at, distance):
				hits.z += 1
			continue
		var health: float = unit.get_meta("health", 1.0)
		var falloff := 1.0 - distance / reach
		health -= 0.78 * falloff if airburst else 1.65 * pow(falloff, 0.84)
		if health <= 0.0:
			if unit.has_meta("kill_feed_label"):
				hud.add_kill(str(unit.get_meta("kill_feed_label")))
			drop_figure(unit, at, 1 if airburst else breakage_count(distance))
			unit.queue_free()
			team.remove_at(index)
			hits.x += 1
		else:
			unit.set_meta("health", health)
			hits.y += 1
			if not airburst and maybe_chip_figure(unit, at, distance):
				hits.z += 1
	return hits

func breakage_count(distance: float) -> int:
	if distance < 2.8:
		return 6
	if distance < 5.1:
		return 3
	if distance < 8.0:
		return 2
	return 1

func drop_figure(unit: Node3D, source: Vector3, breakage: int) -> void:
	var remains := FALLEN_ASSET.new()
	remains.name = "Fallen Figure"
	actors.add_child(remains)
	remains.drop(unit, source, breakage)

func maybe_chip_figure(unit: Node3D, source: Vector3, distance: float) -> bool:
	if distance < 8.5 or distance > 15.0 or unit.has_meta("missing_arm") or debris_random.randf() > 0.24:
		return false
	var shard := FALLEN_ASSET.new()
	shard.name = "Chipped Arm"
	actors.add_child(shard)
	if shard.knock_off_arm(unit, source):
		return true
	shard.queue_free()
	return false

func flash(at: Vector3, size: float, color: Color, duration: float) -> void:
	var cloud := round_mesh(actors, at, Vector3.ONE * 0.2, color)
	effects.append({"node": cloud, "time": 0.0, "length": duration, "size": size})

func update_effects(delta: float) -> void:
	for index in range(effects.size() - 1, -1, -1):
		var effect := effects[index]
		effect.time += delta
		var phase: float = effect.time / effect.length
		if phase >= 1.0:
			effect.node.queue_free()
			effects.remove_at(index)
		else:
			effect.node.scale = Vector3.ONE * sin(phase * PI) * effect.size

func move_tan(unit: Node3D, goal: Vector3, delta: float) -> void:
	var speed: float = unit.get_meta("speed")
	var before := Vector2(unit.position.x, unit.position.z)
	var next := before.move_toward(Vector2(goal.x, goal.z), speed * delta)
	var movement := next - before
	unit.position = Vector3(next.x, ground_height(next), next.y)
	if movement.length_squared() > 0.000001:
		unit.rotation.y = atan2(-movement.x, -movement.y)
		var near_view := camera.position.distance_squared_to(unit.position) <= runner_detail_distance_squared
		if near_view and (unit.runner or runner_starts_left > 0):
			if not unit.runner:
				runner_starts_left -= 1
			unit.run_step(movement.length(), true)
			return
	unit.set_pose(TOY_SOLDIER.Pose.STANDING)

func make_rifle_pop() -> AudioStreamWAV:
	var random := RandomNumberGenerator.new()
	random.seed = 6321
	const RATE := 22050
	var pcm := PackedByteArray()
	pcm.resize(int(RATE * 0.14) * 2)
	for index in range(pcm.size() / 2):
		var t := float(index) / RATE
		var tick := random.randf_range(-1.0, 1.0) * exp(-90.0 * t)
		var tap := sin(TAU * (290.0 * t - 170.0 * t * t)) * exp(-57.0 * t)
		pcm.encode_s16(index * 2, int((tick * 0.52 + tap * 0.34) * 24000.0))
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = RATE
	clip.data = pcm
	return clip

func add_rifle_pop(unit: Node3D) -> void:
	unit.set_meta("flash_time", rng.randf_range(0.45, 2.2))
	unit.set_meta("flash_hold", 0.0)
	var player := AudioStreamPlayer3D.new()
	player.name = "RiflePop"
	player.stream = rifle_pop
	player.position = unit.to_local(unit.muzzle_position())
	player.unit_size = 9.0
	player.max_distance = 220.0
	player.volume_db = -18.0
	unit.add_child(player)

func animate_rifle(unit: Node3D, delta: float) -> void:
	var remaining: float = unit.get_meta("flash_time") - delta
	var hold := maxf(float(unit.get_meta("flash_hold")) - delta, 0.0)
	var fires := remaining <= 0.0
	if fires:
		hold = 0.26
		remaining = rng.randf_range(1.65, 3.4)
	var raised := maxf(1.0 - smoothstep(0.0, 0.27, remaining), smoothstep(0.0, 0.22, hold))
	unit.set_pose(TOY_SOLDIER.Pose.STANDING if raised > 0.52 else TOY_SOLDIER.Pose.KNEELING)
	unit.set_meta("flash_time", remaining)
	unit.set_meta("flash_hold", hold)
	if fires:
		var sound: AudioStreamPlayer3D = unit.get_node("RiflePop")
		sound.position = unit.to_local(unit.muzzle_position())
		flash(sound.global_position, 0.57, Color("#ffe19c"), 0.12)
		if camera.global_position.distance_squared_to(sound.global_position) < 220.0 * 220.0:
			sound.play()

func breached(at: Vector3) -> bool:
	var relative := Vector2(at.x - OUTPOST_CENTER.x, at.z - OUTPOST_CENTER.z).abs()
	var from_wall := (relative - OUTPOST_HALF).max(Vector2.ZERO)
	return from_wall.length_squared() <= BREACH_DISTANCE * BREACH_DISTANCE

func finish_defense(won: bool) -> void:
	playing = false
	trigger_time = 0.0
	if not follow.has("hold"):
		stop_following()
	report = "Outpost secured" if won else "Tan breached the perimeter"
	hud.show_end(won)

func advance_battle(delta: float) -> void:
	if tans.is_empty():
		if wave == WAVE_COUNTS.size():
			finish_defense(true)
		elif intermission_left <= 0.0:
			intermission_left = INTERMISSION_SECONDS
			report = "Wave %d cleared" % wave
			hud.announce_wave(wave, true)
		else:
			prepare_wave_soldier(WAVE_COUNTS[wave])
			intermission_left = maxf(intermission_left - delta, 0.0)
			if intermission_left <= 0.0:
				start_wave()
		return

	runner_starts_left = RUNNER_STARTS_PER_FRAME
	var detail_distance := RUNNER_DETAIL_DISTANCE * (binocular_zoom() if binoculars else 1)
	runner_detail_distance_squared = detail_distance * detail_distance
	var defending := false
	for unit in tans:
		if breached(unit.position):
			finish_defense(false)
			return
		var line: int = unit.get_meta("line")
		if line < COVER_POSITIONS.size():
			var route: Array[Vector3] = unit.get_meta("route")
			var cover_time: float = unit.get_meta("cover_time")
			if cover_time > 0.0 and unit.position.is_equal_approx(route[line]):
				unit.rotation.y = PI
				unit.rotation.z = 0.0
				unit.set_meta("cover_time", maxf(cover_time - delta, 0.0))
				animate_rifle(unit, delta)
			elif cover_time > 0.0:
				move_tan(unit, route[line], delta)
			else:
				var exits: Array[Vector3] = unit.get_meta("exits")
				move_tan(unit, exits[line], delta)
				if unit.position.is_equal_approx(exits[line]):
					unit.set_meta("line", line + 1)
					unit.set_meta("cover_time", rng.randf_range(20.0, 30.0))
		else:
			var goal := OUTPOST_CENTER + Vector3(unit.get_meta("flank"), 0, -OUTPOST_HALF.y)
			move_tan(unit, goal, delta)
			if breached(unit.position):
				finish_defense(false)
				return
		defending = defending or unit.position.z > OUTPOST_CENTER.z - 155.0
	if defending:
		for unit in greens:
			if unit != observer_unit:
				animate_rifle(unit, delta)

func _process(delta: float) -> void:
	if at_title:
		prepare_wave_soldier(WAVE_COUNTS[0])
		if fly_in_time >= 0.0:
			fly_to_gunner(delta)
		return
	advance_craters(delta)
	if recoil_time > 0.0:
		recoil_time = maxf(0.0, recoil_time - delta)
		update_barrel()
	if playing:
		elapsed += delta
		cooldown = maxf(cooldown - delta, 0.0)
		if distant_launch_left > 0.0:
			distant_launch_left = maxf(0.0, distant_launch_left - delta)
			if distant_launch_left == 0.0 and observing and observer_available():
				distant_launch_audio.play()
		if resupply_time > 0.0:
			resupply_time = maxf(resupply_time - delta, 0.0)
			if resupply_time <= 0.0:
				rounds_ready = CRATE_ROUNDS
				sync_crate()
		if trigger_time > 0.0:
			trigger_time = maxf(0.0, trigger_time - delta)
			if trigger_time <= 0.0:
				release_shot()
		flight(delta)
		advance_battle(delta)
		update_effects(delta)
	crew_motion.pose(delta, barrel.to_global(TUBE_MOUTH), barrel.global_basis.y.normalized(), rounds_ready > 0)
	if observing and (not playing or not observer_available()):
		observing = false
		set_binoculars(false)
		distant_launch_audio.stop()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		crew_camera(1.0)
	if observing:
		observer_camera(delta)
	elif follow.is_empty():
		crew_camera(minf(delta * 5.0, 1.0))
	else:
		shot_camera(delta)
	sync_player_visibility()
	hud.sync(delta)
