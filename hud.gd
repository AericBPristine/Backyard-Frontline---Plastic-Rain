extends CanvasLayer

const PAPER := Color("#f2ecd5")
const SOFT := Color("#c9d2b2")
const ACCENT := Color("#e4ce86")
const DARK := Color("#14251eee")
const LINE := Color("#6c815a")
const MINT := Color("#b9d28b")
const INDEX_RED := Color("#ff7969")
const KILL_FEED_LIMIT := 10
const KILL_FEED_HEIGHT := 27.0
const KILL_FEED_LIFETIME := 5.0
const KILL_FEED_FADE := 1.4
const ANNOUNCEMENT_SECONDS := 3.4
const BINOCULAR_MASK := preload("res://art/figures/binocular_mask.gdshader")
const SNIPER_MASK := preload("res://art/figures/sniper_scope.gdshader")
const TOY_MARKSMAN := preload("res://art/figures/toy_marksman.gd")
const LOADOUT := preload("res://art/figures/player_loadout.gd")
const LOADOUT_HUD := preload("res://art/figures/loadout_hud.gd")
const COOP_LOBBY := preload("res://art/multiplayer/coop_lobby.gd")

var game: Node3D
var root: Control
var overlay: ColorRect
var title_screen: Control
var start_button: Button
var sniper_button: Button
var valley_map_button: Button
var fields_map_button: Button
var practice_button: Button
var coop_title_button: Button
var coop_lobby: COOP_LOBBY
var title_settings_button: Button
var settings_overlay: ColorRect
var music_slider: HSlider
var music_percent: Label
var microphone_picker: OptionButton
var microphone_note: Label
var find_microphones_button: Button
var test_microphone_button: Button
var pause_overlay: ColorRect
var resume_button: Button
var title: Label
var briefing: Label
var play_button: Button
var wave_label: Label
var wave_detail: Label
var intermission_label: Label
var total_label: Label
var wave_banner: Control
var banner_title: Label
var banner_detail: Label
var announcement_left := 0.0
var announcing_clear := false
var greens_label: Label
var report_label: Label
var shell_hint: Control
var kill_feed: Control
var kill_entries: Array[Dictionary] = []
var azimuth_tape: Control
var elevation_tape: Control
var azimuth_readout: Label
var elevation_readout: Label
var fire_button: Button
var ride_button: Button
var effect_button: Button
var gunner_controls: Control
var observer_controls: Control
var sniper_controls: Control
var sniper_status: Label
var sniper_aim_hint: Label
var inventory: LOADOUT_HUD
var scope: ColorRect
var scope_action: Label
var scope_zoom_label: Label
var binocular_mask: ColorRect
var binocular_heading: Label
var radio_panel: Control
var radio_status: Label
var radio_transcript: Label
var radio_input_check: Label
var radio_entry: LineEdit
var observer_title: Label
var observer_look_hint: Label
var observer_view_hint: Label
var observer_button: Button
var observer_return_button: Button
var he_button: Button
var airburst_button: Button
var crate_label: Label
var cached_state := ""
var shown_azimuth := -1
var shown_elevation := -1
var heading_slider: HSlider
var elevation_slider: HSlider

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	binocular_mask = ColorRect.new()
	binocular_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	binocular_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var lenses := ShaderMaterial.new()
	lenses.shader = BINOCULAR_MASK
	binocular_mask.material = lenses
	binocular_mask.hide()
	root.add_child(binocular_mask)
	var reticle := Control.new()
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	binocular_mask.add_child(reticle)
	reticle.draw.connect(draw_binocular_reticle.bind(reticle))
	binocular_heading = label(binocular_mask, "", Vector2(550, 80), 16, PAPER)
	binocular_heading.size.x = 180
	binocular_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	binocular_heading.add_theme_color_override("font_shadow_color", DARK)
	binocular_heading.add_theme_constant_override("shadow_offset_y", 2)
	gunner_controls = Control.new()
	gunner_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(gunner_controls)
	observer_controls = Control.new()
	observer_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	observer_controls.hide()
	root.add_child(observer_controls)

	panel(root, Vector2(22, 20), Vector2(343, 124))
	wave_label = label(root, "", Vector2(40, 30), 21, ACCENT)
	intermission_label = label(root, "", Vector2(215, 34), 15, SOFT)
	intermission_label.size.x = 132
	intermission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wave_detail = label(root, "", Vector2(40, 60), 16)
	total_label = label(root, "", Vector2(40, 83), 15, SOFT)
	greens_label = label(root, "", Vector2(238, 83), 15, MINT)
	greens_label.size.x = 109
	greens_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	report_label = label(root, "", Vector2(40, 111), 15, SOFT)

	panel(gunner_controls, Vector2(388, 20), Vector2(504, 88))
	label(gunner_controls, "AZIMUTH · MIL", Vector2(406, 32), 14, ACCENT)
	azimuth_readout = label(gunner_controls, "", Vector2(594, 25), 24)
	azimuth_readout.size.x = 92
	azimuth_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	azimuth_tape = Control.new()
	azimuth_tape.position = Vector2(395, 55)
	azimuth_tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gunner_controls.add_child(azimuth_tape)
	azimuth_tape.draw.connect(draw_azimuth_tape)

	panel(gunner_controls, Vector2(22, 156), Vector2(115, 353))
	label(gunner_controls, "ELEVATION", Vector2(38, 168), 14, ACCENT)
	elevation_readout = label(gunner_controls, "", Vector2(38, 190), 23)
	label(gunner_controls, "MIL", Vector2(94, 198), 13, SOFT)
	elevation_tape = Control.new()
	elevation_tape.position = Vector2(41, 232)
	elevation_tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gunner_controls.add_child(elevation_tape)
	elevation_tape.draw.connect(draw_elevation_tape)

	panel(gunner_controls, Vector2(776, 496), Vector2(482, 200))
	ride_button = button(gunner_controls, "Shell camera  [C]", Vector2(793, 510), Vector2(147, 31), func(): game.set_view(true))
	effect_button = button(gunner_controls, "Fire for Effect", Vector2(947, 510), Vector2(156, 31), func(): game.set_view(false))
	observer_button = button(gunner_controls, "Observer  [O]", Vector2(1111, 510), Vector2(129, 31), game.toggle_observer)
	label(gunner_controls, "Direction", Vector2(793, 551), 16)
	label(gunner_controls, "Elevation", Vector2(1020, 551), 16)
	heading_slider = slider(gunner_controls, Vector2(793, 572), -30.0, 30.0, func(value: float): game.aim(value - game.heading, 0))
	elevation_slider = slider(gunner_controls, Vector2(1020, 572), 18.0, 88.0, func(value: float): game.aim(0, value - game.elevation))
	he_button = button(gunner_controls, "HE-PD", Vector2(793, 610), Vector2(88, 38), func(): game.set_airburst(false))
	airburst_button = button(gunner_controls, "Airburst", Vector2(889, 610), Vector2(160, 38), func(): game.set_airburst(true))
	fire_button = button(gunner_controls, "Fire  [Space]", Vector2(1062, 610), Vector2(178, 38), game.fire)
	crate_label = label(gunner_controls, "", Vector2(793, 665), 14, SOFT)

	panel(observer_controls, Vector2(811, 595), Vector2(447, 101))
	observer_title = label(observer_controls, "GREEN OUTPOST", Vector2(829, 609), 15, ACCENT)
	observer_look_hint = label(observer_controls, "", Vector2(829, 648), 15, SOFT)
	observer_view_hint = label(observer_controls, "", Vector2(829, 671), 15, SOFT)
	observer_return_button = button(observer_controls, "Gunner  [O]", Vector2(1096, 608), Vector2(144, 36), game.toggle_observer)
	shade(observer_return_button, true)
	build_radio_panel(observer_controls)

	sniper_controls = Control.new()
	sniper_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sniper_controls.hide()
	root.add_child(sniper_controls)
	panel(sniper_controls, Vector2(22, 595), Vector2(338, 101))
	sniper_status = label(sniper_controls, "", Vector2(40, 611), 17, ACCENT)
	label(sniper_controls, "L Ctrl kneel  ·  Q/E lean", Vector2(188, 613), 13, SOFT)
	label(sniper_controls, "WASD move  ·  Shift sprint  ·  Space hop", Vector2(40, 645), 14, SOFT)
	sniper_aim_hint = label(sniper_controls, "", Vector2(40, 669), 14, SOFT)

	wave_banner = Control.new()
	wave_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wave_banner.hide()
	root.add_child(wave_banner)
	panel(wave_banner, Vector2(417, 292), Vector2(446, 111))
	banner_title = label(wave_banner, "", Vector2(417, 303), 35, ACCENT)
	banner_title.size.x = 446
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_detail = label(wave_banner, "", Vector2(417, 356), 18, SOFT)
	banner_detail.size.x = 446
	banner_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	overlay = ColorRect.new()
	overlay.color = Color("#0d1a13ac")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	panel(overlay, Vector2(348, 191), Vector2(584, 328))
	title = label(overlay, "", Vector2(377, 245), 57)
	briefing = label(overlay, "", Vector2(382, 332), 19, SOFT)
	briefing.size.x = 514
	briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	play_button = button(overlay, "Play again", Vector2(382, 455), Vector2(183, 43), game.start_game)
	shade(play_button, true)
	overlay.hide()
	shell_hint = Control.new()
	shell_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shell_hint)
	panel(shell_hint, Vector2(22, 20), Vector2(205, 36))
	label(shell_hint, "Left / right click to return", Vector2(34, 27), 15)
	shell_hint.hide()
	kill_feed = Control.new()
	kill_feed.process_mode = Node.PROCESS_MODE_PAUSABLE
	kill_feed.position = Vector2(1038, 20)
	kill_feed.size = Vector2(220, KILL_FEED_HEIGHT * KILL_FEED_LIMIT)
	kill_feed.clip_contents = true
	kill_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(kill_feed)
	kill_feed.hide()
	scope = ColorRect.new()
	scope.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scope.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sight := ShaderMaterial.new()
	sight.shader = SNIPER_MASK
	scope.material = sight
	scope.hide()
	add_child(scope)
	scope_zoom_label = scope_caption(-251.0)
	scope_action = scope_caption(221.0)
	scope_caption(250.0).text = "↑ / ↓ zero  ·  Scroll zoom"
	inventory = LOADOUT_HUD.new()
	inventory.game = game
	add_child(inventory)
	build_title()
	build_pause()
	build_settings()

