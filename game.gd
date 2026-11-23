extends Node3D

enum MapVariant { WOODED_VALLEY, OPEN_FIELDS, PRACTICE_RANGE }

const TITLE_POSITION := Vector3(78, 92, -48)
const TITLE_LOOK := Vector3(-23, 28, -410)
const FIELDS_TITLE_POSITION := Vector3(67, 56, -119)
const FIELDS_TITLE_LOOK := Vector3(-12, 12, -307)
const GUNNER_POSITION := Vector3(0, 2.55, 4.65)
const GUNNER_LOOK := Vector3(0, 1.32, -5.60)
const FIELD_OF_VIEW := 66.0
const GUNNER_FIRST_PERSON_FOV := 76.0
const M16_ADS_FOV := 55.0
const M16_FOCUS_MAGNIFICATION := 1.35
const M16_FOCUS_SECONDS := 0.18
const SPRINT_SPEED_MULTIPLIER := 1.35
const OBSERVER_HOP_HEIGHT := 0.47
const OBSERVER_HOP_SECONDS := 0.44
const OBSERVER_KNEEL_DROP := 0.49
const OBSERVER_KNEEL_PACE := 0.52
const OBSERVER_LEAN_ANGLE := PI / 9.0
const OBSERVER_LEAN_DISTANCE := 0.26
const PRACTICE_RESPAWN_SECONDS := 5.0
const FLY_IN_SECONDS := 2.65
const MAP_SIZE := 750.0
const MAP_CENTER := Vector3(0, 0, -359)
const OUTPOST_CENTER := Vector3(0, 0, -207)
const OUTPOST_HALF := Vector2(10, 5)
const PRACTICE_DISTANCE := 150.0
const PRACTICE_TANS := 10
const PRACTICE_NEARBY_NOTICE := 8.0
const PRACTICE_START := Vector3(-96.0, 0.0, -470.0)
const PRACTICE_AREA := Rect2(-193.0, -651.0, 176.0, 231.0)
const PRACTICE_WANDER := Rect2(-149.0, -519.0, 87.0, 46.0)
const VILLAGE_PATROL := preload("res://art/woodland/village_patrol.gd")
const BREACH_DISTANCE := 10.0
const GREEN_COUNT := 8
const WAVE_COUNTS := [5, 8, 12, 16, 20]
const INTERMISSION_SECONDS := 10.0
const RUNNER_DETAIL_DISTANCE := 145.0
const RUNNER_STARTS_PER_FRAME := 2
const DODGE_SECONDS := 1.65
const FLINCH_SECONDS := 0.34
const NPC_RIFLE_REACH := 155.0
const NPC_RIFLE_DAMAGE := 0.2
const M16_LIMB_DAMAGE := 0.2
const M16_LOWER_TORSO_DAMAGE := 0.5
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
const ROUND_ROLL_SPEED := TAU / 4.0
const SHOT_INTERVAL_SECONDS := 3.0
const CRATE_ROUNDS := 6
const RESUPPLY_SECONDS := 10.0
const AIRBURST_STOCK := 10
const AIRBURST_HEIGHT := 10.0
const AIRBURST_SPREAD := 22.0
const OUTPOST_OBSERVER := OUTPOST_CENTER + Vector3(0.8, 0, 2.9)
const OBSERVER_RADIUS := 0.27
const OBSERVER_SPEED := 4.5
const OBSERVER_DEFAULT_PITCH := -0.045
const BINOCULAR_ZOOMS := [2, 3, 4, 6, 8]
const SNIPER_ZOOMS := [5, 10, 20]
const SNIPER_ZERO_STEP := 100
const SNIPER_ZERO_COUNT := 6
const OBSERVER_EYE_HEIGHT := 1.61
const IMPACT_FRAME_DISTANCE := 10.0
const IMPACT_CAMERA_OFFSET := Vector3(5.0, 6.1, 10.0)
const CRATER_SECONDS := 60.0
const MAX_CRATERS := 24
const VALLEY_PROPS := [
	[preload("res://art/woodland/props/brick_workshop.glb"), Vector2(-48, -660), -8.0],
	[preload("res://art/woodland/props/tool_shed.glb"), Vector2(51, -529), 13.0],
	[preload("res://art/woodland/props/one_story_cottage.glb"), Vector2(-47, -425), -12.0],
	[preload("res://art/woodland/props/concrete_bunker.glb"), Vector2(46, -273), 7.0],
]
const HILL_PROPS := [
	[preload("res://art/woodland/props/brick_workshop.glb"), Vector2(-23, -211), 9.0],
	[preload("res://art/woodland/props/one_story_cottage.glb"), Vector2(24, -202), -14.0],
]
const SMALL_PROPS := preload("res://art/woodland/props/small_props.glb")
const SUPPLY_CONTAINERS := [
	[&"BlueContainer", Vector2(-48, -673), -10.0],
	[&"OxideContainer", Vector2(-48, -435.6), -12.0],
	[&"OliveContainer", Vector2(46, -263), 7.0],
]
const SUPPLY_BARRIERS := [
	[&"ConcreteBarrierA", 0.0, [Vector2(-51.35, -677.2)]],
	[&"ConcreteBarrierB", 90.0, [Vector2(-53.55, -675), Vector2(-53.55, -670.55)]],
	[&"ConcreteBarrierC", 90.0, [Vector2(-53.3, -436.8), Vector2(-53.3, -432.35)]],
	[&"ConcreteBarrierD", 90.0, [Vector2(42, -262.7), Vector2(42, -258.25)]],
]

const SANDBAG_WALL := preload("res://art/woodland/props/sandbag_wall.glb")
const FOREST_FLOOR := preload("res://art/woodland/forest_floor.tres")
const CRATER_ASSET := preload("res://art/woodland/impact_crater.gd")
const PINE_ASSET := preload("res://art/woodland/pine_mesh.gd")
const LANDSCAPE_ASSET := preload("res://art/woodland/landscape.gd")
const VALLEY_GROUND := preload("res://art/woodland/valley_ground.gd")
const STORM_SKY := preload("res://art/woodland/storm_sky.gdshader")
const WEATHER_NOISE := preload("res://art/woodland/floor_noise.tres")
const OUTPOST_ASSET := preload("res://art/woodland/outpost.gd")
const ROADSIDE := preload("res://art/woodland/roadside_property.gd")
const VILLAGE := preload("res://art/woodland/pine_hollow.gd")
const TOY_SOLDIER := preload("res://art/figures/toy_soldier.gd")
const SNIPER_VIEW := preload("res://art/figures/sniper_view.gd")
const LOADOUT := preload("res://art/figures/player_loadout.gd")
const LOADOUT_INTERACTION_DISTANCE := 2.15
const OBSERVER_RADIO := preload("res://art/audio/observer_radio.gd")
const CREW_MOTION := preload("res://art/figures/crew_motion.gd")
const TOY_ROUND := preload("res://art/figures/toy_round.glb")
const TOY_MARKSMAN := preload("res://art/figures/toy_marksman.gd")
const MORTAR_BASE := preload("res://art/figures/mortar_player_mount.glb")
const MORTAR_TUBE := preload("res://art/figures/mortar_player_tube.glb")
const FALLEN_ASSET := preload("res://art/figures/fallen_figure.gd")
const IMPACT_ASSET := preload("res://art/effects/impact.gd")
const RIFLE_IMPACT := preload("res://art/effects/rifle_impact.gd")
const PROJECTILE_AUDIO := preload("res://art/effects/projectile_audio.gd")
const COOP_SESSION := preload("res://art/multiplayer/coop_session.gd")
const MUZZLE_ASSET := preload("res://art/effects/muzzle.gd")
const LAUNCH_SOUND := preload("res://art/effects/mortar_close_81.wav")
const SNIPER_SHOT_SOUND := preload("res://art/effects/sniper_shot.wav")
const M16_NEAR_SOUND := preload("res://art/effects/m16_near.wav")
const M16_DISTANT_SOUND := preload("res://art/effects/m16_distant.wav")
const M16_DISTANT_DISTANCE := 15.0
const M16_AUDIO_RANGE := 220.0
const SNIPER_CYCLE_SOUND := preload("res://art/effects/sniper_cycle.wav")
const DISTANT_LAUNCH_SOUND := preload("res://art/effects/mortar_distant_02.mp3")
const DISTANT_LAUNCH_DELAY := 0.8
const SETTINGS_PATH := "user://settings.cfg"
const MENU_MUSIC := preload("res://art/music/backyard_frontline_theme.ogg")
const BATTLEFIELD_MUSIC := preload("res://art/music/silent_march.ogg")
const DEFAULT_BATTLEFIELD_MUSIC_VOLUME := 0.15
const IMPACT_SOUND := preload("res://art/effects/distant_impact.wav")
const CAMERA_IMPACT_SOUND := preload("res://art/effects/thumpy_crackle_take_2.wav")
const TUBE_MOUTH := Vector3(0, 1.29, 0)
const BARREL_SEAT := Vector3(0, 0.052, 0)
const RECOIL_SETTLE_SECONDS := 0.28

var rng := RandomNumberGenerator.new()
var visual := RandomNumberGenerator.new()
var debris_random := RandomNumberGenerator.new()
var recoil_random := RandomNumberGenerator.new()
var map_variant := MapVariant.WOODED_VALLEY
var last_battle_map := MapVariant.WOODED_VALLEY
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
var valley_ground: VALLEY_GROUND
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
var sniper_mode := false
var loadout := LOADOUT.new()
var loadout_open := false
var supply_crate: MeshInstance3D
var m16_audio: AudioStreamPlayer
var sniper_scoped := false
var sniper_raise := 0.0
var m16_focus := 0.0
var sniper_zoom_index := 0
var sniper_zero_index := 0
var sniper_zero_offsets := PackedFloat32Array()
var sniper := TOY_MARKSMAN.new()
var projectile_audio := PROJECTILE_AUDIO.new()
var coop := COOP_SESSION.new()
var sniper_view: SNIPER_VIEW
var observer_radio: OBSERVER_RADIO
var sniper_audio: AudioStreamPlayer
var sniper_cycle_audio: AudioStreamPlayer
var gunner_first_person := false
var observer_first_person := true
var observer_hop_left := 0.0
var observer_kneeling := false
var observer_kneel := 0.0
var observer_lean := 0.0
var practice_invulnerable := true
var practice_respawn_left := 0.0
var binoculars := false
var binocular_zoom_index := 0
var outpost_obstacles: Array[Rect2] = []
var village_patrol: VILLAGE_PATROL
var patrols: Dictionary = {}
var observer_post_obstacles: Array[Rect2] = []
var free_look := false
var free_look_angles := Vector2.ZERO
var free_look_mouse_mode := Input.MOUSE_MODE_VISIBLE
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
var settings := ConfigFile.new()
var menu_music_volume := 1.0
var battlefield_music_volume := DEFAULT_BATTLEFIELD_MUSIC_VOLUME
var music_volume: float:
	get:
		return battlefield_music_volume if in_battlefield_music() else menu_music_volume
var music: AudioStreamPlayer
var launch_audio: AudioStreamPlayer
var distant_launch_audio: AudioStreamPlayer3D
var distant_launch_left := 0.0
var impact_audio: AudioStreamPlayer
var camera_impact_audio: AudioStreamPlayer

