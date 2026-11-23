extends Control

const LOADOUT := preload("res://art/figures/player_loadout.gd")
const M40_ICON := preload("res://art/figures/loadout_m40.png")
const M16_ICON := preload("res://art/figures/loadout_m16.png")
const PAPER := Color("#f2ecd5")
const MUTED := Color("#b1bfa7")
const EDGE := Color("#6e805f")
const GOLD := Color("#e4ce86")
const CARD_WIDTH := 96
const CARD_HEIGHT := 66
const GAP := 8

class ItemTile extends Panel:
	var inventory: Control
	var slot := -1
	var weapon := LOADOUT.Item.EMPTY
	var highlight := false
	var name_label: Label
	var icon: TextureRect

	func _get_drag_data(_at: Vector2) -> Variant:
		if not inventory.crate.visible or weapon == LOADOUT.Item.EMPTY:
			return null
		var preview := PanelContainer.new()
		var caption := Label.new()
		caption.text = "  %s  " % LOADOUT.ITEM_NAMES[weapon]
		caption.custom_minimum_size.y = 34
		preview.add_child(caption)
		set_drag_preview(preview)
		return {"weapon": weapon, "slot": slot}

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return inventory.crate.visible and slot >= 0 and data is Dictionary 			and data.get("weapon") in LOADOUT.CRATE_ITEMS and data.has("slot")

	func _drop_data(_at: Vector2, data: Variant) -> void:
		inventory.game.move_loadout_item(data.weapon, data.slot, slot)

var game: Node3D
var crate: ColorRect
var proximity: Label
var slots: Array[ItemTile] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	crate = ColorRect.new()
	crate.color = Color("#0c1611be")
	crate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(crate)
	crate.hide()

	var panel := Panel.new()
	panel.position = Vector2(382, 170)
	panel.size = Vector2(516, 283)
	panel.add_theme_stylebox_override("panel", skin(Color("#202e24"), EDGE, 11))
	crate.add_child(panel)
	caption(panel, "Supply crate", Vector2(28, 20), 28, PAPER)
	caption(panel, "Drag a rifle to a slot below", Vector2(28, 64), 16, MUTED)
	for i in range(LOADOUT.CRATE_ITEMS.size()):
		var item: int = LOADOUT.CRATE_ITEMS[i]
		var tile := make_tile(panel, Vector2(28 + i * 239, 105), Vector2(221, 143), -1)
		set_item(tile, item, false)
		tile.icon.position = Vector2(17, 16)
		tile.icon.size = Vector2(187, 65)
		tile.name_label.position = Vector2(14, 83)
		tile.name_label.size.x = 193
		tile.name_label.add_theme_font_size_override("font_size", 19)
		var description := caption(tile, LOADOUT.ITEM_DETAILS[item], Vector2(10, 111), 14, MUTED)
		description.size.x = 201
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	caption(panel, "E / Esc close", Vector2(28, 253), 13, MUTED)

	proximity = caption(self, "F   Open supply crate", Vector2(480, 578), 16, PAPER)
	proximity.size = Vector2(320, 30)
	proximity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	proximity.add_theme_color_override("font_shadow_color", Color("#0a130b"))
	proximity.add_theme_constant_override("shadow_offset_y", 2)

	var width := CARD_WIDTH * LOADOUT.SLOT_COUNT + GAP * (LOADOUT.SLOT_COUNT - 1)
	for i in range(LOADOUT.SLOT_COUNT):
		var x := (1280.0 - width) * 0.5 + i * (CARD_WIDTH + GAP)
		var tile := make_tile(self, Vector2(x, 628), Vector2(CARD_WIDTH, CARD_HEIGHT), i)
		slots.append(tile)
		caption(tile, str(i + 1), Vector2(8, 5), 12, GOLD)
	sync()

func make_tile(parent: Control, at: Vector2, dimensions: Vector2, slot: int) -> ItemTile:
	var tile := ItemTile.new()
	tile.inventory = self
	tile.slot = slot
	parent.add_child(tile)
	tile.position = at
	tile.size = dimensions
	tile.icon = TextureRect.new()
	tile.icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tile.icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tile.icon.position = Vector2(11, 12)
	tile.icon.size = Vector2(74, 28)
	tile.add_child(tile.icon)
	tile.name_label = caption(tile, "", Vector2(3, 43), 13, PAPER)
	tile.name_label.size.x = dimensions.x - 6
	tile.name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return tile

func set_item(tile: ItemTile, item: int, selected: bool) -> void:
	if tile.name_label.text != "" and tile.weapon == item and tile.highlight == selected:
		return
	tile.weapon = item
	tile.highlight = selected
	tile.name_label.text = LOADOUT.ITEM_NAMES[item]
	tile.name_label.modulate = PAPER if item != LOADOUT.Item.EMPTY else MUTED
	tile.icon.texture = M40_ICON if item == LOADOUT.Item.M40 else (M16_ICON if item == LOADOUT.Item.M16 else null)
	tile.add_theme_stylebox_override("panel", skin(Color("#3d4c32") if selected else Color("#17231ce8"),
		GOLD if selected else EDGE, 6))

func sync() -> void:
	visible = game.can_use_loadout() and not get_tree().paused
	crate.visible = visible and game.loadout_open
	proximity.visible = visible and not crate.visible and not game.sniper_scoped and game.near_loadout_crate()
	for i in range(slots.size()):
		var tile := slots[i]
		tile.mouse_filter = Control.MOUSE_FILTER_STOP if crate.visible else Control.MOUSE_FILTER_IGNORE
		set_item(tile, game.loadout.slots[i], game.loadout.selected == i)

func skin(fill: Color, stroke: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = stroke
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color("#0b150da0")
	style.shadow_size = 3
	return style

func caption(parent: Control, words: String, at: Vector2, points: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = words
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", points)
	label.add_theme_color_override("font_color", tint)
	parent.add_child(label)
	return label