func scope_caption(top: float) -> Label:
	var caption := label(scope, "", Vector2.ZERO, 16, PAPER)
	caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	caption.offset_left = -140.0
	caption.offset_right = 140.0
	caption.offset_top = top
	caption.offset_bottom = top + 27.0
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_shadow_color", Color("#161913"))
	caption.add_theme_constant_override("shadow_offset_y", 2)
	return caption

func draw_binocular_reticle(reticle: Control) -> void:
	var center := Vector2(640.0, 385.0)
	var ink := Color("#102017ed")
	var text_font := ThemeDB.fallback_font
	for side in [Vector2.RIGHT, Vector2.UP]:
		var lower := -6 if side == Vector2.RIGHT else -4
		reticle.draw_line(center + side * lower * 28.0, center + side * 6.0 * 28.0, ink, 1.5, true)
		for index in range(lower, 7):
			var at: Vector2 = center + side * index * 28.0
			var across: Vector2 = side.orthogonal() * (6.0 if index % 2 == 0 else 3.0)
			reticle.draw_line(at - across, at + across, ink, 1.4, true)
			if index != 0 and index % 2 == 0:
				var offset := Vector2(-8, 18) if side == Vector2.RIGHT else Vector2(-24, 4)
				reticle.draw_string_outline(text_font, at + offset, str(absi(index) * 5),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 2, Color("#ece5c4b9"))
				reticle.draw_string(text_font, at + offset, str(absi(index) * 5),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ink)