func _ready() -> void:
	debris_random.randomize()
	recoil_random.randomize()
	actors = Node3D.new()
	add_child(actors)
	projectile_audio.name = "Projectile Audio"
	add_child(projectile_audio)
	wave_reserve = Node3D.new()
	wave_reserve.name = "Wave Reserve"
	wave_reserve.hide()
	add_child(wave_reserve)
	build_scene()
	build_map()
	sniper_view = SNIPER_VIEW.new()
	add_child(sniper_view)
	observer_radio = OBSERVER_RADIO.new()
	observer_radio.game = self
	add_child(observer_radio)
	settings.load(SETTINGS_PATH)
	menu_music_volume = clampf(float(settings.get_value("audio", "music_volume", 1.0)), 0.0, 1.0)
	battlefield_music_volume = clampf(float(settings.get_value(
		"audio", "battlefield_music_volume", DEFAULT_BATTLEFIELD_MUSIC_VOLUME)), 0.0, 1.0)
	observer_radio.voice.input_device = String(settings.get_value("audio", "microphone_device", ""))
	coop.name = "PrivateCoop"
	coop.game = self
	add_child(coop)
	hud = preload("res://hud.gd").new()
	hud.game = self
	add_child(hud)
	music = AudioStreamPlayer.new()
	music.name = "Music"
	music.stream = MENU_MUSIC
	apply_music_volume()
	music.autoplay = true
	add_child(music)
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
	m16_audio = AudioStreamPlayer.new()
	m16_audio.stream = M16_NEAR_SOUND
	m16_audio.volume_db = -6.0
	m16_audio.max_polyphony = 2
	add_child(m16_audio)
	sniper_audio = AudioStreamPlayer.new()
	sniper_audio.stream = SNIPER_SHOT_SOUND
	sniper_audio.volume_db = -7.0
	add_child(sniper_audio)
	sniper_cycle_audio = AudioStreamPlayer.new()
	sniper_cycle_audio.stream = SNIPER_CYCLE_SOUND
	sniper_cycle_audio.volume_db = -7.0
	add_child(sniper_cycle_audio)
	frame_title_map()
	hud.sync()

func select_map(variant: MapVariant) -> void:
	if not at_title or fly_in_time >= 0.0 or map_variant == variant:
		return
	map_variant = variant
	sniper.cover.clear()
	outpost_obstacles.clear()
	observer_post_obstacles.clear()
	remove_child(world)
	world.queue_free()
	build_map()
	frame_title_map()
	hud.sync_map_selection()

func frame_title_map() -> void:
	var fields := map_variant != MapVariant.WOODED_VALLEY
	camera.position = FIELDS_TITLE_POSITION if fields else TITLE_POSITION
	camera.look_at(FIELDS_TITLE_LOOK if fields else TITLE_LOOK)

func in_battlefield_music() -> bool:
	return not at_title or fly_in_time >= 0.0

func set_music_volume(value: float) -> void:
	if in_battlefield_music():
		battlefield_music_volume = clampf(value, 0.0, 1.0)
	else:
		menu_music_volume = clampf(value, 0.0, 1.0)
	apply_music_volume()

func apply_music_volume() -> void:
	music.volume_db = linear_to_db(maxf(music_volume, 0.0001))

func save_music_settings() -> void:
	var key := "battlefield_music_volume" if in_battlefield_music() else "music_volume"
	var default := DEFAULT_BATTLEFIELD_MUSIC_VOLUME if in_battlefield_music() else 1.0
	if is_equal_approx(float(settings.get_value("audio", key, default)), music_volume):
		return
	settings.set_value("audio", key, music_volume)
	if settings.save(SETTINGS_PATH) != OK:
		push_warning("Could not save music volume.")

func select_microphone(device: String) -> void:
	if observer_radio.voice.input_device == device:
		return
	observer_radio.voice.input_device = device
	settings.set_value("audio", "microphone_device", device)
	if settings.save(SETTINGS_PATH) != OK:
		push_warning("Could not save the microphone choice.")

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

func build_debris_floor(terrain_mesh: ArrayMesh) -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Ground Collision"
	floor_body.collision_layer = FALLEN_ASSET.GROUND_PHYSICS_LAYER
	floor_body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.shape = terrain_mesh.create_trimesh_shape()
	floor_body.add_child(collision)
	world.add_child(floor_body)

func build_scene() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = STORM_SKY
	sky_mat.set_shader_parameter("weather_noise", WEATHER_NOISE)
	environment.sky = Sky.new()
	environment.sky.sky_material = sky_mat
	environment.sky.radiance_size = Sky.RADIANCE_SIZE_64
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c3cdce")
	environment.ambient_light_energy = 0.50
	environment.fog_enabled = true
	environment.fog_light_color = Color("#9daaad")
	environment.fog_density = 0.00168
	environment.fog_sky_affect = 0.0
	var lighting := WorldEnvironment.new()
	lighting.environment = environment
	add_child(lighting)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -31, 0)
	sun.light_color = Color("#dce0dd")
	sun.light_energy = 0.42
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 210.0
	add_child(sun)
	camera = Camera3D.new()
	camera.fov = FIELD_OF_VIEW
	camera.far = 2200.0
	add_child(camera)
	for variant in range(4):
		pine_variants.append(PINE_ASSET.build(variant))

func build_map() -> void:
	world = Node3D.new()
	world.name = "Battlefield"
	supply_crate = null
	village_patrol = null
	add_child(world)
	visual.seed = 24321
	var practice := is_practice()
	var open_fields := map_variant != MapVariant.WOODED_VALLEY
	var props := VALLEY_PROPS + HILL_PROPS if open_fields else VALLEY_PROPS
	forest_floor = FOREST_FLOOR.duplicate() as ShaderMaterial
	valley_ground = VALLEY_GROUND.new(Vector2(MAP_CENTER.x, MAP_CENTER.z), MAP_SIZE * 0.5,
		Vector2(OUTPOST_CENTER.x, OUTPOST_CENTER.z), [] if practice else COVER_POSITIONS,
		VILLAGE.LOTS if practice else props + SUPPLY_CONTAINERS + VILLAGE.LOTS, open_fields, practice)
	forest_floor.set_shader_parameter("surface_map", valley_ground.paint_texture())
	forest_floor.set_shader_parameter("surface_center", Vector2(MAP_CENTER.x, MAP_CENTER.z))
	forest_floor.set_shader_parameter("surface_size", MAP_SIZE)
	crater_floor = forest_floor.duplicate() as ShaderMaterial
	crater_floor.set_shader_parameter("crater_surface", true)
	var terrain_mesh := valley_ground.build_mesh()
	var field := mesh_at(world, terrain_mesh, Vector3.ZERO, Color.WHITE)
	field.name = "Valley Ground"
	field.material_override = forest_floor
	build_debris_floor(terrain_mesh)
	LANDSCAPE_ASSET.build(world, MAP_CENTER, MAP_SIZE, forest_floor, open_fields, practice)
	if practice:
		build_practice_village()
	else:
		build_outpost()
		build_battlefield_props(open_fields, props)
		build_mortar_position()

func build_battlefield_props(open_fields: bool, props: Array) -> void:
	if not open_fields:
		build_valley_pines()
	for cluster in [Vector2(-8, -6), Vector2(9, -7), Vector2(-12, -15), Vector2(15, -21), Vector2(-30, -14), Vector2(31, -16)]:
		for index in range(5):
			var at := Vector3(cluster.x + visual.randf_range(-1.3, 1.3), visual.randf_range(-0.03, 0.18), cluster.y + visual.randf_range(-0.9, 0.9))
			var size := Vector3(visual.randf_range(0.45, 1.55), visual.randf_range(0.36, 0.92), visual.randf_range(0.64, 1.25))
			var rock := round_mesh(world, at, size, Color("#6b6959").lerp(Color("#999582"), visual.randf()))
			rock.rotation = Vector3(visual.randf_range(-0.3, 0.3), visual.randf() * TAU, visual.randf_range(-0.28, 0.28))
	build_woodland(open_fields)
	build_cover()
	LANDSCAPE_ASSET.add_valley_boulders(world, ground_height)
	build_map_props(props)

func build_practice_village() -> void:
	var props := Node3D.new()
	props.name = "Map Props"
	world.add_child(props)
	build_pine_hollow(props)
	village_patrol = VILLAGE_PATROL.new()
	village_patrol.setup(PRACTICE_AREA, props, OBSERVER_RADIUS)
	barrel = null
	crew_motion = null
	mortar_supports.clear()
	crate_rounds.clear()

func build_mortar_position() -> void:
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

func build_valley_pines() -> void:
	for index in range(13):
		var x := -31.0 + index * 5.2
		var z := -37.0 + visual.randf_range(-5.0, 5.0)
		var y := ground_height(Vector2(x, z))
		tree(Vector3(x, y, z), visual.randf_range(5.5, 8.8))
	for index in range(162):
		var x := visual.randf_range(-88, 88)
		var z := visual.randf_range(-88, -19)
		if index >= 80:
			x = visual.randf_range(57, 260) * (1 if index % 2 else -1)
			z = visual.randf_range(-706, -92)
		if absf(x + 7) > 5.0:
			var height := visual.randf_range(4.8, 12.4)
			var at := Vector2(x, z)
			if not observer_clearing(at) and not ROADSIDE.inside_clearing(at) and not VILLAGE.CLEARING.has_point(at):
				tree(Vector3(at.x, ground_height(at), at.y), height)
			else:
				# Keep the existing woodland's random sequence for skipped trees.
				visual.randi_range(0, pine_variants.size() - 1)
				visual.randf()

func build_cover() -> void:
	var source := SANDBAG_WALL.instantiate() as Node3D
	var meshes := source.find_children("*", "MeshInstance3D", true, false)
	var model := source as MeshInstance3D if source is MeshInstance3D else meshes[0] as MeshInstance3D
	var sandbags := MultiMesh.new()
	sandbags.transform_format = MultiMesh.TRANSFORM_3D
	sandbags.mesh = model.mesh
	sandbags.instance_count = valley_ground.stations.size() * 2
	var index := 0
	for at in valley_ground.stations:
		for offset in [-2.37, 2.37]:
			var position := at + Vector2(offset, 0)
			var floor_point := Vector3(position.x, ground_height(position), position.y)
			sandbags.set_instance_transform(index, Transform3D(Basis.IDENTITY, floor_point) * model.transform)
			index += 1
	source.free()
	var wall := MultiMeshInstance3D.new()
	wall.name = "Valley Sandbag Positions"
	wall.multimesh = sandbags
	world.add_child(wall)


