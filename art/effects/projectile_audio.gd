extends Node3D

const CATEGORIES := [&"flyby", &"dirt", &"wood", &"concrete", &"sandbag", &"concrete_ricochet"]
const BUNDLED_AUDIO := "res://art/effects/projectile_audio"
const MAX_VOICES := 10
const MAX_TAKES := 3
const CONCRETE_RICOCHET_CHANCE := 0.18
const IMPACT_RANGE := 95.0
const FLYBY_RANGE := 15.0

var clips: Dictionary[StringName, Array] = {}
var previous_take: Dictionary[StringName, int] = {}
var voices: Array[AudioStreamPlayer3D] = []
var variation := RandomNumberGenerator.new()

func load_clips() -> void:
	clips.clear()
	previous_take.clear()
	var local_folder := ""
	if OS.has_feature("windows") and not OS.has_feature("editor"):
		local_folder = OS.get_executable_path().get_base_dir().get_base_dir().path_join("Sound Effects")
	for category in CATEGORIES:
		var takes: Array[AudioStream] = []
		for index in range(MAX_TAKES):
			var stem := String(category) if index == 0 else "%s_%d" % [category, index + 1]
			var clip := load_take(local_folder, stem)
			if clip:
				takes.append(clip)
		if not takes.is_empty():
			clips[category] = takes

func load_take(local_folder: String, stem: String) -> AudioStream:
	for extension in ["wav", "mp3"]:
		var filename := "%s.%s" % [stem, extension]
		if not local_folder.is_empty():
			var local_path := local_folder.path_join(filename)
			if FileAccess.file_exists(local_path):
				var clip: AudioStream = AudioStreamWAV.load_from_file(local_path) if extension == "wav" \
					else AudioStreamMP3.load_from_file(local_path)
				if clip:
					return clip
		var bundled := BUNDLED_AUDIO.path_join(filename)
		if ResourceLoader.exists(bundled):
			return load(bundled) as AudioStream
	return null

func flyby_listener(camera: Camera3D) -> Vector3:
	return camera.global_position if clips.has(&"flyby") else Vector3.INF

func play_at(category: StringName, point: Vector3, listener: Vector3) -> void:
	var flyby := category == &"flyby"
	var radius := FLYBY_RANGE if flyby else IMPACT_RANGE
	if not clips.has(category) or point.distance_squared_to(listener) > radius * radius:
		return
	var voice: AudioStreamPlayer3D
	for player in voices:
		if not player.playing:
			voice = player
			break
	if voice == null:
		if voices.size() >= MAX_VOICES:
			return
		voice = AudioStreamPlayer3D.new()
		add_child(voice)
		voices.append(voice)
	var group := category
	if category == &"concrete" and clips.has(&"concrete_ricochet") \
			and variation.randf() < CONCRETE_RICOCHET_CHANCE:
		group = &"concrete_ricochet"
	var takes: Array = clips[group]
	var index := variation.randi_range(0, takes.size() - 1)
	if takes.size() > 1 and index == previous_take.get(group, -1):
		index = (index + 1) % takes.size()
	previous_take[group] = index
	voice.stream = takes[index]
	voice.global_position = point
	voice.max_distance = radius
	voice.unit_size = 3.0 if flyby else 9.0
	voice.volume_db = -12.0 if flyby else -15.0
	voice.play()

func stop_all() -> void:
	for voice in voices:
		voice.stop()