func build_radio_panel(parent: Control) -> void:
	radio_panel = Control.new()
	radio_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(radio_panel)
	panel(radio_panel, Vector2(22, 583), Vector2(495, 113))
	label(radio_panel, "RADIO   ·   Hold V to talk   ·   T to type", Vector2(39, 593), 16, ACCENT)
	radio_input_check = label(radio_panel, "", Vector2(39, 614), 13, SOFT)
	radio_input_check.hide()
	radio_status = label(radio_panel, "", Vector2(39, 632), 15, PAPER)
	radio_transcript = label(radio_panel, "", Vector2(39, 655), 14, SOFT)
	radio_transcript.size.x = 461
	radio_transcript.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	radio_transcript.max_lines_visible = 2
	radio_transcript.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	radio_transcript.hide()
	radio_entry = LineEdit.new()
	radio_entry.position = Vector2(39, 656)
	radio_entry.size = Vector2(461, 30)
	radio_entry.placeholder_text = "Direction and distance, correction, or Fire for Effect"
	radio_entry.max_length = 120
	radio_entry.hide()
	radio_entry.text_submitted.connect(submit_radio_text)
	radio_panel.add_child(radio_entry)

func radio_typing() -> bool:
	return radio_entry.visible

func close_radio_entry() -> void:
	if not radio_typing():
		return
	radio_entry.release_focus()
	radio_entry.hide()
	if game.observing and game.playing and not get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func submit_radio_text(command: String) -> void:
	close_radio_entry()
	game.observer_radio.submit(command)

func build_title() -> void:
	title_screen = Control.new()
	title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_screen)
	var tones := Gradient.new()
	tones.offsets = PackedFloat32Array([0.0, 0.18, 0.49, 0.75, 1.0])
	tones.colors = PackedColorArray([Color("#092026d9"), Color("#14221aa6"), Color("#16251b00"), Color("#17221826"), Color("#0a130ecd")])
	var fade := GradientTexture2D.new()
	fade.gradient = tones
	fade.fill_from = Vector2(0, 0)
	fade.fill_to = Vector2(0, 1)
	var scrim := TextureRect.new()
	scrim.texture = fade
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_screen.add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var words := label(title_screen, "BACKYARD FRONTLINE", Vector2(0, 40), 78)
	words.size.x = 1280
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.add_theme_font_override("font", preload("res://art/fonts/SairaStencilOne-Regular.ttf"))
	words.add_theme_color_override("font_shadow_color", Color("#111d17c7"))
	words.add_theme_constant_override("shadow_offset_y", 4)
	var subtitle := label(title_screen, "Plastic Rain", Vector2(0, 143), 29, ACCENT)
	subtitle.size.x = 1280
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_button = button(title_screen, "Play Mortar", Vector2(429, 564), Vector2(202, 61), game.begin_fly_in)
	sniper_button = button(title_screen, "Play Sniper", Vector2(649, 564), Vector2(202, 61), func(): game.begin_fly_in(true))
	sniper_button.focus_mode = Control.FOCUS_ALL
	sniper_button.add_theme_font_size_override("font_size", 24)
	start_button.add_theme_font_size_override("font_size", 26)
	start_button.focus_mode = Control.FOCUS_ALL
	var focus_ring := style(Color.TRANSPARENT, Color("#f4e4aa"), 6)
	focus_ring.set_border_width_all(2)
	focus_ring.set_expand_margin_all(4.0)
	start_button.add_theme_stylebox_override("focus", focus_ring)
	shade(start_button, true)
	var map_label := label(title_screen, "Map", Vector2(429, 478), 16, PAPER)
	map_label.size.x = 422.0
	map_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	valley_map_button = button(title_screen, "Wooded Valley", Vector2(429, 505), Vector2(202, 40),
		func(): game.select_map(game.MapVariant.WOODED_VALLEY))
	fields_map_button = button(title_screen, "Open Fields", Vector2(649, 505), Vector2(202, 40),
		func(): game.select_map(game.MapVariant.OPEN_FIELDS))
	var map_choices := ButtonGroup.new()
	for option in [valley_map_button, fields_map_button]:
		option.toggle_mode = true
		option.button_group = map_choices
		option.focus_mode = Control.FOCUS_ALL
		option.add_theme_stylebox_override("focus", focus_ring)
	sync_map_selection()
	practice_button = button(title_screen, "Practice Range", Vector2(22, 20), Vector2(148, 38), game.begin_practice)
	practice_button.focus_mode = Control.FOCUS_ALL
	practice_button.add_theme_stylebox_override("focus", focus_ring)
	title_settings_button = button(title_screen, "Settings", Vector2(539, 637), Vector2(202, 45), open_settings)
	title_settings_button.focus_mode = Control.FOCUS_ALL
	title_settings_button.add_theme_font_size_override("font_size", 19)
	if game.coop.supported():
		coop_title_button = button(title_screen, "Private Co-op", Vector2(22, 66), Vector2(148, 38), game.coop.open_menu)
		coop_title_button.focus_mode = Control.FOCUS_ALL
		coop_title_button.add_theme_stylebox_override("focus", focus_ring)
	coop_lobby = COOP_LOBBY.new()
	add_child(coop_lobby)
	coop_lobby.setup(self, game.coop)

