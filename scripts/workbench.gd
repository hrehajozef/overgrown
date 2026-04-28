class_name Workbench
extends Interactable

# Holds cut flowers waiting to be assembled into a bouquet.
# Inventory is per-type counts; bouquets are arrays of Type ints, sorted.

const VISUAL_WIDTH := 280.0
const VISUAL_HEIGHT := 80.0
const BODY_WIDTH := 240.0
const BODY_HEIGHT := 60.0

var game # Main reference; needed to forward bouquets to the counter
var inventory: Array = [0, 0, 0]
var ui_open_for: Player = null

var inv_labels: Array = []

func _ready() -> void:
	radius = 70.0
	super._ready()
	# Solid body — player works around the workbench, can't walk through.
	add_solid_rect(Vector2(BODY_WIDTH, BODY_HEIGHT), Vector2(0, 0))
	if not _bind_existing_inventory_labels():
		push_error("Workbench '%s' is missing inventory labels in the scene." % name)
		return
	_refresh_inventory_labels()

func _bind_existing_inventory_labels() -> bool:
	inv_labels.clear()
	for child in get_children():
		if child is Label:
			var lbl := child as Label
			if lbl.text.find("\n") != -1:
				inv_labels.append(lbl)
	if inv_labels.size() == FlowerDB.TYPE_COUNT:
		return true
	inv_labels.clear()
	return false

func interact(player) -> void:
	if player.has_cut_flower():
		var stack: Array = player.drain_cut_flowers()
		for t in stack:
			inventory[t] += 1
		_refresh_inventory_labels()
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
	for i in FlowerDB.TYPE_COUNT:
		var l: Label = inv_labels[i]
		l.text = "%s\n%d" % [FlowerDB.TYPE_NAMES[i].substr(0, 1), inventory[i]]

func _open_bouquet_ui(player) -> void:
	ui_open_for = player
	player.ui_open = true
	var ui_script: GDScript = preload("res://scripts/bouquet_ui.gd")
	var ui = ui_script.new()
	ui.workbench = self
	ui.player = player
	ui.game = game
	game.add_child(ui)

func close_ui() -> void:
	if ui_open_for:
		ui_open_for.ui_open = false
		ui_open_for = null

func consume_bouquet(bouquet: Array) -> bool:
	var counts := [0, 0, 0]
	for t in bouquet:
		counts[t] += 1
	for i in FlowerDB.TYPE_COUNT:
		if inventory[i] < counts[i]:
			return false
	for i in FlowerDB.TYPE_COUNT:
		inventory[i] -= counts[i]
	_refresh_inventory_labels()
	return true