func build_woodland(open_fields: bool) -> void:
	# The denser belt sits south of the outpost. More open groups break up
	# the valley while leaving the main lanes and tracks visible.
	var clusters := [
		[Vector2(-28, -180), Vector2(18, 13), 15],
		[Vector2(-49, -164), Vector2(19, 12), 12],
		[Vector2(25, -179), Vector2(17, 12), 16],
		[Vector2(50, -161), Vector2(18, 14), 11],
		[Vector2(-21, -153), Vector2(13, 13), 10],
		[Vector2(21, -148), Vector2(13, 12), 9],
		[Vector2(-66, -335), Vector2(14, 19), 9],
		[Vector2(62, -370), Vector2(12, 19), 10],
		[Vector2(-14, -350), Vector2(9, 15), 7],
		[Vector2(22, -407), Vector2(9, 15), 7],
		[Vector2(-19, -473), Vector2(8, 14), 6],
		[Vector2(13, -565), Vector2(9, 15), 8],
		[Vector2(-62, -606), Vector2(11, 19), 8],
	]
	if open_fields:
		clusters = [
			[Vector2(-28, -39), Vector2(12, 5), 3],
			[Vector2(34, -45), Vector2(13, 6), 3],
			[Vector2(-38, -191), Vector2(14, 7), 4],
			[Vector2(36, -187), Vector2(13, 7), 4],
			[Vector2(-56, -308), Vector2(12, 15), 4],
			[Vector2(58, -382), Vector2(13, 17), 3],
			[Vector2(-65, -496), Vector2(13, 14), 4],
			[Vector2(60, -555), Vector2(10, 13), 3],
			[Vector2(-58, -630), Vector2(11, 16), 4],
		]
	var summit := VALLEY_GROUND.OBSERVER_POST
	clusters.append_array([
		[summit + Vector2(21, 22), Vector2(16, 15), 17],
		[summit + Vector2(-10, 30), Vector2(24, 15), 20],
		[summit + Vector2(23, -23), Vector2(16, 14), 18],
		[summit + Vector2(2, -38), Vector2(13, 28), 19],
		[summit + Vector2(52, 0), Vector2(22, 32), 29],
		[summit + Vector2(33, 46), Vector2(30, 27), 24],
		[summit + Vector2(-68, -12), Vector2(21, 54), 29],
		[summit + Vector2(8, -75), Vector2(35, 21), 24],
		[summit + Vector2(-28, 67), Vector2(28, 19), 20],
	])
	for band in range(12):
		var z := -690.0 + band * 59.0
		var west := 184.0 + sin(band * 2.25) * 24.0
		var east := 329.0 + cos(band * 1.62) * 10.0
		clusters.append([Vector2(west, z), Vector2(41.0, 40.0), 17 if open_fields else 23])
		clusters.append([Vector2(east, z + 11.0), Vector2(23.0, 33.0), 11 if open_fields else 15])
	var forest := RandomNumberGenerator.new()
	forest.seed = 91342
	var trees: Array[Transform3D] = []
	var planted: Array[Vector2] = []
	for cluster in clusters:
		var center: Vector2 = cluster[0]
		var spread: Vector2 = cluster[1]
		var count: int = cluster[2]
		var accepted := 0
		for _attempt in range(count * 6):
			if accepted >= count:
				break
			var angle := forest.randf() * TAU
			var offset := Vector2(cos(angle), sin(angle)) * sqrt(forest.randf()) * spread
			var at := center + offset
			if not woodland_space(at, planted):
				continue
			planted.append(at)
			var pos := Vector3(at.x, ground_height(at), at.y)
			trees.append(LANDSCAPE_ASSET.pine_transform(pos, forest.randf_range(6.4, 13.6), forest.randf() * TAU))
			accepted += 1
	var woodland := Node3D.new()
	woodland.name = "Valley Woodland"
	world.add_child(woodland)
	for variant in range(pine_variants.size()):
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = pine_variants[variant]
		batch.instance_count = range(variant, trees.size(), pine_variants.size()).size()
		for i in range(batch.instance_count):
			batch.set_instance_transform(i, trees[variant + i * pine_variants.size()])
		var pines := MultiMeshInstance3D.new()
		pines.multimesh = batch
		pines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		woodland.add_child(pines)

func observer_clearing(at: Vector2) -> bool:
	var local := at - VALLEY_GROUND.OBSERVER_POST
	return local.length_squared() < 13.0 * 13.0 \
		or Rect2(-58.0, -62.0, 58.0, 82.0).has_point(local)

func woodland_space(at: Vector2, planted: Array[Vector2]) -> bool:
	if valley_ground.on_road(at) or observer_clearing(at) or ROADSIDE.inside_clearing(at) \
			or VILLAGE.CLEARING.has_point(at):
		return false
	if at.y > -204.0 and absf(at.x) < 11.0:
		return false
	for pad in valley_ground.pads:
		if at.distance_squared_to(pad) < 77.0:
			return false
	for station in valley_ground.stations:
		if at.distance_squared_to(station) < 91.0:
			return false
	for other in planted:
		if at.distance_squared_to(other) < 12.5:
			return false
	return true

func build_map_props(buildings: Array) -> void:
	var props := Node3D.new()
	props.name = "Map Props"
	world.add_child(props)
	for prop in buildings:
		var at: Vector2 = prop[1]
		var model := place_model(prop[0], props, Vector3(at.x, ground_height(at), at.y))
		model.rotation_degrees.y = prop[2]
	var crew_wall := place_model(SANDBAG_WALL, props, Vector3(0, ground_height(Vector2(0, -3.5)), -3.5))
	crew_wall.name = "Mortar Sandbag Wall"
	build_small_props(props)
	build_observer_post(props)
	ROADSIDE.build(props, ground_height)
	build_loadout_crate(props)

func build_pine_hollow(props: Node3D) -> void:
	VILLAGE.build(props, ground_height)
	for pine: Vector3 in VILLAGE.PINES:
		tree(Vector3(pine.x, ground_height(Vector2(pine.x, pine.z)), pine.z), pine.y)

func build_loadout_crate(parent: Node3D) -> void:
	var kit := ROADSIDE.KIT.instantiate()
	var at := Vector2(OUTPOST_CENTER.x - 2.3, OUTPOST_CENTER.z + 2.1)
	supply_crate = ROADSIDE.place(kit, parent, &"SupplyCase", at, 14.0, ground_height)
	supply_crate.name = "Outpost Supply Crate"
	kit.free()
	var bounds := supply_crate.global_transform * supply_crate.get_aabb()
	outpost_obstacles.append(obstacle_footprint(bounds.get_center(), Vector2(bounds.size.x, bounds.size.z)))

func build_observer_post(parent: Node3D) -> void:
	var center := VALLEY_GROUND.OBSERVER_POST
	var half := VALLEY_GROUND.OBSERVER_HALF
	var post := Node3D.new()
	post.name = "East Mountain Observer Post"
	parent.add_child(post)
	post.position = Vector3(center.x, ground_height(center), center.y)
	# Low bags leave the open viewing side clear above the perimeter.
	var edge := half.x - 0.24
	var section := half.x * 0.47
	var offsets := [
		Vector2(-edge, -section), Vector2(-edge, section), Vector2(edge, -section),
		Vector2(-section, -edge), Vector2(section, -edge), Vector2(-section, edge),
	]
	for index in range(offsets.size()):
		var offset: Vector2 = offsets[index]
		var wall := place_model(SANDBAG_WALL, post, Vector3(offset.x, 0.0, offset.y))
		wall.rotation.y = PI * 0.5 if index < 3 else 0.0
		wall.scale.y = 1.46
		var bags := wall.get_node("sandbag_wall") as MeshInstance3D
		var bounds := bags.global_transform * bags.get_aabb()
		observer_post_obstacles.append(obstacle_footprint(bounds.get_center(), Vector2(bounds.size.x, bounds.size.z)))

func build_small_props(parent: Node3D) -> void:
	var kit := place_model(SMALL_PROPS, parent, Vector3.ZERO)
	kit.name = "Small Props"
	for prop in SUPPLY_CONTAINERS:
		var model: Node3D = kit.get_node(NodePath(prop[0]))
		place_supply_prop(model, prop[1], prop[2])
	for fence in SUPPLY_BARRIERS:
		var section: MeshInstance3D = kit.get_node(NodePath(fence[0]))
		var positions: Array = fence[2]
		place_supply_prop(section, positions[0], fence[1])
		for index in range(1, positions.size()):
			var extra := section.duplicate() as MeshInstance3D
			kit.add_child(extra)
			place_supply_prop(extra, positions[index], fence[1])

	var west := kit.get_node("TimberTower") as MeshInstance3D
	var east := west.duplicate() as MeshInstance3D
	kit.add_child(east)
	west.name = "West Outpost Tower"
	east.name = "East Outpost Tower"
	var towers := [west, east]
	for index in range(towers.size()):
		var tower: MeshInstance3D = towers[index]
		var side := -1.0 if index == 0 else 1.0
		var at := OUTPOST_CENTER + Vector3(side * 7.2, 0, 2.38)
		at.y = ground_height(Vector2(at.x, at.z))
		tower.position = at
		# The model's +X ladder side rotates to +Z (south).
		tower.rotation_degrees.y = -90.0
		for foot in [Vector2(-1.11, -1.11), Vector2(-1.11, 1.11), Vector2(1.11, -1.11), Vector2(1.11, 1.11), Vector2(1.11, 0.04)]:
			var base := tower.to_global(Vector3(foot.x, 0, foot.y))
			outpost_obstacles.append(obstacle_footprint(base, Vector2(0.22, 0.22)))

	var crates := kit.get_node("TimberCrates") as MeshInstance3D
	var crate_pos := OUTPOST_CENTER + Vector3(4.5, 0, 2.65)
	crate_pos.y = ground_height(Vector2(crate_pos.x, crate_pos.z))
	crates.position = crate_pos
	crates.rotation_degrees.y = -17.0
	var footprint := crates.global_transform * crates.get_aabb()
	outpost_obstacles.append(obstacle_footprint(footprint.get_center(), Vector2(footprint.size.x, footprint.size.z)))

func place_supply_prop(model: Node3D, at: Vector2, heading_degrees: float) -> void:
	model.position = Vector3(at.x, ground_height(at), at.y)
	model.rotation_degrees.y = heading_degrees

func obstacle_footprint(at: Vector3, size: Vector2) -> Rect2:
	var footprint := Rect2(Vector2(at.x, at.z) - size * 0.5, size)
	return footprint.grow(OBSERVER_RADIUS)


func build_outpost() -> void:
	var plateau := OUTPOST_CENTER + Vector3.UP * ground_height(Vector2(OUTPOST_CENTER.x, OUTPOST_CENTER.z))
	var place_outpost_box := func(parent: Node3D, at: Vector3, size: Vector3, color: Color):
		var floor_height := at.y - plateau.y
		if floor_height + size.y * 0.5 > 0.24 and floor_height - size.y * 0.5 < 1.61:
			outpost_obstacles.append(obstacle_footprint(at, Vector2(size.x, size.z)))
		var prop := box(parent, at, size, color)
		var concrete: bool = color == OUTPOST_ASSET.CONCRETE or color == OUTPOST_ASSET.EDGE
		prop.set_meta("impact_material", &"concrete" if concrete else &"dirt")
		return prop
	OUTPOST_ASSET.build(world, plateau, OUTPOST_HALF, place_outpost_box)
	if not is_practice():
		OUTPOST_ASSET.mark_perimeter(world, OUTPOST_CENTER, OUTPOST_HALF, BREACH_DISTANCE, ground_height)

func build_ammo_crate() -> void:
	crate_rounds.clear()
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

func tree(at: Vector3, height: float) -> void:
	var pine := MeshInstance3D.new()
	pine.mesh = pine_variants[visual.randi_range(0, pine_variants.size() - 1)]
	pine.position = at
	pine.scale = Vector3.ONE * height
	pine.rotation.y = visual.randf() * TAU
	world.add_child(pine)