func build_pause() -> void:
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color("#0b1612b9")
	add_child(pause_overlay)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel(pause_overlay, Vector2(433, 262), Vector2(414, 183))
	var heading := label(pause_overlay, "Paused", Vector2(433, 281), 40)
	heading.size.x = 414
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resume_button = button(pause_overlay, "Resume", Vector2(455, 365), Vector2(130, 51), game.resume_game)
	var settings_button := button(pause_overlay, "Settings", Vector2(595, 365), Vector2(130, 51), open_settings)
	var quit_button := button(pause_overlay, "Quit", Vector2(735, 365), Vector2(90, 51), game.quit_to_title)
	for control in [resume_button, settings_button, quit_button]:
		control.focus_mode = Control.FOCUS_ALL
		control.add_theme_font_size_override("font_size", 20)
	var focus_ring := style(Color.TRANSPARENT, Color("#f4e4aa"), 6)
	focus_ring.set_border_width_all(2)
	focus_ring.set_expand_margin_all(4.0)
	resume_button.add_theme_stylebox_override("focus", focus_ring)
	resume_button.add_theme_color_override("font_focus_color", Color("#202a1c"))
	quit_button.add_theme_stylebox_override("focus", focus_ring)
	shade(resume_button, true)
	pause_overlay.hide()

func build_settings() -> void:
	settings_overlay = ColorRect.new()
	settings_overlay.color = Color("#0b1612d9")
	add_child(settings_overlay)
	settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel(settings_overlay, Vector2(360, 170), Vector2(560, 382))
	var heading := label(settings_overlay, "Audio Settings", Vector2(360, 190), 38)
	heading.size.x = 560
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(settings_overlay, "Music volume", Vector2(395, 260), 21)
	music_percent = label(settings_overlay, "%d%%" % roundi(game.music_volume * 100), Vector2(808, 261), 20, ACCENT)
	music_percent.size.x = 76
	music_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	music_slider = slider(settings_overlay, Vector2(395, 299), 0, 100, update_music_volume)
	music_slider.size = Vector2(490, 30)
	music_slider.step = 1.0
	music_slider.focus_mode = Control.FOCUS_ALL
	music_slider.set_value_no_signal(game.music_volume * 100)
	label(settings_overlay, "Radio microphone", Vector2(395, 351), 21)
	microphone_picker = OptionButton.new()
	settings_overlay.add_child(microphone_picker)
	microphone_picker.position = Vector2(395, 383)
	microphone_picker.size = Vector2(355, 39)
	microphone_picker.fit_to_longest_item = false
	microphone_picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	microphone_picker.add_theme_font_size_override("font_size", 16)
	microphone_picker.item_selected.connect(set_microphone)
	shade(microphone_picker, false)
	find_microphones_button = button(settings_overlay, "Find mics", Vector2(765, 383), Vector2(120, 39),
		func(): refresh_microphones(true))
	find_microphones_button.focus_mode = Control.FOCUS_ALL
	microphone_note = label(settings_overlay, "", Vector2(395, 447), 15, SOFT)
	microphone_note.size.x = 360
	microphone_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	test_microphone_button = button(settings_overlay, "Test mic", Vector2(765, 436), Vector2(120, 39),
		game.observer_radio.voice.test_microphone)
	test_microphone_button.focus_mode = Control.FOCUS_ALL
	game.observer_radio.voice.devices_updated.connect(show_microphones)
	game.observer_radio.voice.microphone_check.connect(show_microphone_check)
	var back := button(settings_overlay, "Back", Vector2(580, 485), Vector2(120, 44), close_settings)
	back.focus_mode = Control.FOCUS_ALL
	back.add_theme_font_size_override("font_size", 19)
	settings_overlay.hide()

func open_settings() -> void:
	if get_tree().paused:
		pause_overlay.hide()
	else:
		title_screen.hide()
	music_slider.set_value_no_signal(game.music_volume * 100.0)
	music_percent.text = "%d%%" % roundi(game.music_volume * 100.0)
	settings_overlay.show()
	music_slider.grab_focus()
	refresh_microphones(false)

func refresh_microphones(request_access: bool) -> void:
	find_microphones_button.disabled = true
	test_microphone_button.disabled = true
	microphone_note.text = "Checking microphone devices…"
	game.observer_radio.voice.find_devices(request_access)

