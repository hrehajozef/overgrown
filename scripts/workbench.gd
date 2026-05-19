class_name Workbench
extends Interactable

# Holds cut flowers waiting to be assembled into a bouquet.
# Inventory is per-type counts; bouquets are arrays of Type ints, sorted.

const BODY_WIDTH := 240.0
const BODY_HEIGHT := 60.0
const BOUQUET_UI_SCRIPT := preload("res://scripts/bouquet_ui.gd")

var game
var inventory: Array = []
var ui_open_for: Player = null

var inv_labels: Array = []

func _ready() -> void:
	radius = 70.0
	super._ready()
	add_solid_rect(Vector2(BODY_WIDTH, BODY_HEIGHT), Vector2.ZERO)
	_ensure_inventory_shape()
	if not _bind_inventory_labels():
		push_error("Workbench '%s' is missing inventory labels in the scene." % name)
		return
	_refresh_inventory_labels()

func _ensure_inventory_shape() -> void:
	if inventory.size() == FlowerDB.TYPE_COUNT:
		return
	inventory.resize(FlowerDB.TYPE_COUNT)
	for i in range(FlowerDB.TYPE_COUNT):
		if inventory[i] == null:
			inventory[i] = 0

func _bind_inventory_labels() -> bool:
	inv_labels.clear()
	for i in range(FlowerDB.TYPE_COUNT):
		var lbl := get_node_or_null("InventoryLabel%d" % i) as Label
		if lbl == null:
			inv_labels.clear()
			return false
		inv_labels.append(lbl)
	return true

func interact(player) -> void:
	if player.has_cut_flower():
		var stack: Array = player.drain_cut_flowers()
		for t in stack:
			inventory[t] += 1
		_refresh_inventory_labels()
		AudioManager.play_sfx("flower_workbench_place")
	elif ui_open_for == null and _has_any():
		_open_bouquet_ui(player)

func get_hint(player) -> String:
	if player.has_cut_flower():
		return "[Space] Place %d flower%s" % [player.cut_flower_count(), "" if player.cut_flower_count() == 1 else "s"]
	if _has_any():
		return "[Space] Make bouquet"
	return "Bring cut flowers"

func _has_any() -> bool:
	for c in inventory:
		if c > 0:
			return true
	return false

func _refresh_inventory_labels() -> void:
	for i in range(FlowerDB.TYPE_COUNT):
		var lbl: Label = inv_labels[i]
		lbl.text = "%s\n%d" % [FlowerDB.TYPE_NAMES[i], inventory[i]]

func _open_bouquet_ui(player) -> void:
	ui_open_for = player
	player.ui_open = true
	var ui = BOUQUET_UI_SCRIPT.new()
	ui.workbench = self
	ui.player = player
	ui.game = game
	game.add_child(ui)
	AudioManager.play_sfx("workbench_modal_pop")

func close_ui() -> void:
	if ui_open_for:
		ui_open_for.ui_open = false
		ui_open_for = null

func consume_bouquet(bouquet: Array) -> bool:
	var counts: Array = []
	counts.resize(FlowerDB.TYPE_COUNT)
	for i in range(FlowerDB.TYPE_COUNT):
		counts[i] = 0
	for t in bouquet:
		counts[t] += 1
	for i in range(FlowerDB.TYPE_COUNT):
		if inventory[i] < counts[i]:
			return false
	for i in range(FlowerDB.TYPE_COUNT):
		inventory[i] -= counts[i]
	_refresh_inventory_labels()
	return true