func add_soldier(at: Vector3, tan: bool, armed: bool, marksman := false) -> Node3D:
	var unit := TOY_SOLDIER.new()
	if marksman:
		unit.name = "Green Sniper"
	unit.position = at
	actors.add_child(unit)
	unit.setup(tan, TOY_SOLDIER.Pose.STANDING if armed else TOY_SOLDIER.Pose.UNARMED, marksman)
	if armed and not marksman and not (is_practice() and not tan):
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

func is_practice() -> bool:
	return map_variant == MapVariant.PRACTICE_RANGE

func begin_practice() -> void:
	if not at_title or fly_in_time >= 0.0:
		return
	last_battle_map = map_variant
	select_map(MapVariant.PRACTICE_RANGE)
	begin_fly_in(true)

func begin_fly_in(play_sniper := false) -> void:
	if not at_title or fly_in_time >= 0.0:
		return
	sniper_mode = play_sniper
	fly_in_time = 0.0
	if sniper_mode or is_practice():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	music.stream = BATTLEFIELD_MUSIC
	apply_music_volume()
	music.play()
	hud.begin_fly_in()

func fly_to_gunner(delta: float) -> void:
	fly_in_time = minf(fly_in_time + delta, FLY_IN_SECONDS)
	var progress := fly_in_time / FLY_IN_SECONDS
	var t := smoothstep(0.0, 1.0, progress)
	var end := GUNNER_POSITION
	var end_basis := Basis.looking_at(GUNNER_LOOK - GUNNER_POSITION)
	var approach := Vector3(13, 14, 16)
	if sniper_mode or is_practice():
		end = observer_spawn() + Vector3.UP * 1.61
		end_basis = Basis.from_euler(Vector3(OBSERVER_DEFAULT_PITCH, 0, 0))
		approach = end + Vector3(10, 36, 18)
	var fields := map_variant != MapVariant.WOODED_VALLEY
	var start := FIELDS_TITLE_POSITION if fields else TITLE_POSITION
	var first_turn := Vector3(46, 42, -124) if fields else Vector3(53, 62, -25)
	camera.position = start.bezier_interpolate(first_turn, approach, end, t)
	var wide := Basis.looking_at((FIELDS_TITLE_LOOK if fields else TITLE_LOOK) - start)
	camera.basis = wide.slerp(end_basis, t)
	hud.fade_title(progress)
	if progress >= 1.0:
		start_game()

func toggle_pause() -> bool:
	if coop.in_match():
		hud.coop_lobby.toggle_match_menu()
		return true
	if get_tree().paused:
		resume_game()
		return true
	if not playing and not (at_title and fly_in_time >= 0.0):
		return false
	end_free_look()
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
	end_free_look()
	m16_audio.stop()
	get_tree().paused = false
	playing = false
	at_title = true
	fly_in_time = -1.0
	sniper_mode = false
	sniper_scoped = false
	sniper_raise = 0.0
	m16_focus = 0.0
	sniper_audio.stop()
	sniper_cycle_audio.stop()
	observing = false
	gunner_first_person = false
	observer_first_person = true
	set_binoculars(false)
	observer_unit = null
	sync_player_visibility()
	clear_battlefield()
	launch_audio.stop()
	distant_launch_audio.stop()
	distant_launch_left = 0.0
	impact_audio.stop()
	camera_impact_audio.stop()
	if is_practice():
		select_map(last_battle_map)
	frame_title_map()
	hud.show_title()
	hud.sync()
	music.stream = MENU_MUSIC
	apply_music_volume()
	music.play()

func clear_battlefield() -> void:
	close_loadout()
	loadout = LOADOUT.new()
	sniper.clear()
	projectile_audio.stop_all()
	sniper_view.clear()
	observer_radio.clear()
	for entry in actors.get_children():
		actors.remove_child(entry)
		entry.queue_free()
	greens.clear()
	tans.clear()
	patrols.clear()
	practice_respawn_left = 0.0
	reset_observer_posture()
	shots.clear()
	effects.clear()
	craters.clear()
	update_cutouts()
	stop_following()

func uses_mountain_post() -> bool:
	return not sniper_mode and not is_practice()

func observer_spawn() -> Vector3:
	var spawn := OUTPOST_OBSERVER
	if is_practice():
		spawn = PRACTICE_START
	elif uses_mountain_post():
		var post := VALLEY_GROUND.OBSERVER_POST
		spawn = Vector3(post.x - 2.75, 0.0, post.y - 1.10)
	elif map_variant == MapVariant.OPEN_FIELDS:
		spawn = OUTPOST_CENTER + Vector3(0.8, 0.0, -3.85)
	spawn.y = ground_height(Vector2(spawn.x, spawn.z))
	return spawn

func start_coop_game(observer: bool, map: int) -> void:
	select_map(MapVariant.OPEN_FIELDS if map == MapVariant.OPEN_FIELDS else MapVariant.WOODED_VALLEY)
	sniper_mode = false
	fly_in_time = -1.0
	start_game()
	tank_view = false
	if observer:
		toggle_observer_for_local_role()
	if coop.guest_match():
		for unit in greens.duplicate():
			if unit != observer_unit:
				greens.erase(unit)
				unit.queue_free()
	music.stream = BATTLEFIELD_MUSIC
	apply_music_volume()
	music.play()
	hud.sync()

func coop_controls_locked() -> bool:
	return coop.in_match() and hud.coop_lobby.match_menu_open

func make_coop_round_visual(pose: Transform3D) -> Dictionary:
	var shell := place_model(TOY_ROUND, actors, pose.origin)
	shell.transform = pose
	return {"node": shell, "goal": pose}

func start_game() -> void:
	at_title = false
	sniper_mode = sniper_mode or is_practice()
	clear_battlefield()
	launch_audio.stop()
	distant_launch_audio.stop()
	distant_launch_left = 0.0
	camera_impact_audio.stop()
	rng.randomize()
	for index in range(GREEN_COUNT - 1 if is_practice() else 0, GREEN_COUNT):
		var at := OUTPOST_CENTER + Vector3((index - 3.0) * 2.38, 0, -2.58 - (index % 2) * 0.45)
		if index == GREEN_COUNT - 1:
			at = observer_spawn()
		else:
			at.y = ground_height(Vector2(at.x, at.z))
		var armed := index < GREEN_COUNT - 1
		var marksman := sniper_mode and not armed and not is_practice()
		var unit := add_soldier(at, false, armed or sniper_mode, marksman)
		if armed:
			unit.set_pose(TOY_SOLDIER.Pose.KNEELING)
		greens.append(unit)
	observer_unit = greens.back()
	observing = sniper_mode
	sniper_scoped = false
	sniper_raise = 0.0
	m16_focus = 0.0
	sniper_zoom_index = 0
	sniper_zero_index = 0
	gunner_first_person = false
	observer_first_person = true
	set_binoculars(false)
	binocular_zoom_index = 0
	observer_yaw = 0.0
	observer_pitch = OBSERVER_DEFAULT_PITCH
	if uses_mountain_post():
		var vista := Vector2(0.0, -455.0)
		var look := (Vector3(vista.x, ground_height(vista), vista.y) - observer_unit.position \
			- Vector3.UP * OBSERVER_EYE_HEIGHT).normalized()
		observer_yaw = atan2(-look.x, -look.z)
		observer_pitch = asin(look.y)
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
	if crew_motion:
		crew_motion.reset()
	intermission_left = 0.0
	wave = 0
	kills = 0
	playing = true
	if barrel:
		update_barrel()
	sniper.reset(world, valley_ground.stations, ground_height)
	projectile_audio.load_clips()
	if is_practice():
		loadout.slots[0] = LOADOUT.Item.M16
	if sniper_mode:
		if not is_practice():
			sniper_zero_offsets = sniper.sight_offsets(SNIPER_ZERO_STEP, SNIPER_ZERO_COUNT)
		sniper_view.equip(observer_unit.poses[TOY_SOLDIER.Pose.STANDING], is_practice())
	if observing:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		observer_camera(0.0)
	else:
		crew_camera(1.0)
	sync_player_visibility()
	hud.show_game()
	if is_practice():
		start_village_patrols()
	elif not coop.guest_match():
		start_wave()

func start_village_patrols() -> void:
	report = ""
	for index in range(PRACTICE_TANS):
		var at := Vector2(PRACTICE_START.x + (index % 5 - 2) * 6.0,
			PRACTICE_START.z - PRACTICE_DISTANCE - floorf(index / 5.0) * 2.0)
		var unit := deploy_wave_soldier(Vector3(at.x, ground_height(at), at.y))
		unit.rotation.y = PI
		unit.set_meta("kill_feed_label", "Tan rifleman")
		unit.set_meta("speed", rng.randf_range(2.65, 3.15))
		var goal := Vector2(-145.0 + (index % 5) * 18.5, -476.0 + floorf(index / 5.0) * 1.5)
		patrols[unit] = {
			"path": village_patrol.route(at, goal), "waypoint": 0, "idle": 0.0,
			"look_timer": index * 0.02, "sees_player": false,
			"activity": VILLAGE_PATROL.Activity.ROAM,
		}
		tans.append(unit)

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
	if not playing or coop_controls_locked():
		return
	if coop.guest_match():
		coop.send_gunner_command("aim", change_x, change_y)
		return
	apply_gunner_aim(change_x, change_y)

func apply_gunner_aim(change_x: float, change_y: float) -> void:
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
	apply_gunner_aim(horizontal, vertical)

func set_view(shell_view: bool) -> void:
	if observing or coop.in_match():
		return
	tank_view = shell_view
	if not tank_view:
		if not follow.is_empty():
			crew_camera(1.0)
		stop_following()
	elif not shots.is_empty():
		begin_following(shots.back())

func begin_following(shot: Dictionary) -> void:
	end_free_look()
	follow = shot
	scout_yaw = 0.0
	scout_pitch = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func stop_following() -> void:
	follow = {}
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func set_airburst(selected: bool) -> void:
	if not playing or observing or coop_controls_locked() or (selected and airburst_left <= 0):
		return
	if coop.guest_match():
		coop.send_gunner_command("effect", float(selected))
	else:
		airburst_selected = selected

func can_fire() -> bool:
	return not observing and not observer_radio.busy() and rounds_ready > 0 and mortar_ready()

func mortar_ready() -> bool:
	return playing and is_instance_valid(barrel) and not get_tree().paused and cooldown <= 0.0 and trigger_time <= 0.0 and follow.is_empty()

func fire() -> void:
	if not can_fire() or coop_controls_locked():
		return
	if coop.guest_match():
		coop.send_gunner_command("fire")
	else:
		press_mortar(airburst_selected)

func queue_radio_round() -> bool:
	if not mortar_ready():
		return false
	press_mortar(false)
	return true

func cancel_pending_radio_round() -> void:
	trigger_time = 0.0
	cooldown = 0.0
	crew_motion.reset()

func press_mortar(airburst: bool) -> void:
	queued_airburst = airburst
	trigger_time = CREW_MOTION.RELEASE_SECONDS
	cooldown = SHOT_INTERVAL_SECONDS
	crew_motion.press()

