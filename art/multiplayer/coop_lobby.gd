extends ColorRect

const SESSION := preload("res://art/multiplayer/coop_session.gd")

var hud: Node
var session: SESSION
var heading: Label
var subtitle: Label
var host_button: Button
var code_entry: LineEdit
var join_button: Button
var code_readout: Label
var copy_button: Button
var roles: Array[Button] = []
var ready_button: Button
var leave_button: Button
var partner_status: Label
var resume_button: Button
var match_menu_open := false
var previous_phase := SESSION.Phase.CLOSED

func setup(owner_hud: Node, connection: SESSION) -> void:
	hud = owner_hud
	session = connection
	color = Color("#0b1612d9")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.panel(self, Vector2(340, 169), Vector2(600, 382))
	heading = hud.label(self, "Private Co-op", Vector2(380, 193), 34)
	heading.size.x = 520
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle = hud.label(self, "", Vector2(380, 250), 16, hud.SOFT)
	subtitle.size.x = 520
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host_button = hud.button(self, "Host match", Vector2(435, 320), Vector2(170, 45), session.make_host)
	code_entry = LineEdit.new()
	code_entry.position = Vector2(435, 387)
	code_entry.size = Vector2(195, 45)
	code_entry.alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_entry.placeholder_text = "Six-digit code"
	code_entry.max_length = 6
	code_entry.add_theme_stylebox_override("normal", hud.style(Color("#182c23"), hud.LINE, 6))
	code_entry.add_theme_font_size_override("font_size", 18)
	code_entry.text_submitted.connect(session.find_host)
	add_child(code_entry)
	join_button = hud.button(self, "Join by code", Vector2(653, 387), Vector2(175, 45),
		func(): session.find_host(code_entry.text))
	code_readout = hud.label(self, "", Vector2(443, 292), 23, hud.ACCENT)
	copy_button = hud.button(self, "Copy code", Vector2(715, 293), Vector2(115, 35),
		func(): DisplayServer.clipboard_set(session.code))
	for index in range(SESSION.ROLE_NAMES.size()):
		var role := index
		var choice: Button = hud.button(self, SESSION.ROLE_NAMES[index],
			Vector2(425 + index * 226, 348), Vector2(203, 48), func(): session.choose_role(role))
		roles.append(choice)
	partner_status = hud.label(self, "", Vector2(386, 410), 15, hud.SOFT)
	partner_status.size.x = 508
	partner_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ready_button = CheckBox.new()
	ready_button.text = "Ready"
	ready_button.position = Vector2(467, 468)
	ready_button.size = Vector2(155, 43)
	ready_button.add_theme_font_size_override("font_size", 19)
	ready_button.toggled.connect(session.set_ready)
	add_child(ready_button)
	resume_button = hud.button(self, "Return to match", Vector2(420, 463), Vector2(185, 45), toggle_match_menu)
	leave_button = hud.button(self, "Back", Vector2(651, 468), Vector2(155, 43), session.leave)
	session.lobby_changed.connect(refresh)
	hide()

func toggle_match_menu() -> void:
	if not session.in_match():
		return
	match_menu_open = not match_menu_open
	if match_menu_open:
		hud.game.end_free_look()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if not match_menu_open and hud.game.observing else Input.MOUSE_MODE_VISIBLE
	refresh()

func refresh() -> void:
	var phase := session.phase
	if phase != SESSION.Phase.MATCH:
		match_menu_open = false
	visible = phase != SESSION.Phase.CLOSED and (phase != SESSION.Phase.MATCH or match_menu_open)
	if phase == SESSION.Phase.CLOSED:
		if previous_phase != SESSION.Phase.CLOSED and hud.game.at_title:
			hud.title_screen.show()
		previous_phase = phase
		return
	hud.title_screen.hide()
	var menu := phase == SESSION.Phase.MENU
	var joining := phase == SESSION.Phase.JOINING
	var lobby := phase == SESSION.Phase.LOBBY
	var match_over := phase == SESSION.Phase.MATCH_OVER
	heading.text = "Match Over" if match_over else "Private Co-op"
	subtitle.text = session.status
	if match_menu_open:
		subtitle.text = ""
	elif match_over:
		subtitle.text += " Returning to the lobby…"
	host_button.visible = menu
	code_entry.visible = menu
	join_button.visible = menu
	code_readout.visible = lobby
	copy_button.visible = lobby
	partner_status.visible = lobby
	ready_button.visible = lobby
	resume_button.visible = match_menu_open
	leave_button.visible = not match_over
	leave_button.text = "Back" if menu else ("Cancel" if joining else "Leave session")
	for choice in roles:
		choice.visible = lobby
	if lobby:
		var id := multiplayer.get_unique_id()
		var partner: Dictionary = {}
		for peer in session.players:
			if peer != id:
				partner = session.players[peer]
				break
		var ready := session.local_ready()
		var role := session.local_role()
		code_readout.text = "Join code  " + session.code
		partner_status.text = "Waiting for teammate" if partner.is_empty() else ("Teammate  ·  %s  ·  %s" % [
			SESSION.ROLE_NAMES[partner.role], "Ready" if partner.ready else "Picking role"])
		for index in range(roles.size()):
			hud.shade(roles[index], index == role)
		ready_button.disabled = partner.is_empty() or int(partner.role) == role
		ready_button.set_pressed_no_signal(ready)
	previous_phase = phase
