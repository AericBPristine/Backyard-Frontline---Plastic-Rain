extends Node

signal lobby_changed

enum Phase { CLOSED, MENU, JOINING, LOBBY, MATCH, MATCH_OVER }
enum Role { GUNNER, OBSERVER }

const DISCOVERY_PORT := 31474
const MATCH_PORT := 31475
const PROTOCOL := "backyard-lan-1"
const JOIN_TIMEOUT := 7.0
const SNAPSHOT_STEP := 0.10
const REMATCH_DELAY := 2.4
const ROLE_NAMES := ["Mortar Gunner", "Observer"]

var game: Node3D
var phase := Phase.CLOSED
var status := ""
var code := ""
var players: Dictionary = {}
var host := false
var match_number := 0
var enet: ENetMultiplayerPeer
var discovery: PacketPeerUDP
var join_left := 0.0
var probe_left := 0.0
var snapshot_left := 0.0
var remote_observer_update_at := 0
var mirror_tans: Dictionary = {}
var mirror_greens: Dictionary = {}
var mirror_rounds: Dictionary = {}
var observer_goal := Vector3.ZERO

static func supported() -> bool:
	return OS.has_feature("windows") and not OS.has_feature("web")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.connected_to_server.connect(connected_to_host)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(host_disconnected)
	multiplayer.peer_connected.connect(await_invite)
	multiplayer.peer_disconnected.connect(peer_disconnected)

func in_match() -> bool:
	return phase == Phase.MATCH

func guest_match() -> bool:
	return in_match() and not host

func local_role() -> int:
	return int(players.get(multiplayer.get_unique_id(), {}).get("role", Role.GUNNER))

func local_ready() -> bool:
	return bool(players.get(multiplayer.get_unique_id(), {}).get("ready", false))

func open_menu() -> void:
	if not supported() or phase != Phase.CLOSED:
		return
	phase = Phase.MENU
	status = "Host a match or enter a code from someone on your local network."
	lobby_changed.emit()

func make_host() -> void:
	if phase != Phase.MENU:
		return
	discovery = PacketPeerUDP.new()
	if discovery.bind(DISCOVERY_PORT) != OK:
		return_to_menu("Couldn’t open LAN discovery. Close the other host or try again.")
		return
	enet = ENetMultiplayerPeer.new()
	if enet.create_server(MATCH_PORT, 1) != OK:
		return_to_menu("Couldn’t host on this PC. Close the other host or try again.")
		return
	multiplayer.multiplayer_peer = enet
	host = true
	code = "%06d" % (randi() % 1000000)
	players = {1: {"role": Role.GUNNER, "ready": false}}
	phase = Phase.LOBBY
	update_host_lobby()

func find_host(input: String) -> void:
	if phase != Phase.MENU:
		return
	var requested := input.strip_edges()
	if requested.length() != 6 or not requested.is_valid_int() or not requested.unicode_at(0) in range(48, 58):
		status = "Enter the six-digit code from your host."
		lobby_changed.emit()
		return
	discovery = PacketPeerUDP.new()
	if discovery.bind(0) != OK:
		return_to_menu("Couldn’t open LAN discovery on this PC.")
		return
	discovery.set_broadcast_enabled(true)
	code = requested
	phase = Phase.JOINING
	join_left = JOIN_TIMEOUT
	probe_left = 0.0
	status = "Looking for that code on the local network…"
	lobby_changed.emit()

func choose_role(role: int) -> void:
	if phase != Phase.LOBBY or role not in [Role.GUNNER, Role.OBSERVER]:
		return
	if host:
		set_player_role(1, role)
	else:
		request_role.rpc_id(1, role)

func set_ready(ready: bool) -> void:
	if phase != Phase.LOBBY:
		return
	if host:
		set_player_ready(1, ready)
	else:
		request_lobby_ready.rpc_id(1, ready)

func update_host_lobby() -> void:
	if phase != Phase.LOBBY:
		return
	if players.size() == 1:
		status = "Waiting for one player to join."
	elif int(players[1].role) == int(players[other_player()].role):
		status = "Pick different roles before you ready up."
	else:
		status = "The match starts when both players are ready."
	if players.size() == 2:
		receive_lobby.rpc_id(other_player(), code, players, status)
	lobby_changed.emit()
	if players.size() == 2 and players[1].ready and players[other_player()].ready:
		match_number += 1
		begin_match.rpc_id(other_player(), match_number, int(game.map_variant))
		begin_match(match_number, int(game.map_variant))

func other_player() -> int:
	for id: int in players:
		if id != 1:
			return id
	return 0