func show_microphones(devices: Array, message: String) -> void:
	microphone_picker.clear()
	microphone_picker.add_item("System default")
	microphone_picker.set_item_metadata(0, "")
	var saved: String = game.observer_radio.voice.input_device
	var choice := 0
	for device in devices:
		var index := microphone_picker.item_count
		microphone_picker.add_item(String(device.label))
		microphone_picker.set_item_metadata(index, String(device.id))
		if device.id == saved:
			choice = index
	if choice == 0 and not saved.is_empty():
		choice = microphone_picker.item_count
		microphone_picker.add_item("Previously selected mic unavailable")
		microphone_picker.set_item_metadata(choice, saved)
	microphone_picker.select(choice)
	find_microphones_button.disabled = false
	test_microphone_button.disabled = false
	microphone_note.text = message if not message.is_empty() else "Used when you hold V to talk."

func show_microphone_check(active: bool, message: String) -> void:
	microphone_picker.disabled = active
	find_microphones_button.disabled = active
	test_microphone_button.disabled = active
	microphone_note.text = message

func set_microphone(index: int) -> void:
	game.select_microphone(String(microphone_picker.get_item_metadata(index)))

func close_settings() -> void:
	game.observer_radio.voice.cancel_microphone_check()
	settings_overlay.hide()
	game.save_music_settings()
	if get_tree().paused:
		show_pause()
	else:
		title_screen.show()
		title_settings_button.grab_focus()

func update_music_volume(value: float) -> void:
	game.set_music_volume(value / 100.0)
	music_percent.text = "%d%%" % roundi(value)

func show_pause() -> void:
	close_radio_entry()
	game.observer_radio.voice.cancel()
	pause_overlay.show()
	resume_button.grab_focus()

func hide_pause() -> void:
	pause_overlay.hide()

func show_title() -> void:
	close_radio_entry()
	show_game()
	hide_pause()
	title_screen.modulate.a = 1.0
	start_button.disabled = false
	sniper_button.disabled = false
	valley_map_button.disabled = false
	fields_map_button.disabled = false
	practice_button.disabled = false
	if coop_title_button:
		coop_title_button.disabled = false
	title_settings_button.disabled = false
	title_screen.show()

func begin_fly_in() -> void:
	start_button.release_focus()
	start_button.disabled = true
	sniper_button.disabled = true
	valley_map_button.disabled = true
	fields_map_button.disabled = true
	practice_button.disabled = true
	if coop_title_button:
		coop_title_button.disabled = true
	title_settings_button.disabled = true

func sync_map_selection() -> void:
	var open_fields: bool = game.map_variant == game.MapVariant.OPEN_FIELDS
	valley_map_button.set_pressed_no_signal(not open_fields)
	fields_map_button.set_pressed_no_signal(open_fields)
	shade(valley_map_button, not open_fields)
	shade(fields_map_button, open_fields)

func fade_title(progress: float) -> void:
	title_screen.modulate.a = 1.0 - smoothstep(0.0, 0.20, progress)
	if progress >= 0.20:
		title_screen.hide()

func style(fill: Color, edge: Color, radius: int) -> StyleBoxFlat:
	var decoration := StyleBoxFlat.new()
	decoration.bg_color = fill
	decoration.border_color = edge
	decoration.set_border_width_all(1)
	decoration.set_corner_radius_all(radius)
	return decoration

func panel(parent: Control, at: Vector2, dimensions: Vector2) -> void:
	var background := Panel.new()
	parent.add_child(background)
	background.position = at
	background.size = dimensions
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skin := style(DARK, LINE, 9)
	skin.shadow_color = Color("#0a130ca6")
	skin.shadow_size = 6
	skin.shadow_offset = Vector2(0, 3)
	background.add_theme_stylebox_override("panel", skin)

func label(parent: Control, words: String, at: Vector2, points: int, color: Color = PAPER) -> Label:
	var text := Label.new()
	parent.add_child(text)
	text.position = at
	text.text = words
	text.add_theme_font_size_override("font_size", points)
	text.add_theme_color_override("font_color", color)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return text

func button(parent: Control, words: String, at: Vector2, dimensions: Vector2, action: Callable) -> Button:
	var control := Button.new()
	parent.add_child(control)
	control.position = at
	control.size = dimensions
	control.text = words
	control.focus_mode = Control.FOCUS_NONE
	control.add_theme_font_size_override("font_size", 16)
	control.add_theme_stylebox_override("disabled", style(Color("#293b2c"), LINE, 5))
	control.add_theme_color_override("font_disabled_color", SOFT)
	control.pressed.connect(action)
	shade(control, false)
	return control

func shade(control: Button, active: bool) -> void:
	control.add_theme_stylebox_override("normal", style(ACCENT if active else Color("#273c2b"), LINE, 5))
	control.add_theme_stylebox_override("hover", style(ACCENT.lightened(0.18) if active else Color("#42604a"), MINT, 5))
	control.add_theme_stylebox_override("pressed", style(ACCENT, MINT, 5))
	control.add_theme_color_override("font_color", Color("#202a1c") if active else PAPER)
	control.add_theme_color_override("font_hover_color", Color("#202a1c") if active else PAPER)
	control.add_theme_color_override("font_pressed_color", Color("#202a1c"))