func release_shot() -> void:
	var radio_round := observer_radio.pending
	if not radio_round:
		rounds_ready -= 1
		sync_crate()
		if rounds_ready == 0:
			resupply_time = RESUPPLY_SECONDS
	if queued_airburst:
		airburst_left -= 1
		if airburst_left == 0:
			airburst_selected = false

	var radio_order := 0
	var target := Vector3(heading * AIM_WIDTH_STEP, 0.3, -AIM_BASE_DISTANCE - elevation * AIM_DEPTH_STEP)
	if radio_round:
		var point := observer_radio.round_target()
		target = Vector3(point.x, 0.3, point.y)
		radio_order = observer_radio.released()
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
		"height": lerpf(44.0, 128.0, span), "airburst": queued_airburst, "radio_order": radio_order
	}
	shots.append(shot)
	if tank_view and not radio_round and not observing and follow.is_empty():
		begin_following(shot)
	report = "Airburst away" if queued_airburst else "HE-PD away"
	paint_launch(muzzle, launch_direction)
	coop.send_launch(muzzle, launch_direction)
	settle_after_shot()

func paint_launch(muzzle: Vector3, launch_direction: Vector3) -> void:
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

func observer_available() -> bool:
	return is_instance_valid(observer_unit) and greens.has(observer_unit)

func can_use_loadout() -> bool:
	return playing and sniper_mode and observing and observer_available()

func near_loadout_crate() -> bool:
	return can_use_loadout() and is_instance_valid(supply_crate) \
		and observer_unit.global_position.distance_squared_to(supply_crate.global_position) < pow(LOADOUT_INTERACTION_DISTANCE, 2.0)

func toggle_loadout() -> bool:
	if loadout_open:
		close_loadout()
		return true
	if not near_loadout_crate() or get_tree().paused:
		return false
	end_free_look()
	loadout_open = true
	sniper_scoped = false
	sniper_raise = 0.0
	m16_focus = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	sync_player_visibility()
	hud.sync()
	return true

func close_loadout() -> void:
	if not loadout_open:
		return
	loadout_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if can_use_loadout() else Input.MOUSE_MODE_VISIBLE
	hud.sync()

func select_loadout_slot(index: int) -> void:
	if not can_use_loadout() or index < 0 or index >= LOADOUT.SLOT_COUNT:
		return
	var previous := loadout.equipped()
	loadout.selected = index
	refresh_equipped_item(previous)

func move_loadout_item(item: int, from_slot: int, to_slot: int) -> void:
	if not loadout_open or not can_use_loadout():
		return
	var previous := loadout.equipped()
	loadout.move_item(item, from_slot, to_slot)
	refresh_equipped_item(previous)

func refresh_equipped_item(previous: LOADOUT.Item) -> void:
	var current := loadout.equipped()
	if current != previous:
		sniper.cancel_reload()
		sniper_scoped = false
		sniper_raise = 0.0
		m16_focus = 0.0
		sniper.kick_left = 0.0
		if current == LOADOUT.Item.EMPTY:
			sniper_view.clear()
		else:
			observer_unit.equip_rifle(current == LOADOUT.Item.M40)
			sniper_view.equip(observer_unit.poses[TOY_SOLDIER.Pose.STANDING], current == LOADOUT.Item.M16)
		observer_camera(0.0)
		sync_player_visibility()
	hud.sync()

func toggle_first_person() -> void:
	if not playing or not follow.is_empty() or loadout_open or practice_respawn_left > 0.0:
		return
	if observing:
		observer_first_person = not observer_first_person
		sniper_scoped = false
		if binoculars:
			set_binoculars(false)
		observer_camera(0.0)
	else:
		gunner_first_person = not gunner_first_person
		crew_camera(1.0)
	sync_player_visibility()

func sync_player_visibility() -> void:
	var can_use_eyes := playing and follow.is_empty()
	var gunner_eyes := can_use_eyes and not observing and gunner_first_person
	if crew_motion:
		crew_motion.set_first_person_view(gunner_eyes)
	camera.fov = GUNNER_FIRST_PERSON_FOV if gunner_eyes else FIELD_OF_VIEW
	var rifle_fov := SNIPER_VIEW.BASE_FOV
	if sniper_scope_visible():
		camera.fov = optic_fov(sniper_zoom())
	elif sniper_mode and not free_look and loadout.equipped() == LOADOUT.Item.M16:
		var focus_amount := smoothstep(0.0, 1.0, m16_focus) * sniper_raise
		var magnification := lerpf(1.0, M16_FOCUS_MAGNIFICATION, focus_amount)
		camera.fov = optic_fov(magnification, lerpf(FIELD_OF_VIEW, M16_ADS_FOV, sniper_raise))
		rifle_fov = optic_fov(magnification, rifle_fov)
	elif binoculars_visible():
		camera.fov = optic_fov(binocular_zoom())
	sniper_view.camera.fov = rifle_fov
	var observer_eyes := observing and (observer_first_person or sniper_raise > 0.0 or binoculars)
	if observer_available():
		observer_unit.visible = not (can_use_eyes and observer_eyes)
	sniper_view.set_active(can_use_eyes and sniper_mode and observer_eyes
		and loadout.equipped() != LOADOUT.Item.EMPTY and not sniper_scope_visible())

func binoculars_visible() -> bool:
	return binoculars and not free_look

func sniper_scope_visible() -> bool:
	return not free_look and sniper_scoped and sniper_raise >= 0.99 and loadout.equipped() == LOADOUT.Item.M40

func binocular_zoom() -> int:
	return BINOCULAR_ZOOMS[binocular_zoom_index]

func sniper_zoom() -> int:
	return SNIPER_ZOOMS[sniper_zoom_index]

func sniper_zero_distance() -> int:
	return SNIPER_ZERO_STEP * (sniper_zero_index + 1)

func adjust_sniper_zero(step: int) -> void:
	if not playing or get_tree().paused or not sniper_scoped or not observer_available() \
		or loadout.equipped() != LOADOUT.Item.M40:
		return
	sniper_zero_index = clampi(sniper_zero_index + step, 0, sniper_zero_offsets.size() - 1)
	observer_camera(0.0)
	hud.sync()

func optic_fov(magnification: float, base_fov := FIELD_OF_VIEW) -> float:
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(base_fov * 0.5)) / magnification))

func set_binoculars(active: bool) -> void:
	binoculars = active

func toggle_observer() -> void:
	if not playing or sniper_mode or is_practice() or not observer_available() or coop.in_match():
		return
	toggle_observer_for_local_role()

func toggle_observer_for_local_role() -> void:
	end_free_look()
	observing = not observing
	stop_following()
	set_binoculars(false)
	if observing:
		launch_audio.stop()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		observer_camera(0.0)
	else:
		distant_launch_audio.stop()
		observer_radio.voice.cancel()
		reset_observer_posture()
		move_observer(Vector3.ZERO, 0.0)
		crew_camera(1.0)
	sync_player_visibility()

func observer_camera(delta: float) -> void:
	var movement := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	var lean := float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q))
	var controls_locked: bool = hud.radio_typing() or loadout_open or coop_controls_locked()
	if controls_locked:
		movement = Vector2.ZERO
		lean = 0.0
	observer_hop_left = maxf(0.0, observer_hop_left - delta)
	var kneel: bool = observer_kneeling and observer_hop_left <= 0.0
	observer_kneel = move_toward(observer_kneel, 1.0 if kneel else 0.0, delta * 7.5)
	observer_lean = move_toward(observer_lean, lean, delta * 6.5)
	var facing := Basis(Vector3.UP, observer_yaw)
	var sprint: bool = not kneel and observer_kneel <= 0.0 and not sniper_scoped \
		and sniper_raise <= 0.0 and not binoculars and Input.is_physical_key_pressed(KEY_SHIFT)
	var pace := SPRINT_SPEED_MULTIPLIER if sprint else lerpf(1.0, OBSERVER_KNEEL_PACE, observer_kneel)
	var travel := move_observer(facing * Vector3(movement.x, 0.0, movement.y).limit_length(), delta, pace)
	camera.position = observer_eye_position()
	if not observer_first_person and not binoculars:
		var third_person := Vector3(0.95, 2.14, 2.85) if sniper_mode else Vector3(0.65, 2.9, 3.8)
		var orbit := facing.rotated(Vector3.UP, free_look_angles.x)
		camera.position += orbit * (third_person - Vector3.UP * OBSERVER_EYE_HEIGHT) \
			* (1.0 - smoothstep(0.0, 1.0, sniper_raise))
	var rotation := Vector3(observer_pitch, observer_yaw, 0.0)
	if sniper_mode:
		if sniper_scope_visible() and sniper_zero_index < sniper_zero_offsets.size():
			rotation.x -= sniper_zero_offsets[sniper_zero_index]
		var kick := pow(sniper.kick_left / TOY_MARKSMAN.KICK_SECONDS, 2.0)
		var dip := 0.0
		var progress := 0.0
		if sniper.reload_left > 0.0:
			progress = 1.0 - sniper.reload_left / sniper.reload_duration(sniper.reload_weapon)
		elif loadout.equipped() == LOADOUT.Item.M40 and sniper.action == TOY_MARKSMAN.Action.CYCLING:
			progress = 1.0 - sniper.cycle_left / TOY_MARKSMAN.CYCLE_SECONDS
		dip = smoothstep(0.0, 0.24, progress) * (1.0 - smoothstep(0.55, 1.0, progress))
		var scale := float(SNIPER_ZOOMS[0]) / sniper_zoom() if sniper_scope_visible() else 1.0
		rotation += Vector3(0.083 * kick - 0.052 * dip, -0.010 * kick, 0.034 * dip) * scale
		sniper_view.pose(delta, travel, kick, dip, sniper_raise)
	var head_offset := free_look_basis()
	var tilt := Basis(Vector3.BACK, -observer_lean * OBSERVER_LEAN_ANGLE)
	camera.basis = Basis.from_euler(rotation) * head_offset * tilt
	sniper_view.set_view(head_offset)

func free_look_basis() -> Basis:
	return Basis.from_euler(Vector3(free_look_angles.y, free_look_angles.x, 0.0))

func begin_free_look() -> void:
	if free_look or not playing or get_tree().paused or not follow.is_empty() or loadout_open or hud.radio_typing():
		return
	if observing and not observer_available():
		return
	free_look = true
	free_look_mouse_mode = Input.mouse_mode
	if not observing:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	sync_player_visibility()
	hud.sync()

func end_free_look() -> void:
	if not free_look:
		return
	free_look = false
	free_look_angles = Vector2.ZERO
	Input.mouse_mode = free_look_mouse_mode
	if observing and observer_available():
		observer_camera(0.0)
	elif barrel:
		crew_camera(1.0)
	sync_player_visibility()
	hud.sync()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		end_free_look()

func look_observer(amount: Vector2) -> void:
	if sniper_scope_visible():
		amount /= float(sniper_zoom())
	elif binoculars:
		amount /= float(binocular_zoom())
	observer_yaw = wrapf(observer_yaw - amount.x, -PI, PI)
	observer_pitch = clampf(observer_pitch - amount.y, -0.85, 0.62)

func reset_observer_posture() -> void:
	observer_hop_left = 0.0
	observer_kneeling = false
	observer_kneel = 0.0
	observer_lean = 0.0

func observer_walk_obstacles() -> Array[Rect2]:
	if is_practice():
		return village_patrol.walk_obstacles
	return observer_post_obstacles if uses_mountain_post() else outpost_obstacles

