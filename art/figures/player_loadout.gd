extends RefCounted

enum Item { EMPTY, M40, M16 }

const SLOT_COUNT := 5
const CRATE_ITEMS := [Item.M40, Item.M16]
const ITEM_NAMES := {Item.EMPTY: "Empty", Item.M40: "M40", Item.M16: "M16"}
const ITEM_DETAILS := {Item.M40: "Scoped rifle", Item.M16: "Iron-sight rifle"}

var slots: Array[int] = [Item.M40, Item.EMPTY, Item.EMPTY, Item.EMPTY, Item.EMPTY]
var selected := 0

func equipped() -> Item:
	return slots[selected] as Item

func move_item(item: int, from_slot: int, to_slot: int) -> void:
	if item not in CRATE_ITEMS or to_slot < 0 or to_slot >= SLOT_COUNT:
		return
	if from_slot < 0:
		from_slot = slots.find(item)
	if from_slot >= SLOT_COUNT or from_slot == to_slot:
		return
	if from_slot >= 0:
		if slots[from_slot] != item:
			return
		slots[from_slot] = slots[to_slot]
	slots[to_slot] = item
