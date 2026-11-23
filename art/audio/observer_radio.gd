extends Node

const VOICE := preload("res://art/audio/radio_voice.gd")
const NORTH := 3200
const HEADING_STEPS := 10000
const SALVO_DIAMETER := 20.0
const CHECK_FIRE_CALLS := ["check fire", "check fire check fire"]
const SALVO_CALLS := [
	"fire for effect", "fire for effects", "fire for affect", "fire four effect",
	"fire fore effect", "fire for a fact", "fire for fact", "fire for the effect",
]

class FireOrder:
	var id: int
	var target: Vector2
	var remaining: int
	var salvo: bool

	func _init(number: int, point: Vector2, count: int) -> void:
		id = number
		target = point
		remaining = count
		salvo = count > 1

const WORDS := {
	"zero": 0, "oh": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
	"six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12,
	"thirteen": 13, "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17,
	"eighteen": 18, "nineteen": 19, "twenty": 20, "thirty": 30, "forty": 40,
	"fifty": 50, "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90
}

var game: Node3D
var voice: VOICE
var status := "Ready for a call"
var voice_input_check := ""
var target := Vector2.ZERO
var forward := Vector2(0.0, -1.0)
var has_target := false
var orders: Array[FireOrder] = []
var last_order: FireOrder
var order_number := 0
var pending := false
var airborne: Dictionary[int, int] = {}
var readback_left := 0.0
var readback_deadline := 0.0
var direction_call := RegEx.create_from_string("^(?:(?:new )?fire mission )?direction ([a-z0-9 ]+) distance ([a-z0-9 ]+)$")
var correction_call := RegEx.create_from_string(
	"^(left|right|add|drop) ([a-z0-9 ]+?)(?: (left|right|add|drop) ([a-z0-9 ]+?))?(?: ("
	+ "|".join(PackedStringArray(SALVO_CALLS)) + "))?$"
)

func _ready() -> void:
	voice = VOICE.new()
	voice.heard.connect(submit_voice)
	voice.unavailable.connect(func(message: String): status = message)
	add_child(voice)

func active() -> bool:
	return (game.playing and game.observing and not game.sniper_mode
		and game.observer_available() and not get_tree().paused and not game.coop_controls_locked())

func busy() -> bool:
	return not orders.is_empty() or not airborne.is_empty()

func clear() -> void:
	voice.cancel()
	if DisplayServer.get_name() != "headless":
		DisplayServer.tts_stop()
	reset_mission()
	status = "Ready for a call"

func reset_mission() -> void:
	if pending:
		game.cancel_pending_radio_round()
	has_target = false
	orders.clear()
	last_order = null
	pending = false
	airborne.clear()
	readback_left = 0.0
	readback_deadline = 0.0

func listen(pressed: bool) -> void:
	if pressed:
		if active():
			voice.begin()
	else:
		voice.end()

func heading(yaw: float) -> int:
	return posmod(NORTH - roundi(yaw * HEADING_STEPS / TAU), HEADING_STEPS)

func normalize_call(transcript: String) -> String:
	var words := transcript.to_lower().replace(",", " ").replace(".", " ").replace("-", " ").replace("!", " ").replace("?", " ")
	var clean := PackedStringArray()
	for word in words.split(" ", false):
		if word not in ["meters", "metres", "mils", "over", "and"]:
			clean.append(word)
	return " ".join(clean)

func submit_voice(transcripts: Array) -> void:
	voice_input_check = ""
	if transcripts.is_empty():
		return
	var call := normalize_voice_call(String(transcripts.front()))
	if call not in CHECK_FIRE_CALLS and call not in SALVO_CALLS \
		and call not in ["fire mission", "new fire mission"] \
		and not direction_call.search(call) and not readable_correction(correction_call.search(call)):
		for index in range(1, transcripts.size()):
			var alternate := normalize_voice_call(String(transcripts[index]))
			var correction := correction_call.search(alternate)
			if alternate in CHECK_FIRE_CALLS or alternate == "fire for effect" \
				or (readable_correction(correction) and not correction.get_string(5).is_empty()):
				call = alternate
				break
	dispatch_call(call, true)