func draw_azimuth_tape() -> void:
	var font := ThemeDB.fallback_font
	const CENTER := 245.0
	const PIXELS_PER_MIL := 0.54
	var first := floori((shown_azimuth - 430) / 25.0) * 25
	azimuth_tape.draw_line(Vector2(0, 16), Vector2(CENTER * 2.0, 16), LINE, 1.0)
	for tick in range(first, first + 925, 25):
		var x := CENTER + (tick - shown_azimuth) * PIXELS_PER_MIL
		if x < 1.0 or x > CENTER * 2.0 - 1.0:
			continue
		var major := tick % 100 == 0
		azimuth_tape.draw_line(Vector2(x, 16), Vector2(x, 2 if major else 9), SOFT, 1.0)
		if major and x >= 22.0 and x <= CENTER * 2.0 - 22.0:
			var value := "%04d" % posmod(tick, game.MILS_PER_TURN)
			var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			azimuth_tape.draw_string(font, Vector2(x - width * 0.5, 38), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, SOFT)
	azimuth_tape.draw_line(Vector2(CENTER, -2), Vector2(CENTER, 22), INDEX_RED, 3.0)

func draw_elevation_tape() -> void:
	var font := ThemeDB.fallback_font
	var low: int = game.elevation_mils(18)
	var high: int = game.elevation_mils(88)
	const HEIGHT := 258.0
	elevation_tape.draw_line(Vector2(14, 0), Vector2(14, HEIGHT), LINE, 1.0)
	for tick in range(700, 1550, 50):
		var y := (high - tick) * HEIGHT / (high - low)
		var major := tick % 100 == 0
		elevation_tape.draw_line(Vector2(14, y), Vector2(28 if major else 21, y), SOFT, 1.0)
		if major:
			elevation_tape.draw_string(font, Vector2(34, y + 4), "%d" % tick, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, SOFT)
	var marker_y := (high - shown_elevation) * HEIGHT / (high - low)
	var pointer := PackedVector2Array([Vector2(2, marker_y - 6), Vector2(14, marker_y), Vector2(2, marker_y + 6)])
	elevation_tape.draw_colored_polygon(pointer, INDEX_RED)

func slider(parent: Control, at: Vector2, low: float, high: float, action: Callable) -> HSlider:
	var control := HSlider.new()
	parent.add_child(control)
	control.position = at
	control.size = Vector2(205, 26)
	control.min_value = low
	control.max_value = high
	control.step = 0.0
	control.focus_mode = Control.FOCUS_NONE
	var rail := style(Color("#324a37"), LINE, 3)
	rail.content_margin_top = 4
	rail.content_margin_bottom = 4
	control.add_theme_stylebox_override("slider", rail)
	var fill := rail.duplicate() as StyleBoxFlat
	fill.bg_color = Color("#7f9e77")
	control.add_theme_stylebox_override("grabber_area", fill)
	control.add_theme_stylebox_override("grabber_area_highlight", fill)
	control.value_changed.connect(action)
	return control

func add_kill(unit_name: String) -> void:
	if kill_entries.size() == KILL_FEED_LIMIT:
		var retiring: Panel = kill_entries.pop_front().row
		var slide := retiring.create_tween().set_parallel()
		slide.tween_property(retiring, "position:x", 34.0, 0.18)
		slide.tween_property(retiring, "modulate:a", 0.0, 0.18)
		slide.chain().tween_callback(retiring.queue_free)
	var row := Panel.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.position = Vector2(28, kill_entries.size() * KILL_FEED_HEIGHT)
	row.size = Vector2(220, 24)
	row.modulate.a = 0.0
	row.add_theme_stylebox_override("panel", style(Color("#14251ef0"), Color("#87605a"), 4))
	kill_feed.add_child(row)
	var text := label(row, unit_name, Vector2(12, 2), 15, INDEX_RED)
	text.add_theme_color_override("font_outline_color", Color("#171511"))
	text.add_theme_constant_override("outline_size", 2)
	kill_entries.append({"row": row, "age": 0.0})

func update_kill_feed(delta: float) -> void:
	if not kill_feed.visible or delta <= 0.0:
		return
	for index in range(kill_entries.size() - 1, -1, -1):
		var entry := kill_entries[index]
		entry.age += delta
		if entry.age >= KILL_FEED_LIFETIME:
			entry.row.queue_free()
			kill_entries.remove_at(index)
	for index in range(kill_entries.size()):
		var entry := kill_entries[index]
		var row: Panel = entry.row
		var fade := smoothstep(KILL_FEED_LIFETIME - KILL_FEED_FADE, KILL_FEED_LIFETIME, entry.age)
		row.position.x = lerpf(28.0, 0.0, smoothstep(0.0, 0.24, entry.age)) + 26.0 * fade
		row.position.y = lerpf(row.position.y, index * KILL_FEED_HEIGHT, minf(delta * 16.0, 1.0))
		row.modulate.a = smoothstep(0.0, 0.18, entry.age) * (1.0 - fade)

func show_game() -> void:
	title_screen.hide()
	for row in kill_feed.get_children():
		row.queue_free()
	kill_entries.clear()
	announcement_left = 0.0
	wave_banner.hide()
	overlay.hide()

func announce_wave(number: int, cleared: bool) -> void:
	announcing_clear = cleared
	announcement_left = ANNOUNCEMENT_SECONDS
	banner_title.text = "WAVE %d COMPLETE" % number if cleared else "WAVE %d" % number
	if not cleared:
		banner_detail.text = "%d Tan riflemen" % game.WAVE_COUNTS[number - 1]
	wave_banner.modulate.a = 1.0
	wave_banner.show()