func observer_eye_position() -> Vector3:
	var eyes := observer_unit.global_position + Vector3.UP * (OBSERVER_EYE_HEIGHT - observer_kneel * OBSERVER_KNEEL_DROP)
	if not is_zero_approx(observer_lean):
		var side := Basis(Vector3.UP, observer_yaw) * Vector3.RIGHT * (OBSERVER_LEAN_DISTANCE * observer_lean)
		var position := Vector2(eyes.x, eyes.z)
		var obstacles := observer_walk_obstacles()
		var leaned := slide_observer(position, position.x + side.x, 0, obstacles)
		leaned = slide_observer(leaned, position.y + side.z, 1, obstacles)
		eyes.x = leaned.x
		eyes.z = leaned.y
	return eyes

func hop_observer() -> void:
	if playing and observing and observer_available() and not loadout_open \
		and not observer_kneeling and observer_kneel <= 0.0 and observer_hop_left <= 0.0:
		observer_hop_left = OBSERVER_HOP_SECONDS

func move_observer(direction: Vector3, delta: float, pace := 1.0) -> float:
	var before := observer_unit.position
	var summit := uses_mountain_post()
	var center := VALLEY_GROUND.OBSERVER_POST if summit else Vector2(OUTPOST_CENTER.x, OUTPOST_CENTER.z)
	var half := VALLEY_GROUND.OBSERVER_HALF if summit else OUTPOST_HALF
	var obstacles := observer_walk_obstacles()
	var area := (PRACTICE_AREA if is_practice() else Rect2(center - half, half * 2.0)).grow(-OBSERVER_RADIUS)
	var current := Vector2(before.x, before.z)
	var desired := (current + Vector2(direction.x, direction.z) * (OBSERVER_SPEED * pace * delta)).clamp(area.position, area.end)
	var bounded := slide_observer(current, desired.x, 0, obstacles)
	bounded = slide_observer(bounded, desired.y, 1, obstacles)
	var movement := bounded - current
	var carrying := sniper_mode and loadout.equipped() != LOADOUT.Item.EMPTY
	var hop_progress := observer_hop_left / OBSERVER_HOP_SECONDS
	var hop := 4.0 * OBSERVER_HOP_HEIGHT * hop_progress * (1.0 - hop_progress)
	observer_unit.position = Vector3(bounded.x, ground_height(bounded) + hop, bounded.y)
	observer_unit.rotation.z = -observer_lean * OBSERVER_LEAN_ANGLE
	if observer_kneel >= 0.5:
		observer_unit.rotation.y = observer_yaw
		observer_unit.set_pose(TOY_SOLDIER.Pose.KNEELING)
		var kneeling_rifle := observer_unit.poses[TOY_SOLDIER.Pose.KNEELING].get_node_or_null("Rifle") as Node3D
		if kneeling_rifle:
			kneeling_rifle.visible = carrying
	elif movement.length_squared() > 0.000001 and not (sniper_mode and sniper_scoped):
		observer_unit.rotation.y = atan2(-movement.x, -movement.y)
		observer_unit.run_step(movement.length(), carrying)
	else:
		observer_unit.rotation.y = observer_yaw
		if carrying:
			var kick := sniper.kick_left / TOY_MARKSMAN.KICK_SECONDS
			observer_unit.rifle_pose(sniper_raise, 0.0, kick)
		else:
			observer_unit.set_pose(TOY_SOLDIER.Pose.UNARMED)
	return movement.length()

func slide_observer(from: Vector2, destination: float, axis: int, obstacles: Array[Rect2]) -> Vector2:
	var cross_axis := 1 - axis
	for obstacle in obstacles:
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
	if gunner_first_person and playing:
		desired_position = crew_motion.head_position() + aligned * Vector3(-0.035, 0.135, 0.10)
		var toward_tube := desired_position.direction_to(barrel.to_global(TUBE_MOUTH))
		desired_look = desired_position + (aligned * Vector3.FORWARD).lerp(toward_tube, 0.45) + Vector3.DOWN * 0.13
	var desired := Transform3D(Basis.looking_at(desired_look - desired_position), desired_position)
	if free_look:
		desired.basis *= free_look_basis()
		camera.transform = desired
	else:
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
	if coop_controls_locked():
		return
	if (event is InputEventKey and event.pressed and not event.echo
			and event.physical_keycode == KEY_CTRL and event.location == KEY_LOCATION_LEFT
			and playing and observing and observer_available() and not get_tree().paused
			and not loadout_open and not hud.radio_typing()):
		observer_kneeling = not observer_kneeling
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.physical_keycode == KEY_ALT and event.location == KEY_LOCATION_LEFT:
		if event.pressed:
			begin_free_look()
		else:
			end_free_look()
		if playing:
			get_viewport().set_input_as_handled()
		return
	if hud.radio_typing() or loadout_open:
		return
	if event is InputEventMouseButton and event.pressed:
		if playing and sniper_mode and sniper_scoped and loadout.equipped() == LOADOUT.Item.M40 and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var step := 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1
			sniper_zoom_index = clampi(sniper_zoom_index + step, 0, SNIPER_ZOOMS.size() - 1)
			sync_player_visibility()
			hud.sync()
			get_viewport().set_input_as_handled()
			return
		if sniper_mode and playing and observing and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if event.button_index == MOUSE_BUTTON_RIGHT:
				sniper_scoped = loadout.equipped() != LOADOUT.Item.EMPTY and sniper.reload_left <= 0.0 and not sniper_scoped
				observer_camera(0.0)
				sync_player_visibility()
			else:
				fire_sniper()
			get_viewport().set_input_as_handled()
			return
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
	if free_look:
		var movement: Vector2 = event.screen_relative * 0.004
		free_look_angles.x = clampf(free_look_angles.x - movement.x, -1.55, 1.55)
		free_look_angles.y = clampf(free_look_angles.y - movement.y, -0.8, 0.8)
	elif observing and playing:
		look_observer(event.screen_relative * 0.004)
	elif not follow.is_empty():
		scout_yaw = clampf(scout_yaw - event.relative.x * 0.0036, -1.75, 1.75)
		scout_pitch = clampf(scout_pitch - event.relative.y * 0.0036, -0.82, 0.95)

func _unhandled_input(event: InputEvent) -> void:
	if hud.radio_typing() or loadout_open:
		return
	if observing and playing and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()

func reload_rifle() -> void:
	if not can_use_loadout() or get_tree().paused or loadout_open:
		return
	var weapon := loadout.equipped()
	if sniper.start_reload(weapon):
		sniper_scoped = false
		sync_player_visibility()
		hud.sync()

func fire_sniper() -> void:
	if not can_use_loadout() or get_tree().paused or loadout_open or sniper.reload_left > 0.0:
		return
	var weapon := loadout.equipped()
	if weapon == LOADOUT.Item.EMPTY:
		return
	if sniper.magazine_rounds(weapon) == 0:
		reload_rifle()
		return
	if weapon == LOADOUT.Item.M40:
		if sniper.action == TOY_MARKSMAN.Action.CYCLING:
			return
		if sniper.action == TOY_MARKSMAN.Action.SPENT:
			sniper.start_cycle()
			sniper_cycle_audio.play()
			hud.sync()
			return
	var direction := -Basis.from_euler(Vector3(observer_pitch, observer_yaw, 0.0)).z
	var origin := observer_eye_position() + direction * TOY_MARKSMAN.TRACER_LEAD
	var fired := sniper.fire_m16(actors, origin, direction) if weapon == LOADOUT.Item.M16 else sniper.fire(actors, origin, direction)
	if fired:
		(m16_audio if weapon == LOADOUT.Item.M16 else sniper_audio).play()
		observer_camera(0.0)
		hud.sync()

func _physics_process(delta: float) -> void:
	if not playing or coop.guest_match() or sniper.rounds.is_empty():
		return
	var listener := camera.global_position
	var results := sniper.advance(delta, get_world_3d().direct_space_state, greens, tans,
		observer_unit, notice_toy_round, projectile_audio.flyby_listener(camera))
	for hit in results:
		if hit.has("flyby"):
			projectile_audio.play_at(&"flyby", hit.point, listener)
			continue
		if hit.has("surface"):
			projectile_audio.play_at(hit.impact_material, hit.point, listener)
			var ground_hit: bool = hit.surface == TOY_MARKSMAN.Surface.DIRT
			var style := RIFLE_IMPACT.Style.DIRT if ground_hit else RIFLE_IMPACT.Style.COVER
			spawn_rifle_impact("Dirt Impact" if ground_hit else "Cover Impact", style, hit.point, hit.normal)
			continue
		var unit: Node3D = hit.get("unit")
		if not is_instance_valid(unit) or unit.is_queued_for_deletion():
			continue
		apply_rifle_hit(unit, hit)

func apply_rifle_hit(unit: Node3D, hit: Dictionary) -> void:
	var tan: bool = unit.is_tan
	var practice_player := is_practice() and unit == observer_unit
	if practice_player and practice_invulnerable:
		return
	var team := tans if tan else greens
	var style := RIFLE_IMPACT.Style.TAN_TOY if tan else RIFLE_IMPACT.Style.GREEN_TOY
	var plastic_chips: bool = hit.kind == TOY_MARKSMAN.RoundKind.PLAYER
	spawn_rifle_impact("Tan Plastic Hit" if tan else "Green Plastic Hit", style,
		hit.point, -Vector3(hit.direction), plastic_chips)
	var player_round := TOY_MARKSMAN.is_player_round(hit.kind)
	var damage := NPC_RIFLE_DAMAGE
	match hit.kind:
		TOY_MARKSMAN.RoundKind.PLAYER:
			damage = 1.0
		TOY_MARKSMAN.RoundKind.PLAYER_M16:
			match hit.get("region", TOY_SOLDIER.HitRegion.LIMB):
				TOY_SOLDIER.HitRegion.HEAD, TOY_SOLDIER.HitRegion.UPPER_TORSO:
					damage = 1.0
				TOY_SOLDIER.HitRegion.LOWER_TORSO:
					damage = M16_LOWER_TORSO_DAMAGE
				_:
					damage = M16_LIMB_DAMAGE
	var health := maxf(0.0, float(unit.get_meta("health", 1.0)) - damage)
	if health > 0.0001:
		unit.set_meta("health", health)
		if unit == observer_unit:
			report = ("Health %d%%" if is_practice() else "Observer hit • %d%%") % roundi(health * 100)
		return
	if practice_player:
		greens.erase(unit)
		unit.queue_free()
		begin_practice_respawn()
		return
	remove_hit_unit(team, team.find(unit), hit.point, 0, {} if player_round and not tan else hit)
	if tan:
		kills += 1
		report = "Tan rifleman down"
	else:
		report = "Green hit"

func begin_practice_respawn() -> void:
	practice_respawn_left = PRACTICE_RESPAWN_SECONDS
	sniper.cancel_reload()
	sniper_scoped = false
	sniper_raise = 0.0
	m16_focus = 0.0
	sniper_view.clear()
	hud.show_practice_death(ceili(practice_respawn_left))