func normalize_voice_call(transcript: String) -> String:
	var call := " " + normalize_call(transcript) + " "
	return call.replace(" write ", " right ").replace(" wright ", " right ").strip_edges()

func readable_correction(command: RegExMatch) -> bool:
	if command == null:
		return false
	for index in [2, 4]:
		var words := command.get_string(index)
		if words.is_empty():
			continue
		var amount := read_number(words)
		if amount <= 0 or amount > 750:
			return false
	return true

func submit(transcript: String) -> void:
	dispatch_call(normalize_call(transcript), false)

func dispatch_call(call: String, from_voice: bool) -> void:
	if not active():
		return
	if game.coop.guest_match():
		game.coop.send_observer_call(call, from_voice)
		return
	execute_call(call, from_voice)

func execute_call(call: String, from_voice := false) -> void:
	if not game.playing or not game.observer_available():
		return
	if game.coop.in_match():
		voice_input_check = ""
	if call in CHECK_FIRE_CALLS:
		reset_mission()
		reply("Check fire. Mission cleared.")
		if game.coop.in_match() and game.coop.host:
			game.coop.publish_mil_correction("Check fire. Mission cleared.", "")
		return
	if not game.coop.in_match() and airborne.is_empty() and not orders.is_empty():
		reply("Round waiting to launch.")
		return
	var coordinates := direction_call.search(call)
	if coordinates:
		begin_mission(read_number(coordinates.get_string(1)), read_number(coordinates.get_string(2)), from_voice)
	elif call in ["fire mission", "new fire mission"]:
		reply("Send direction and distance.")
	elif call in SALVO_CALLS:
		if has_target:
			queue_rounds(game.CRATE_ROUNDS, "Fire for Effect. Six rounds.")
		else:
			reply("Send direction and distance first.")
	else:
		var correction := correction_call.search(call)
		if correction and has_target:
			adjust(correction)
		else:
			reply("Call not recognized. Try again or press T to type.")

func begin_mission(direction: int, distance: int, from_voice := false) -> void:
	var direction_valid := direction >= 0 and direction < HEADING_STEPS
	var distance_valid := distance > 0 and distance <= 1100
	if from_voice:
		voice_input_check = "Direction %s  ·  Distance %s" % [
			number_check(direction, direction_valid), number_check(distance, distance_valid)]
	if not direction_valid or not distance_valid:
		reply("Check the direction and distance.")
		return
	var turn := float(direction - NORTH) * TAU / HEADING_STEPS
	var axis := Vector2(sin(turn), -cos(turn))
	var observer: Vector3 = game.observer_unit.global_position
	var requested := Vector2(observer.x, observer.z) + axis * distance
	if not on_map(requested):
		reply("That call goes outside the map.")
		return
	target = requested
	forward = axis
	has_target = true
	queue_rounds(1, "Direction %04d. Distance %d." % [direction, distance])

func adjust(command: RegExMatch) -> void:
	var requested := target
	var confirmation := PackedStringArray()
	var right := Vector2(-forward.y, forward.x)
	for index in [1, 3]:
		var side := command.get_string(index)
		if side.is_empty():
			break
		var amount := read_number(command.get_string(index + 1))
		if amount <= 0 or amount > 750:
			reply("Repeat the correction distance.")
			return
		match side:
			"left": requested -= right * amount
			"right": requested += right * amount
			"add": requested += forward * amount
			"drop": requested -= forward * amount
		confirmation.append("%s %d" % [side.capitalize(), amount])
	if not on_map(requested):
		reply("That correction goes outside the map.")
		return
	target = requested
	var summary := ". ".join(confirmation) + "."
	if command.get_string(5).is_empty():
		queue_rounds(1, summary)
	else:
		queue_rounds(game.CRATE_ROUNDS, summary + " Fire for Effect. Six rounds.")