func show_practice_death(seconds: int) -> void:
	title.text = "You are dead"
	briefing.text = "Respawning in %d…" % seconds
	play_button.hide()
	overlay.color = Color("#0c140f")
	overlay.show()

func show_end(won: bool) -> void:
	wave_banner.hide()
	announcement_left = 0.0
	title.text = "Outpost held" if won else "Outpost breached"
	var progress := "All %d waves cleared." % game.WAVE_COUNTS.size() if won else "A Tan crossed the perimeter on Wave %d." % game.wave
	briefing.text = "%s %d Tans stopped. %d of %d Greens standing." % [progress, game.kills, game.greens.size(), game.GREEN_COUNT]
	play_button.show()
	overlay.color = Color("#0d1a13ac")
	overlay.show()

func sync_wave(delta: float) -> void:
	if game.is_practice():
		wave_label.text = "PRACTICE RANGE"
		wave_detail.text = "PINE HOLLOW  ·  %d TANS LEFT" % game.tans.size()
		intermission_label.text = ""
		return
	if game.wave <= 0:
		return
	var down: int = game.WAVE_COUNTS[game.wave - 1] - game.tans.size()
	wave_label.text = "WAVE %d / %d" % [game.wave, game.WAVE_COUNTS.size()]
	wave_detail.text = "%d DOWN  ·  %d LEFT" % [down, game.tans.size()]
	intermission_label.text = "NEXT IN %ds" % ceili(game.intermission_left) if game.intermission_left > 0.0 else ""
	if announcing_clear and game.intermission_left > 0.0:
		banner_detail.text = "Next wave in %ds" % ceili(game.intermission_left)
	if root.visible and announcement_left > 0.0:
		announcement_left = maxf(announcement_left - delta, 0.0)
		wave_banner.modulate.a = smoothstep(0.0, 0.55, announcement_left)
		wave_banner.visible = announcement_left > 0.0

