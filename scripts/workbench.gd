class_name Workbench
extends Interactable

# Holds cut flowers waiting to be assembled into a bouquet.
# Inventory is per-type counts; bouquets are arrays of Type ints, sorted.

const VISUAL_WIDTH := 280.0
const VISUAL_HEIGHT := 80.0
const BODY_WIDTH := 240.0
const BODY_HEIGHT := 60.0

var game  # Main reference; needed to forward bouquets to the counter
var inventory: Array = [0, 0, 0]
var ui_open_for: Player = null

var inv_labels: Array = []

func _ready() -> void:
	radius = 70.0
	super._ready()
	# Solid body — player works around the workbench, can't walk through.
	add_solid_rect(Vector2(BODY_WIDTH, BODY_HEIGHT), Vector2(0, 0))
	# Tan top
	add_child(make_rect(Vector2(VISUAL_WIDTH, VISUAL_HEIGHT), Color(0.78, 0.58, 0.36),
		Vector2(-VISUAL_WIDTH / 2.0, -VISUAL_HEIGHT / 2.0)))
	# Dark front edge
	add_child(make_rect(Vector2(VISUAL_WIDTH, 6), Color(0.55, 0.40, 0.22),
		Vector2(-VISUAL_WIDTH / 2.0, -VISUAL_HEIGHT / 2.0)))
	# Dark working surface in the middle (cutting board) — solid feel.
	add_child(make_rect(Vector2(VISUAL_WIDTH - 60, VISUAL_HEIGHT - 30), Color(0.30, 0.22, 0.15),
		Vector2(-(VISUAL_WIDTH - 60) / 2.0, -(VISUAL_HEIGHT - 30) / 2.0)))
	# Title above the bench
	add_child(make_label("Workbench", Vector2(-VISUAL_WIDTH / 2.0, -VISUAL_HEIGHT / 2.0 - 24),
		VISUAL_WIDTH))
	# Inventory display along the cutting board
	for i in FlowerDB.TYPE_COUNT:
		var lbl := Label.new()
		var x_offset: float = -90.0 + i * 90.0  # spread across the bench
		lbl.position = Vector2(x_offset - 20, -18)
		lbl.size = Vector2(40, 32)
		lbl.add_theme_color_override("font_color", FlowerDB.TYPE_COLORS[i])
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(lbl)
		inv_labels.append(lbl)
	_refresh_inventory_labels()

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