func return_to_menu(message: String) -> void:
	reset_network()
	phase = Phase.MENU
	status = message
	lobby_changed.emit()

func leave() -> void:
	var was_playing := phase == Phase.MATCH or phase == Phase.MATCH_OVER
	reset_network()
	phase = Phase.CLOSED
	status = ""
	if was_playing:
		game.quit_to_title()
	lobby_changed.emit()

func reset_network() -> void:
	if discovery:
		discovery.close()
	discovery = null
	if enet:
		enet.close()
	multiplayer.multiplayer_peer = null
	enet = null
	host = false
	code = ""
	players.clear()
	clear_snapshots()

func connected_to_host() -> void:
	if phase == Phase.JOINING:
		join_session.rpc_id(1, code)

func connection_failed() -> void:
	if phase == Phase.JOINING:
		return_to_menu("Couldn’t connect to the host. Check the code and local network.")

func host_disconnected() -> void:
	if phase != Phase.CLOSED and not host:
		if in_match() or phase == Phase.MATCH_OVER:
			game.quit_to_title()
		return_to_menu("The host left. Enter a code to join another match.")

func await_invite(id: int) -> void:
	if not host:
		return
	var connection := enet
	get_tree().create_timer(JOIN_TIMEOUT).timeout.connect(func():
		if host and enet == connection and not players.has(id) and id in multiplayer.get_peers():
			enet.disconnect_peer(id)
	)
func peer_disconnected(id: int) -> void:
	if not host or not players.has(id):
		return
	players.erase(id)
	if phase == Phase.MATCH or phase == Phase.MATCH_OVER:
		game.quit_to_title()
		clear_snapshots()
	phase = Phase.LOBBY
	players[1].ready = false
	update_host_lobby()

func set_player_role(id: int, role: int) -> void:
	if not host or phase != Phase.LOBBY or not players.has(id) or role not in [Role.GUNNER, Role.OBSERVER]:
		return
	if players[id].role == role:
		return
	players[id].role = role
	for player in players.values():
		player.ready = false
	update_host_lobby()

func set_player_ready(id: int, ready: bool) -> void:
	if not host or phase != Phase.LOBBY or not players.has(id):
		return
	if ready and (players.size() != 2 or players[1].role == players[other_player()].role):
		return
	players[id].ready = ready
	update_host_lobby()

@rpc("any_peer", "reliable")
func join_session(requested: String) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if not host or sender == 0 or players.has(sender):
		return
	if phase != Phase.LOBBY or players.size() != 1 or requested != code:
		enet.disconnect_peer(sender)
		return
	players[sender] = {"role": 1 - int(players[1].role), "ready": false}
	update_host_lobby()

@rpc("any_peer", "reliable")
func request_role(role: int) -> void:
	set_player_role(multiplayer.get_remote_sender_id(), role)

@rpc("any_peer", "reliable")
func request_lobby_ready(ready: bool) -> void:
	set_player_ready(multiplayer.get_remote_sender_id(), ready)

@rpc("authority", "reliable")
func receive_lobby(invite: String, roster: Dictionary, message: String) -> void:
	if phase != Phase.JOINING and phase != Phase.LOBBY:
		return
	phase = Phase.LOBBY
	code = invite
	players = roster
	status = message
	lobby_changed.emit()

@rpc("authority", "reliable")
func begin_match(number: int, map: int) -> void:
	match_number = number
	phase = Phase.MATCH
	clear_snapshots()
	snapshot_left = 0.0
	game.start_coop_game(local_role() == Role.OBSERVER, map)
	observer_goal = game.observer_unit.position
	remote_observer_update_at = Time.get_ticks_msec()
	lobby_changed.emit()

func finish_match(won: bool) -> void:
	if not host or phase != Phase.MATCH:
		return
	if other_player():
		show_match_over.rpc_id(other_player(), won)
	show_match_over(won)
	var current := match_number
	get_tree().create_timer(REMATCH_DELAY).timeout.connect(func():
		if host and phase == Phase.MATCH_OVER and current == match_number:
			for player in players.values():
				player.ready = false
			if other_player():
				reopen_lobby.rpc_id(other_player())
			reopen_lobby()
			update_host_lobby()
	)

@rpc("authority", "reliable")
func show_match_over(won: bool) -> void:
	if phase != Phase.MATCH:
		return
	phase = Phase.MATCH_OVER
	game.playing = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	status = "Outpost held." if won else "Outpost breached."
	lobby_changed.emit()