func advance_practice_respawn(delta: float) -> void:
	if practice_respawn_left <= 0.0:
		return
	practice_respawn_left = maxf(0.0, practice_respawn_left - delta)
	if practice_respawn_left > 0.0:
		hud.show_practice_death(ceili(practice_respawn_left))
		return

	var weapon := loadout.equipped()
	observer_unit = add_soldier(observer_spawn(), false, weapon != LOADOUT.Item.EMPTY, weapon == LOADOUT.Item.M40)
	greens.append(observer_unit)
	reset_observer_posture()
	observing = true
	observer_first_person = true
	observer_yaw = 0.0
	observer_pitch = OBSERVER_DEFAULT_PITCH
	if weapon != LOADOUT.Item.EMPTY:
		sniper_view.equip(observer_unit.poses[TOY_SOLDIER.Pose.STANDING], weapon == LOADOUT.Item.M16)
	sniper.animate(PRACTICE_RESPAWN_SECONDS)
	observer_camera(0.0)
	report = ""
	hud.show_game()

func notice_toy_round(from: Vector3, to: Vector3) -> void:
	if from.is_equal_approx(to):
		return
	for unit in tans:
		if unit.reaction_cooldown > 0.0:
			continue
		var center := unit.position + Vector3.UP * 0.8
		if center.distance_squared_to(Geometry3D.get_closest_point_to_segment(center, from, to)) < 12.25:
			if is_practice():
				var patrol: Dictionary = patrols[unit]
				patrol.heard_player = true
				patrol.look_timer = 0.0
			else:
				start_tan_reaction(unit, true)

func spawn_rifle_impact(effect_name: String, style: RIFLE_IMPACT.Style, point: Vector3,
		normal: Vector3, plastic_chips := true) -> void:
	var puff := RIFLE_IMPACT.new()
	puff.name = effect_name
	puff.style = style
	puff.normal = normal
	puff.position = point + normal * 0.035
	puff.plastic_chips = plastic_chips
	if puff.is_toy_hit() and plastic_chips:
		puff.plastic_ground_y = ground_height(Vector2(point.x, point.z))
	actors.add_child(puff)


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
			var along_flight := Basis(Quaternion(Vector3.UP, travel.normalized()))
			var roll := Basis(Vector3.UP, float(entry.time) * ROUND_ROLL_SPEED)
			shell.basis = along_flight * roll
		if t >= 1.0:
			var watched := follow == entry
			if watched:
				follow.hold = IMPACT_VIEW_SECONDS
			detonate(target, entry.airburst, watched)
			if entry.radio_order != 0:
				observer_radio.landed(entry.radio_order)
			entry.shell.queue_free()
			shots.remove_at(index)

func detonate(at: Vector3, airburst := false, watched := false) -> void:
	paint_impact(at, airburst, watched)
	coop.send_impact(at, airburst)
	var center := Vector2(at.x, at.z)
	var tan_hits := damage(tans, at, airburst)
	for unit in tans:
		if unit.reaction_cooldown <= 0.0 and Vector2(unit.position.x, unit.position.z).distance_squared_to(center) < 225.0:
			start_tan_reaction(unit)
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

func paint_impact(at: Vector3, airburst: bool, watched: bool) -> void:
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


func ground_height(at: Vector2) -> float:
	return valley_ground.height_at(at)

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
			remove_hit_unit(team, index, at, 1 if airburst else breakage_count(distance))
			hits.x += 1
		else:
			unit.set_meta("health", health)
			hits.y += 1
			if not airburst and maybe_chip_figure(unit, at, distance):
				hits.z += 1
	return hits

func remove_hit_unit(team: Array[Node3D], index: int, at: Vector3, breakage: int, sniper_hit := {}) -> void:
	var unit := team[index]
	patrols.erase(unit)
	if unit.has_meta("kill_feed_label"):
		hud.add_kill(str(unit.get_meta("kill_feed_label")))
	drop_figure(unit, at, breakage, sniper_hit)
	unit.queue_free()
	team.remove_at(index)

func breakage_count(distance: float) -> int:
	if distance < 2.8:
		return 6
	if distance < 5.1:
		return 3
	if distance < 8.0:
		return 2
	return 1

func drop_figure(unit: Node3D, source: Vector3, breakage: int, sniper_hit: Dictionary) -> void:
	var remains := FALLEN_ASSET.new()
	remains.name = "Fallen Figure"
	actors.add_child(remains)
	if sniper_hit.is_empty():
		remains.drop(unit, source, breakage)
	else:
		remains.drop_limp(unit, sniper_hit.direction, sniper_hit.helmet_pop)

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

func move_tan(unit: Node3D, goal: Vector3, delta: float, meander := true) -> void:
	var speed: float = unit.get_meta("speed")
	var before := Vector2(unit.position.x, unit.position.z)
	var destination := Vector2(goal.x, goal.z)
	var next := before.move_toward(destination, speed * delta)
	var goal_distance_squared := before.distance_squared_to(destination)
	var reacting: bool = unit.reaction == TOY_SOLDIER.Reaction.DODGE
	var age: float = unit.reaction_duration - unit.reaction_left if reacting else DODGE_SECONDS
	if age < DODGE_SECONDS and goal_distance_squared > 1.0:
		var side := 1.0 if unit.get_instance_id() % 2 == 0 else -1.0
		var angle := sin(smoothstep(0.0, DODGE_SECONDS, age) * TAU) * side * 0.38
		next = before + (next - before).rotated(angle * smoothstep(1.0, 3.5, sqrt(goal_distance_squared)))
	elif meander and goal_distance_squared > 144.0:
		var phase := float(unit.get_instance_id() % 31) * 0.67
		next = before + (next - before).rotated(sin(elapsed * 0.65 + phase) * 0.28)
	var movement := next - before
	unit.position = Vector3(next.x, ground_height(next), next.y)
	if movement.length_squared() > 0.000001:
		unit.rotation.y = atan2(-movement.x, -movement.y)
		var distance_squared := camera.position.distance_squared_to(unit.position)
		var near_view := distance_squared <= runner_detail_distance_squared
		if sniper_scoped and distance_squared > RUNNER_DETAIL_DISTANCE * RUNNER_DETAIL_DISTANCE:
			near_view = near_view and camera.is_position_in_frustum(unit.position + Vector3.UP * 0.85)
		if near_view and (unit.runner or runner_starts_left > 0):
			if not unit.runner:
				runner_starts_left -= 1
			var flinch := sin(smoothstep(0.0, FLINCH_SECONDS, age) * PI) if age < FLINCH_SECONDS else 0.0
			unit.run_step(movement.length(), true, flinch)
			return
	unit.set_pose(TOY_SOLDIER.Pose.STANDING)

func start_tan_reaction(unit: Node3D, rifle_near_miss := false) -> void:
	var roll := rng.randf() if rifle_near_miss else 1.0
	unit.reaction_prone = 0.0
	if roll < 0.80:
		unit.reaction = TOY_SOLDIER.Reaction.DODGE
		unit.reaction_left = rng.randf_range(4.5, 5.5)
	elif roll < 0.95:
		unit.reaction = TOY_SOLDIER.Reaction.PRONE
		unit.reaction_left = rng.randf_range(2.4, 4.2)
	else:
		choose_cover_reaction(unit, rifle_near_miss)
	unit.reaction_duration = unit.reaction_left
	unit.reaction_cooldown = unit.reaction_left + rng.randf_range(2.0, 4.0)
	if unit.reaction in [TOY_SOLDIER.Reaction.COVER, TOY_SOLDIER.Reaction.PRONE]:
		unit.set_meta("flash_time", rng.randf_range(0.55, 1.15))

func choose_cover_reaction(unit: Node3D, rifle_near_miss: bool) -> void:
	var at := Vector2(unit.position.x, unit.position.z)
	var nearest := 14.0 * 14.0
	unit.reaction = TOY_SOLDIER.Reaction.NONE if rifle_near_miss else TOY_SOLDIER.Reaction.PRONE
	for station in valley_ground.stations:
		var point := station + Vector2(clampf(at.x - station.x, -3.0, 3.0), -1.35)
		var distance := at.distance_squared_to(point)
		if distance < nearest:
			nearest = distance
			unit.reaction = TOY_SOLDIER.Reaction.COVER
			unit.reaction_goal = Vector3(point.x, ground_height(point), point.y)
	unit.reaction_left = 0.0 if unit.reaction == TOY_SOLDIER.Reaction.NONE else rng.randf_range(2.4, 4.2)
	if unit.reaction == TOY_SOLDIER.Reaction.COVER:
		unit.reaction_left += sqrt(nearest) / float(unit.get_meta("speed"))

func advance_tan_reaction(unit: Node3D, delta: float) -> void:
	if unit.reaction == TOY_SOLDIER.Reaction.COVER and not unit.position.is_equal_approx(unit.reaction_goal):
		move_tan(unit, unit.reaction_goal, delta, false)
		return
	unit.rotation.y = atan2(unit.position.x - OUTPOST_CENTER.x, unit.position.z - OUTPOST_CENTER.z)
	var prone := smoothstep(0.0, 0.30, unit.reaction_left) if unit.reaction == TOY_SOLDIER.Reaction.PRONE else 0.0
	unit.reaction_prone = move_toward(unit.reaction_prone, prone, delta * 4.5)
	animate_rifle(unit, delta, unit.reaction_prone)

func add_rifle_pop(unit: Node3D) -> void:
	unit.set_meta("flash_time", rng.randf_range(0.45, 2.2))
	unit.set_meta("flash_hold", 0.0)
	var player := AudioStreamPlayer3D.new()
	player.name = "RiflePop"
	player.stream = M16_DISTANT_SOUND
	player.position = unit.to_local(unit.muzzle_position())
	player.unit_size = 18.0 if is_practice() else 9.0
	player.max_distance = M16_AUDIO_RANGE
	unit.add_child(player)

func animate_rifle(unit: Node3D, delta: float, prone := 0.0) -> void:
	var remaining: float = unit.get_meta("flash_time") - delta
	var hold := maxf(float(unit.get_meta("flash_hold")) - delta, 0.0)
	var fires := remaining <= 0.0
	if fires:
		hold = 0.26
		remaining = rng.randf_range(1.65, 3.4)
	var raised := maxf(1.0 - smoothstep(0.0, 0.4, remaining), smoothstep(0.0, 0.22, hold))
	var target := nearest_rifle_target(unit) if raised > 0.0 else null
	if target:
		var toward := target.position - unit.position
		unit.rotation.y = atan2(-toward.x, -toward.z)
	var visible_detail := camera.position.distance_squared_to(unit.position) <= runner_detail_distance_squared
	if (prone > 0.0 or (raised > 0.0 and visible_detail)) and (unit.runner or runner_starts_left > 0):
		if not unit.runner:
			runner_starts_left -= 1
		unit.rifle_pose(raised, prone, smoothstep(0.16, 0.26, hold))
	else:
		unit.set_pose(TOY_SOLDIER.Pose.STANDING if raised > 0.52 else TOY_SOLDIER.Pose.KNEELING)
	unit.set_meta("flash_time", remaining)
	unit.set_meta("flash_hold", hold)
	if fires:
		var sound: AudioStreamPlayer3D = unit.get_node("RiflePop")
		var muzzle: Vector3 = unit.muzzle_position()
		sound.position = unit.to_local(muzzle)
		flash(sound.global_position, 0.57, Color("#ffe19c"), 0.12)
		var listener_distance := camera.global_position.distance_squared_to(sound.global_position)
		if listener_distance < M16_AUDIO_RANGE * M16_AUDIO_RANGE:
			var distant := listener_distance > M16_DISTANT_DISTANCE * M16_DISTANT_DISTANCE
			sound.stream = M16_DISTANT_SOUND if distant else M16_NEAR_SOUND
			sound.volume_db = -22.0 if distant and not is_practice() else -14.0
			sound.play()
		var forward := -unit.global_basis.z
		if target:
			var aim := target.global_position + Vector3.UP * 0.85 - muzzle
			var spread := 0.9 + aim.length() * 0.055
			var side := aim.cross(Vector3.UP).normalized()
			aim += side * rng.randf_range(-spread, spread)
			aim.y += rng.randf_range(-spread, spread) * 0.65
			if not aim.is_zero_approx():
				forward = aim.normalized()
		sniper.fire_npc(actors, muzzle, forward, unit.is_tan)