func on_map(point: Vector2) -> bool:
	var edge := (point - Vector2(game.MAP_CENTER.x, game.MAP_CENTER.z)).abs()
	return maxf(edge.x, edge.y) < game.MAP_SIZE * 0.5 - 1.0

func queue_rounds(count: int, readback: String) -> void:
	if game.coop.in_match():
		var sent := readback if readback.ends_with(".") else readback + "."
		reply(sent + " Sent to the gunner.")
		if game.coop.host:
			game.publish_gunner_correction(readback)
		return
	order_number += 1
	last_order = FireOrder.new(order_number, target, count)
	orders.append(last_order)
	if orders.size() == 1:
		start_readback_delay()
		reply(readback)
	else:
		reply(readback + " Call queued.")

func start_readback_delay() -> void:
	readback_left = 1.5
	readback_deadline = 5.0

func advance(delta: float) -> void:
	if game.coop.in_match() or orders.is_empty() or pending:
		return
	readback_left = maxf(0.0, readback_left - delta)
	readback_deadline = maxf(0.0, readback_deadline - delta)
	if readback_left > 0.0:
		return
	if readback_deadline > 0.0 and game.observing and DisplayServer.get_name() != "headless" and DisplayServer.tts_is_speaking():
		return
	if not game.queue_radio_round():
		return
	pending = true

func round_target() -> Vector2:
	var order := orders.front() as FireOrder
	if order.salvo:
		for attempt in range(24):
			var angle: float = game.rng.randf_range(0.0, TAU)
			var radius: float = 0.5 * SALVO_DIAMETER * sqrt(game.rng.randf())
			var point := order.target + Vector2.from_angle(angle) * radius
			if on_map(point):
				return point
	return order.target

func released() -> int:
	var order := orders.front() as FireOrder
	pending = false
	airborne[order.id] = airborne.get(order.id, 0) + 1
	order.remaining -= 1
	if order.remaining == 0:
		orders.pop_front()
		if not orders.is_empty():
			start_readback_delay()
	if order == last_order:
		status = "Salvo launching" if order.remaining > 0 else "Rounds away. Ready for next call."
	return order.id

func landed(id: int) -> void:
	if not airborne.has(id):
		return
	airborne[id] -= 1
	if airborne[id] == 0:
		airborne.erase(id)
		if last_order == null or id != last_order.id or last_order.remaining > 0:
			return
		if last_order.salvo:
			has_target = false
			reply("Rounds complete.")
		else:
			status = "Ready for a correction or Fire for Effect"

func reply(message: String) -> void:
	status = message
	if game.coop.in_match() and game.coop.host:
		game.coop.send_observer_readback(message, voice_input_check)
		return
	speak(message)

func speak(message: String) -> void:
	if game.observing and DisplayServer.get_name() != "headless":
		var voices := DisplayServer.tts_get_voices_for_language("en")
		if not voices.is_empty():
			DisplayServer.tts_speak(message, voices[0], 85, 1.0, 1.05, 0, true)

static func number_check(number: int, valid: bool) -> String:
	if number < 0:
		return "unreadable"
	return "OK" if valid else "outside game limits"

static func read_number(text: String) -> int:
	var parts := text.strip_edges().split(" ", false)
	var total := 0
	var group := 0
	var previous_digit := false
	for part in parts:
		if part == "hundred" or part == "thousand":
			if group == 0:
				return -1
			if part == "thousand":
				total += group * 1000
				group = 0
			else:
				group *= 100
			previous_digit = false
			continue
		var value: int = int(part) if part.is_valid_int() else WORDS.get(part, -1)
		if value < 0 or value > 11000:
			return -1
		if previous_digit and value < 10:
			group = group * 10 + value
		elif previous_digit and part.is_valid_int() and part.length() == 3:
			group = group * 1000 + value
		else:
			group += value
		previous_digit = value < 10
		if group + total > 11000:
			return -1
	return total + group