@rpc("authority", "reliable")
func reopen_lobby() -> void:
	if phase != Phase.MATCH_OVER:
		return
	clear_snapshots()
	game.quit_to_title()
	phase = Phase.LOBBY
	if not host:
		status = "Back in the lobby. Waiting for the host…"
	lobby_changed.emit()

func send_gunner_command(action: String, first := 0.0, second := 0.0) -> void:
	if guest_match() and local_role() == Role.GUNNER:
		gunner_command.rpc_id(1, match_number, action, first, second)

@rpc("any_peer", "reliable")
func gunner_command(number: int, action: String, first: float, second: float) -> void:
	if not allowed_remote(number, Role.GUNNER) or not is_finite(first) or not is_finite(second):
		return
	match action:
		"aim":
			game.apply_gunner_aim(clampf(first, -1.0, 1.0), clampf(second, -1.0, 1.0))
		"effect":
			game.airburst_selected = first > 0.0 and game.airburst_left > 0
		"fire":
			if game.mortar_ready() and game.rounds_ready > 0:
				game.press_mortar(game.airburst_selected)

func allowed_remote(number: int, role: int) -> bool:
	var sender := multiplayer.get_remote_sender_id()
	return host and in_match() and number == match_number and players.has(sender) and players[sender].role == role

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func observer_motion(number: int, position: Vector3, yaw: float, standing_pose: int) -> void:
	if not allowed_remote(number, Role.OBSERVER) or not position.is_finite() or not is_finite(yaw) or not game.observer_available():
		return
	var avatar: Node3D = game.observer_unit
	var now := Time.get_ticks_msec()
	var seconds := clampf((now - remote_observer_update_at) / 1000.0, 0.0, 0.4)
	remote_observer_update_at = now
	var offset := Vector3(position.x - avatar.position.x, 0.0, position.z - avatar.position.z)
	var pace := 2.0
	var available_travel := maxf(0.001, game.OBSERVER_SPEED * seconds * pace)
	game.move_observer((offset / available_travel).limit_length(), seconds, pace)
	var at := Vector2(avatar.position.x, avatar.position.z)
	var level: float = game.ground_height(at)
	avatar.position.y = clampf(position.y, level, level + game.OBSERVER_HOP_HEIGHT)
	avatar.rotation.y = wrapf(yaw, -PI, PI)
	avatar.set_pose(1 if standing_pose == 1 else 2)

func broadcast_battle() -> void:
	var recipient := other_player()
	if recipient == 0:
		return
	var red: Array = []
	for unit: Node3D in game.tans:
		red.append([unit.get_instance_id(), unit.position, unit.rotation.y, unit.pose])
	var green: Array = []
	for unit: Node3D in game.greens:
		if unit != game.observer_unit:
			green.append([unit.get_instance_id(), unit.position, unit.rotation.y, unit.pose])
	var shells: Array = []
	for shot: Dictionary in game.shots:
		var shell: Node3D = shot.shell
		shells.append([shell.get_instance_id(), shell.transform])
	var observer = game.observer_unit
	var avatar := [] if not is_instance_valid(observer) else [observer.position, observer.rotation.y, observer.pose]
	battle_snapshot.rpc_id(recipient, match_number,
		[game.wave, game.kills, game.intermission_left, game.heading, game.elevation,
		game.cooldown, game.rounds_ready, game.airburst_left, game.airburst_selected, game.report],
		red, green, avatar, shells)

@rpc("authority", "call_remote", "unreliable_ordered", 2)
func battle_snapshot(number: int, state: Array, red: Array, green: Array, avatar: Array, shells: Array) -> void:
	if not guest_match() or number != match_number:
		return
	var previous_wave: int = game.wave
	game.wave = state[0]
	game.kills = state[1]
	game.intermission_left = state[2]
	game.heading = state[3]
	game.elevation = state[4]
	game.cooldown = state[5]
	game.rounds_ready = state[6]
	game.airburst_left = state[7]
	game.airburst_selected = state[8]
	game.report = state[9]
	game.update_barrel()
	game.sync_crate()
	if previous_wave != game.wave and game.wave > 0:
		game.hud.announce_wave(game.wave, false)
	reconcile_figures(red, mirror_tans, game.tans, true)
	reconcile_figures(green, mirror_greens, game.greens, false)
	if avatar.size() == 3 and game.observer_available() and local_role() == Role.GUNNER:
		observer_goal = avatar[0]
		game.observer_unit.rotation.y = avatar[1]
		game.observer_unit.set_pose(1 if avatar[2] == 1 else 2)
	var seen := {}
	for row in shells:
		var id: int = row[0]
		seen[id] = true
		if not mirror_rounds.has(id):
			mirror_rounds[id] = game.make_coop_round_visual(row[1])
		mirror_rounds[id].goal = row[1]
	for id in mirror_rounds.keys():
		if not seen.has(id):
			mirror_rounds[id].node.queue_free()
			mirror_rounds.erase(id)

