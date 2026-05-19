class_name HUD
extends CanvasLayer

# Reads state from Main and the player each frame.

const TOP_BAR_HEIGHT := 40.0
const BOTTOM_BAR_Y := 650.0
const VIEWPORT_WIDTH := 1280.0
const VIEWPORT_HEIGHT := 720.0
const WATER_BAR_WIDTH := 200.0

const BAR_COLOR := Color(0.16, 0.11, 0.08, 1.0)
const TIME_WARNING_COLOR := Color(1.0, 0.4, 0.4)
const DEFAULT_TEXT_COLOR := Color.WHITE

var game

var money_label: Label
var day_label: Label
var time_label: Label
var rent_label: Label
var water_bar: ColorRect
var water_text: Label
var seed_root: Node2D
var seed_dots: Array = []
var holding_label: Label
var hint_label: Label
var top_bar: ColorRect
var bottom_bar: ColorRect
var day_panel: Control

func _ready() -> void:
	layer = 10
	if not _bind_nodes():
		push_error("HUD '%s' is missing required UI children in the scene." % name)
		set_process(false)
		return
	_restyle_bars()
	_layout_top_bar()
	_layout_bottom_bar()
	_restrict_background()

func _bind_nodes() -> bool:
	top_bar = get_node_or_null("TopBar") as ColorRect
	money_label = get_node_or_null("MoneyLabel") as Label
	day_label = get_node_or_null("DayLabel") as Label
	time_label = get_node_or_null("TimeLabel") as Label
	rent_label = get_node_or_null("RentLabel") as Label
	bottom_bar = get_node_or_null("BottomBar") as ColorRect
	seed_root = get_node_or_null("SeedRoot") as Node2D
	holding_label = get_node_or_null("HoldingLabel") as Label
	water_bar = get_node_or_null("WaterBar") as ColorRect
	water_text = get_node_or_null("WaterText") as Label
	hint_label = get_node_or_null("HintLabel") as Label

	seed_dots.clear()
	if seed_root != null:
		for child in seed_root.get_children():
			if child is Polygon2D:
				seed_dots.append(child)

	return top_bar != null \
		and money_label != null \
		and day_label != null \
		and time_label != null \
		and rent_label != null \
		and bottom_bar != null \
		and seed_root != null \
		and holding_label != null \
		and water_bar != null \
		and water_text != null \
		and hint_label != null \
		and seed_dots.size() == 10

func _restyle_bars() -> void:
	top_bar.color = BAR_COLOR
	bottom_bar.color = BAR_COLOR

func _layout_top_bar() -> void:
	var quarter := VIEWPORT_WIDTH / 4.0
	_center_label(money_label, 0.0, 6.0, quarter)
	_center_label(day_label, quarter, 6.0, quarter)
	_center_label(time_label, quarter * 2.0, 6.0, quarter)
	_center_label(rent_label, quarter * 3.0, 6.0, quarter)

func _center_label(lbl: Label, x: float, y: float, width: float) -> void:
	lbl.position = Vector2(x, y)
	lbl.size = Vector2(width, 28.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _layout_bottom_bar() -> void:
	holding_label.position = Vector2(240, 655)
	holding_label.size = Vector2(800, 20)
	holding_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	holding_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holding_label.add_theme_font_size_override("font_size", 13)
	holding_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.85))

	hint_label.position = Vector2(240, 678)
	hint_label.size = Vector2(800, 36)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55))

func _restrict_background() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var bg := parent.get_node_or_null("Background")
	if bg is ColorRect:
		var rect := bg as ColorRect
		rect.position = Vector2(0, TOP_BAR_HEIGHT)
		rect.size = Vector2(VIEWPORT_WIDTH, BOTTOM_BAR_Y - TOP_BAR_HEIGHT)

func _process(_delta: float) -> void:
	if game == null:
		return

	money_label.text = "$%d" % game.money
	day_label.text = "Day %d" % game.day

	var t: float = max(0.0, game.time_left)
	time_label.text = "%d:%02d" % [int(t) / 60, int(t) % 60]
	time_label.add_theme_color_override("font_color", TIME_WARNING_COLOR if t < 30.0 else DEFAULT_TEXT_COLOR)

	rent_label.text = "Rent: $%d" % game.rent

	var p: Player = game.player
	if p == null:
		return

	water_bar.size.x = WATER_BAR_WIDTH * (p.water / Player.CAN_CAPACITY)
	water_text.text = "%d / %d" % [int(p.water), int(Player.CAN_CAPACITY)]

	for i in range(seed_dots.size()):
		var dot: Polygon2D = seed_dots[i]
		if i < p.seed_stack.size():
			dot.color = FlowerDB.TYPE_COLORS[p.seed_stack[i]]
			dot.visible = true
		else:
			dot.visible = false

	if p.has_cut_flower():
		var counts: Array = p.cut_flower_counts_by_type()
		var parts: Array = []
		for i in range(FlowerDB.TYPE_COUNT):
			if counts[i] > 0:
				parts.append("%sx%d" % [FlowerDB.TYPE_NAMES[i], counts[i]])
		var breakdown := ""
		for i in range(parts.size()):
			if i > 0:
				breakdown += ", "
			breakdown += parts[i]
		holding_label.text = "Holding %d: %s" % [p.cut_flower_count(), breakdown]
	else:
		holding_label.text = "Holding: nothing"

	if p.ui_open:
		hint_label.text = ""
	else:
		hint_label.text = p.current_interactable.get_hint(p) if p.current_interactable else ""

func show_message(text: String, duration: float = 2.0) -> void:
	if day_panel != null:
		day_panel.queue_free()

	day_panel = Control.new()
	day_panel.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	day_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(day_panel)

	var bg := ColorRect.new()
	bg.size = Vector2(640, 140)
	bg.position = Vector2(320, 280)
	bg.color = Color(0, 0, 0, 0.7)
	day_panel.add_child(bg)

	var label := Label.new()
	label.text = text
	label.size = Vector2(640, 140)
	label.position = Vector2(320, 280)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", DEFAULT_TEXT_COLOR)
	day_panel.add_child(label)

	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(_clear_message)

func _clear_message() -> void:
	if day_panel != null:
		day_panel.queue_free()
		day_panel = null

func show_game_over(days_survived: int) -> void:
	var panel := Control.new()
	panel.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	add_child(panel)

	var dim := ColorRect.new()
	dim.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	dim.color = Color(0, 0, 0, 0.75)
	panel.add_child(dim)

	var title := Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", TIME_WARNING_COLOR)
	title.position = Vector2(0, 220)
	title.size = Vector2(VIEWPORT_WIDTH, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	var sub := Label.new()
	sub.text = "Couldn't pay rent - survived %d day%s" % [days_survived, "" if days_survived == 1 else "s"]
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", DEFAULT_TEXT_COLOR)
	sub.position = Vector2(0, 320)
	sub.size = Vector2(VIEWPORT_WIDTH, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(sub)

	var prompt := Label.new()
	prompt.text = "Press R to restart"
	prompt.add_theme_font_size_override("font_size", 18)
	prompt.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	prompt.position = Vector2(0, 380)
	prompt.size = Vector2(VIEWPORT_WIDTH, 30)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(prompt)