func nearest_rifle_target(unit: Node3D) -> Node3D:
	var opposition := greens if unit.is_tan else tans
	var nearest: Node3D
	var best := NPC_RIFLE_REACH * NPC_RIFLE_REACH
	for target in opposition:
		var distance := unit.position.distance_squared_to(target.position)
		if distance < best:
			nearest = target
			best = distance
	return nearest

func breached(at: Vector3) -> bool:
	var relative := Vector2(at.x - OUTPOST_CENTER.x, at.z - OUTPOST_CENTER.z).abs()
	var from_wall := (relative - OUTPOST_HALF).max(Vector2.ZERO)
	return from_wall.length_squared() <= BREACH_DISTANCE * BREACH_DISTANCE

func finish_defense(won: bool) -> void:
	playing = false
	close_loadout()
	sniper_scoped = false
	sniper_raise = 0.0
	m16_focus = 0.0
	sniper.clear()
	observer_radio.clear()
	hud.close_radio_entry()
	trigger_time = 0.0
	if not follow.has("hold"):
		stop_following()
	report = "Outpost secured" if won else "Tan breached the perimeter"
	if coop.in_match():
		coop.finish_match(won)
	else:
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
	var magnification := sniper_zoom() if sniper_scoped else (binocular_zoom() if binoculars else 1)
	var detail_distance := RUNNER_DETAIL_DISTANCE * magnification
	runner_detail_distance_squared = detail_distance * detail_distance
	var defending := false
	for unit in tans:
		if breached(unit.position):
			finish_defense(false)
			return
		unit.reaction_cooldown = maxf(0.0, unit.reaction_cooldown - delta)
		unit.reaction_left = maxf(0.0, unit.reaction_left - delta)
		if unit.reaction_left == 0.0:
			unit.reaction = TOY_SOLDIER.Reaction.NONE
		elif unit.reaction != TOY_SOLDIER.Reaction.DODGE:
			advance_tan_reaction(unit, delta)
			defending = defending or unit.position.z > OUTPOST_CENTER.z - 155.0
			continue
		var line: int = unit.get_meta("line")
		if line < COVER_POSITIONS.size():
			var route: Array[Vector3] = unit.get_meta("route")
			var cover_time: float = unit.get_meta("cover_time")
			var dodging: bool = unit.reaction == TOY_SOLDIER.Reaction.DODGE \
				and unit.reaction_duration - unit.reaction_left < DODGE_SECONDS
			if dodging and unit.position.is_equal_approx(route[line]):
				cover_time = 0.0
				unit.set_meta("cover_time", cover_time)
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

func advance_village_patrols(delta: float) -> void:
	if not observer_available():
		return
	runner_starts_left = RUNNER_STARTS_PER_FRAME
	runner_detail_distance_squared = 190.0 * 190.0
	for unit in tans:
		var patrol: Dictionary = patrols[unit]
		patrol.look_timer = float(patrol.look_timer) - delta
		if patrol.look_timer <= 0.0:
			patrol.look_timer = 0.18
			var offset := observer_unit.position - unit.position
			var nearby := offset.length_squared() < PRACTICE_NEARBY_NOTICE * PRACTICE_NEARBY_NOTICE
			if nearby or patrol.get("heard_player", false):
				unit.rotation.y = atan2(-offset.x, -offset.z)
				patrol.heard_player = false
			patrol.sees_player = village_patrol.sees_player(unit, observer_unit)
		if advance_village_alert(unit, patrol, delta):
			continue

		if follow_village_route(unit, patrol, delta):
			if patrol.waypoint == patrol.path.size():
				patrol.idle = rng.randf_range(2.0, 7.0)
			continue
		unit.set_pose(TOY_SOLDIER.Pose.STANDING)
		unit.rotation.y = wrapf(unit.rotation.y + 0.9 * delta, -PI, PI)
		patrol.idle = float(patrol.idle) - delta
		if patrol.idle <= 0.0:
			var start := Vector2(unit.position.x, unit.position.z)
			var goal := Vector2(rng.randf_range(PRACTICE_WANDER.position.x, PRACTICE_WANDER.end.x),
				rng.randf_range(PRACTICE_WANDER.position.y, PRACTICE_WANDER.end.y))
			patrol.path = village_patrol.route(start, goal)
			patrol.waypoint = 0
			patrol.idle = 2.0

func advance_village_alert(unit: Node3D, patrol: Dictionary, delta: float) -> bool:
	match patrol.activity:
		VILLAGE_PATROL.Activity.SEEK_COVER:
			if not follow_village_route(unit, patrol, delta * 1.35):
				patrol.activity = VILLAGE_PATROL.Activity.WAIT_IN_COVER
				patrol.idle = rng.randf_range(0.8, 1.45)
				unit.set_pose(TOY_SOLDIER.Pose.KNEELING)
			return true
		VILLAGE_PATROL.Activity.WAIT_IN_COVER:
			patrol.idle = float(patrol.idle) - delta
			if patrol.sees_player:
				alert_village_tan(unit, patrol, delta)
			elif patrol.idle <= 0.0:
				patrol.path = village_patrol.route(Vector2(unit.position.x, unit.position.z), patrol.peek_point)
				patrol.waypoint = 0
				patrol.activity = VILLAGE_PATROL.Activity.PEEK
			return true
		VILLAGE_PATROL.Activity.PEEK:
			if patrol.sees_player:
				alert_village_tan(unit, patrol, delta)
			elif not follow_village_route(unit, patrol, delta):
				resume_village_patrol(unit, patrol)
			return true
		VILLAGE_PATROL.Activity.ALERT:
			patrol.idle = float(patrol.idle) - delta
			if patrol.idle <= 0.0:
				if not patrol.cover_path.is_empty():
					patrol.path = patrol.cover_path
					patrol.waypoint = 0
					patrol.activity = VILLAGE_PATROL.Activity.SEEK_COVER
				else:
					resume_village_patrol(unit, patrol)
			elif patrol.sees_player:
				animate_rifle(unit, delta)
			return true
		_:
			if patrol.sees_player:
				alert_village_tan(unit, patrol, delta)
				return true
	return false

func alert_village_tan(unit: Node3D, patrol: Dictionary, delta: float) -> void:
	if patrol.activity == VILLAGE_PATROL.Activity.ROAM:
		var route: PackedVector2Array = patrol.path
		patrol.roam_goal = route[-1] if not route.is_empty() else Vector2(unit.position.x, unit.position.z)
	patrol.peek_point = Vector2(unit.position.x, unit.position.z)
	patrol.cover_path = village_patrol.route_to_cover(unit, observer_unit)
	patrol.activity = VILLAGE_PATROL.Activity.ALERT
	patrol.idle = rng.randf_range(0.24, 0.48) if not patrol.cover_path.is_empty() else 1.0
	report = "A Tan spotted you"
	unit.set_meta("flash_time", 0.0)
	animate_rifle(unit, delta)

func resume_village_patrol(unit: Node3D, patrol: Dictionary) -> void:
	patrol.activity = VILLAGE_PATROL.Activity.ROAM
	patrol.path = village_patrol.route(Vector2(unit.position.x, unit.position.z), patrol.roam_goal)
	patrol.waypoint = 0
	patrol.look_timer = 0.55
	patrol.sees_player = false
	patrol.idle = 0.0

func follow_village_route(unit: Node3D, patrol: Dictionary, delta: float) -> bool:
	var path: PackedVector2Array = patrol.path
	var waypoint: int = patrol.waypoint
	if waypoint >= path.size():
		return false
	var at := path[waypoint]
	move_tan(unit, Vector3(at.x, ground_height(at), at.y), delta, false)
	if Vector2(unit.position.x, unit.position.z).distance_squared_to(at) < 0.001:
		patrol.waypoint = waypoint + 1
	return true

func _process(delta: float) -> void:
	if at_title:
		prepare_wave_soldier(WAVE_COUNTS[0])
		if fly_in_time >= 0.0:
			fly_to_gunner(delta)
		return
	advance_craters(delta)
	if playing and distant_launch_left > 0.0:
		distant_launch_left = maxf(distant_launch_left - delta, 0.0)
		if distant_launch_left == 0.0 and observing and observer_available():
			distant_launch_audio.play()
	if coop.guest_match():
		if observing and observer_available():
			observer_camera(delta)
		elif barrel:
			crew_camera(minf(delta * 5.0, 1.0))
		sync_player_visibility()
		hud.sync(delta)
		return
	if recoil_time > 0.0:
		recoil_time = maxf(0.0, recoil_time - delta)
		update_barrel()
	if playing:
		elapsed += delta
		cooldown = maxf(cooldown - delta, 0.0)
		if resupply_time > 0.0:
			resupply_time = maxf(resupply_time - delta, 0.0)
			if resupply_time <= 0.0:
				rounds_ready = CRATE_ROUNDS
				sync_crate()
		observer_radio.advance(delta)
		if trigger_time > 0.0:
			trigger_time = maxf(0.0, trigger_time - delta)
			if trigger_time <= 0.0:
				release_shot()
		flight(delta)
		if is_practice():
			advance_practice_respawn(delta)
			advance_village_patrols(delta)
		else:
			advance_battle(delta)
		update_effects(delta)
	if crew_motion:
		var round_ready := rounds_ready > 0 or observer_radio.pending
		crew_motion.pose(delta, barrel.to_global(TUBE_MOUTH), barrel.global_basis.y.normalized(), round_ready)
	if observing and (not playing or not observer_available()):
		end_free_look()
		observing = false
		close_loadout()
		set_binoculars(false)
		observer_radio.voice.cancel()
		hud.close_radio_entry()
		distant_launch_audio.stop()
		if practice_respawn_left <= 0.0:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if barrel:
			crew_camera(1.0)
	if observing:
		if sniper_mode:
			sniper.animate(delta)
			var raised := move_toward(sniper_raise, 1.0 if sniper_scoped else 0.0, delta * 4.5)
			sniper_raise = raised
			var focus := sniper_scoped and not free_look and not loadout_open \
				and loadout.equipped() == LOADOUT.Item.M16 and Input.is_physical_key_pressed(KEY_SHIFT)
			m16_focus = move_toward(m16_focus, 1.0 if focus else 0.0, delta / M16_FOCUS_SECONDS)
		observer_camera(delta)
	elif barrel:
		if follow.is_empty():
			crew_camera(minf(delta * 5.0, 1.0))
		else:
			shot_camera(delta)
	sync_player_visibility()
	hud.sync(delta)