func sync(delta := 0.0) -> void:
	var scoped: bool = game.playing and game.sniper_scope_visible() and not get_tree().paused
	scope.visible = scoped
	root.visible = not game.at_title and game.follow.is_empty() and not scoped
	shell_hint.visible = not game.at_title and not game.follow.is_empty()
	kill_feed.visible = not game.at_title and not scoped
	update_kill_feed(delta)
	sync_wave(delta)
	var azimuth: int = game.azimuth_mils(game.heading)
	var elevation_mil: int = game.elevation_mils(game.elevation)
	if azimuth != shown_azimuth:
		shown_azimuth = azimuth
		azimuth_readout.text = "%04d" % azimuth
		azimuth_tape.queue_redraw()
	if elevation_mil != shown_elevation:
		shown_elevation = elevation_mil
		elevation_readout.text = "%04d" % elevation_mil
		elevation_tape.queue_redraw()
	heading_slider.set_value_no_signal(game.heading)
	elevation_slider.set_value_no_signal(game.elevation)
	total_label.text = "%d TANS DOWN TOTAL" % game.kills
	greens_label.text = "%d / %d GREENS" % [game.greens.size(), game.GREEN_COUNT]
	total_label.visible = not game.is_practice()
	greens_label.visible = not game.is_practice()
	report_label.text = game.report
	gunner_controls.visible = not game.observing and not game.sniper_mode
	observer_controls.visible = game.observing and not game.sniper_mode
	sniper_controls.visible = game.can_use_loadout() and not game.loadout_open
	if sniper_controls.visible:
		var weapon: int = game.loadout.equipped()
		if weapon == LOADOUT.Item.EMPTY:
			sniper_status.text = "UNARMED"
			sniper_aim_hint.text = "1–5 select a loadout slot"
		else:
			var marksman := game.sniper as TOY_MARKSMAN
			var rounds := marksman.magazine_rounds(weapon)
			var ammo := "%d/%d" % [rounds, marksman.magazine_size(weapon)]
			sniper_status.text = "%s  ·  %s" % [LOADOUT.ITEM_NAMES[weapon], ammo]
			var action_text := ""
			if marksman.reload_left > 0.0:
				action_text = "Reloading  ·  %.1fs" % marksman.reload_left
			elif rounds == 0:
				action_text = "R or click to reload"
			elif weapon == LOADOUT.Item.M40 and marksman.action != TOY_MARKSMAN.Action.READY:
				action_text = "Click to cycle" if marksman.action == TOY_MARKSMAN.Action.SPENT else "Cycling"
			sniper_aim_hint.text = action_text if not action_text.is_empty() else (
				"Shift focus  ·  LMB fire  ·  R reload" if game.sniper_scoped
				else "RMB aim  ·  LMB fire  ·  R reload")
			if scoped:
				scope_action.text = ammo if action_text.is_empty() else "%s  ·  %s" % [ammo, action_text]
				scope_zoom_label.text = "%d×  ·  %d m zero" % [game.sniper_zoom(), game.sniper_zero_distance()]
	inventory.sync()
	binocular_mask.visible = game.binoculars_visible()
	if game.binoculars_visible():
		binocular_heading.text = "DIR %04d" % game.observer_radio.heading(game.observer_yaw)
	binocular_heading.visible = not game.coop.in_match()
	radio_panel.visible = game.observing and not game.sniper_mode and game.playing and not game.coop.in_match()
	ride_button.visible = not game.coop.in_match()
	effect_button.visible = not game.coop.in_match()
	if radio_panel.visible:
		var radio: Node = game.observer_radio
		radio_status.text = "Listening … release V to send" if radio.voice.listening else (
			"Reading your call …" if radio.voice.transcribing else radio.status)
		var transcript: String = radio.voice.last_transcript
		radio_transcript.visible = not transcript.is_empty() and not radio_typing()
		radio_input_check.visible = radio_transcript.visible and not radio.voice_input_check.is_empty()
		if radio_input_check.visible:
			radio_input_check.text = radio.voice_input_check
		if radio_transcript.visible:
			radio_transcript.text = "Heard: " + transcript.replace("\n", " ").replace("\r", " ").replace("\t", " ")
	observer_title.text = "BINOCULARS  ·  %d×" % game.binocular_zoom() if game.binoculars_visible() else "GREEN OUTPOST"
	observer_look_hint.text = "WASD move  ·  Shift sprint  ·  Space hop"
	observer_view_hint.text = "Scroll to zoom  ·  Right-click to lower" if game.binoculars else "Right-click binoculars  ·  P view"
	observer_return_button.visible = not game.is_practice() and not game.coop.in_match()
	observer_button.visible = not game.coop.in_match()
	observer_button.disabled = not game.observer_available()
	airburst_button.text = "Airburst  ·  %d left" % game.airburst_left
	airburst_button.disabled = game.airburst_left == 0
	crate_label.text = "Crate %d/%d   ·   A/D direction   W/S elevation   Shift fine aim   ·   P view" % [game.rounds_ready, game.CRATE_ROUNDS]
	var ready_to_fire: bool = game.can_fire()
	fire_button.disabled = not ready_to_fire
	if game.trigger_time > 0.0:
		fire_button.text = "Firing…"
	elif game.resupply_time > 0.0:
		fire_button.text = "Restock %.1fs" % game.resupply_time
	elif game.cooldown > 0.0:
		fire_button.text = "Ready in %.1fs" % game.cooldown
	else:
		fire_button.text = "Fire  [Space]"
	var state := str(game.tank_view) + str(game.airburst_selected)
	if state != cached_state:
		shade(ride_button, game.tank_view)
		shade(effect_button, not game.tank_view)
		shade(he_button, not game.airburst_selected)
		shade(airburst_button, game.airburst_selected)
		shade(fire_button, true)
		cached_state = state

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if game.can_use_loadout() and not get_tree().paused and event.pressed and not event.echo:
		var key: int = event.physical_keycode
		if (key == KEY_F or (game.loadout_open and key == KEY_ESCAPE)) and game.toggle_loadout():
			get_viewport().set_input_as_handled()
			return
		if key == KEY_R:
			game.reload_rifle()
			get_viewport().set_input_as_handled()
			return
		if key >= KEY_1 and key <= KEY_5:
			game.select_loadout_slot(key - KEY_1)
			get_viewport().set_input_as_handled()
			return
	if game.loadout_open:
		get_viewport().set_input_as_handled()
		return
	if radio_typing():
		if event.physical_keycode == KEY_ESCAPE and event.pressed:
			close_radio_entry()
			get_viewport().set_input_as_handled()
		return
	if event.physical_keycode == KEY_V and game.observer_radio.active():
		if not event.echo:
			game.observer_radio.listen(event.pressed)
		get_viewport().set_input_as_handled()
		return
	if event.physical_keycode == KEY_T and event.pressed and not event.echo and game.observer_radio.active():
		game.observer_radio.voice.cancel()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		radio_entry.text = ""
		radio_entry.show()
		radio_entry.grab_focus()
		get_viewport().set_input_as_handled()
		return
	if event.physical_keycode not in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		return
	get_viewport().set_input_as_handled()
	if event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_UP: game.adjust_sniper_zero(1)
			KEY_DOWN: game.adjust_sniper_zero(-1)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	if radio_typing():
		return
	if event.physical_keycode == KEY_ESCAPE:
		if event.echo:
			return
		if settings_overlay.visible:
			close_settings()
			get_viewport().set_input_as_handled()
		elif game.toggle_pause():
			get_viewport().set_input_as_handled()
		return
	if get_tree().paused or not game.playing or game.coop_controls_locked():
		return
	if game.observing and event.physical_keycode == KEY_SPACE:
		if not event.echo:
			game.hop_observer()
		get_viewport().set_input_as_handled()
		return
	if event.physical_keycode == KEY_P:
		if not event.echo:
			game.toggle_first_person()
		get_viewport().set_input_as_handled()
		return
	if event.physical_keycode == KEY_O:
		if not event.echo:
			game.toggle_observer()
		get_viewport().set_input_as_handled()
		return
	if game.observing or game.sniper_mode:
		return
	var horizontal := 1.0 / float(game.AZIMUTH_MILS_PER_STEP) if event.shift_pressed else 1.0
	var vertical := 1.0 / float(game.ELEVATION_MILS_PER_STEP) if event.shift_pressed else 1.0
	match event.physical_keycode:
		KEY_A: game.aim(-horizontal, 0)
		KEY_D: game.aim(horizontal, 0)
		KEY_W: game.aim(0, vertical)
		KEY_S: game.aim(0, -vertical)
		KEY_SPACE:
			if not event.echo:
				game.fire()
		KEY_C:
			if not event.echo:
				game.set_view(not game.tank_view)
		_: return
	get_viewport().set_input_as_handled()