func reconcile_figures(rows: Array, mirrors: Dictionary, team: Array, tan: bool) -> void:
	var seen := {}
	for row in rows:
		var id: int = row[0]
		seen[id] = true
		if not mirrors.has(id):
			var model: Node3D = game.add_soldier(row[1], tan, true)
			team.append(model)
			mirrors[id] = {"node": model, "goal": row[1]}
		var figure: Node3D = mirrors[id].node
		mirrors[id].goal = row[1]
		figure.rotation.y = row[2]
		figure.set_pose(clampi(int(row[3]), 0, 2))
	for id in mirrors.keys():
		if not seen.has(id):
			var removed: Node3D = mirrors[id].node
			team.erase(removed)
			removed.queue_free()
			mirrors.erase(id)

func sync_guest_visuals(delta: float) -> void:
	var weight := 1.0 - exp(-16.0 * delta)
	for roster in [mirror_tans, mirror_greens]:
		for replica in roster.values():
			var model: Node3D = replica.node
			model.position = model.position.lerp(replica.goal, weight)
	for replica in mirror_rounds.values():
		var shell: Node3D = replica.node
		shell.transform = shell.transform.interpolate_with(replica.goal, weight)
	if local_role() == Role.GUNNER and game.observer_available():
		game.observer_unit.position = game.observer_unit.position.lerp(observer_goal, weight)

func clear_snapshots() -> void:
	mirror_tans.clear()
	mirror_greens.clear()
	mirror_rounds.clear()

func send_impact(point: Vector3, airburst: bool) -> void:
	if host and in_match() and other_player():
		show_impact.rpc_id(other_player(), match_number, point, airburst)

@rpc("authority", "reliable")
func show_impact(number: int, point: Vector3, airburst: bool) -> void:
	if guest_match() and match_number == number:
		game.paint_impact(point, airburst, false)

func send_launch(point: Vector3, direction: Vector3) -> void:
	if host and in_match() and other_player():
		show_launch.rpc_id(other_player(), match_number, point, direction)

@rpc("authority", "reliable")
func show_launch(number: int, point: Vector3, direction: Vector3) -> void:
	if guest_match() and match_number == number:
		game.paint_launch(point, direction)

func poll_discovery(delta: float) -> void:
	if phase == Phase.JOINING:
		join_left -= delta
		if join_left <= 0.0:
			return_to_menu("No host found for that code. Check that both PCs are on the same network.")
			return
		if discovery and enet == null:
			probe_left -= delta
			if probe_left <= 0.0:
				probe_left = 0.45
				for address in ["255.255.255.255", "127.0.0.1"]:
					if discovery.set_dest_address(address, DISCOVERY_PORT) == OK:
						discovery.put_packet(("%s:find:%s" % [PROTOCOL, code]).to_utf8_buffer())
	if not discovery:
		return
	for index in range(mini(discovery.get_available_packet_count(), 12)):
		var packet := discovery.get_packet()
		if packet.size() > 80:
			continue
		var message := packet.get_string_from_utf8()
		var sender := discovery.get_packet_ip()
		var sender_port := discovery.get_packet_port()
		if host and phase == Phase.LOBBY and players.size() == 1 and message == "%s:find:%s" % [PROTOCOL, code]:
			if discovery.set_dest_address(sender, sender_port) == OK:
				discovery.put_packet(("%s:offer:%s" % [PROTOCOL, code]).to_utf8_buffer())
		elif phase == Phase.JOINING and enet == null and message == "%s:offer:%s" % [PROTOCOL, code]:
			enet = ENetMultiplayerPeer.new()
			if enet.create_client(sender, MATCH_PORT) != OK:
				return_to_menu("Couldn’t open the connection. Try joining again.")
				return
			multiplayer.multiplayer_peer = enet
			status = "Connecting to the host…"
			lobby_changed.emit()

func _process(delta: float) -> void:
	poll_discovery(delta)
	if not in_match():
		return
	if not host:
		sync_guest_visuals(delta)
	snapshot_left -= delta
	if snapshot_left > 0.0:
		return
	snapshot_left = SNAPSHOT_STEP
	if host:
		broadcast_battle()
	elif local_role() == Role.OBSERVER and game.observer_available():
		var observer: Node3D = game.observer_unit
		observer_motion.rpc_id(1, match_number, observer.position, observer.rotation.y, observer.pose)
