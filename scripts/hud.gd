class_name HUD
extends CanvasLayer

# Reads state from Main and the player(s) each frame.
# Binds to existing nodes baked into main.tscn by name/position/size,
# then re-styles them (opaque bars, centered top stats, hint inside the
# bottom bar) so the .tscn can stay close to what the editor produces.

const SEED_DOT_RADIUS := 7
const SEED_SLOT_WIDTH := 18

const TOP_BAR_HEIGHT := 40.0
const BOTTOM_BAR_HEIGHT := 70.0
const BOTTOM_BAR_Y := 650.0
const VIEWPORT_WIDTH := 1280.0
const VIEWPORT_HEIGHT := 720.0

const BAR_COLOR := Color(0.16, 0.11, 0.08, 1.0)  # opaque dark brown

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
var watering_can_label: Label
var seeds_label: Label
var day_panel: Control
var day_panel_label: Label

func _ready() -> void:
	layer = 10
	if not _bind_existing_nodes():
		push_error("HUD '%s' is missing required UI children in the scene." % name)
		set_process(false)
		return
	_restyle_bars()
	_layout_top_bar()
	_layout_bottom_bar()
	_restrict_background()

func _bind_existing_nodes() -> bool:
	seed_dots.clear()
	money_label = null
	day_label = null
	time_label = null
	rent_label = null
	water_bar = null
	water_text = null
	seed_root = null
	holding_label = null
	hint_label = null
	top_bar = null
	bottom_bar = null
	watering_can_label = null
	seeds_label = null

	for child in get_children():
		if child is Label:
			var lbl := child as Label
			if lbl.text.begins_with("$"):
				money_label = lbl
			elif lbl.text.begins_with("Day"):
				day_label = lbl
			elif lbl.text.begins_with("Rent"):
				rent_label = lbl
			elif lbl.text == "Watering can":
				watering_can_label = lbl
			elif lbl.text.begins_with("Seeds"):
				seeds_label = lbl
			elif lbl.text.find("/") != -1 and lbl.position == Vector2(1060, 681):
				water_text = lbl
			elif lbl.text.begins_with("Holding"):
				holding_label = lbl
			elif lbl.position == Vector2(0, 614):
				hint_label = lbl
			elif lbl.position == Vector2(360, 8):
				time_label = lbl
		elif child is ColorRect:
			var rect := child as ColorRect
			if rect.position == Vector2(0, 0) and rect.size == Vector2(VIEWPORT_WIDTH, TOP_BAR_HEIGHT):
				top_bar = rect
			elif rect.position == Vector2(0, BOTTOM_BAR_Y) and rect.size == Vector2(VIEWPORT_WIDTH, BOTTOM_BAR_HEIGHT):
				bottom_bar = rect
			elif rect.position == Vector2(1060, 682) and rect.size == Vector2(200, 16) and rect.color.b > 0.9:
				water_bar = rect
		elif child is Node2D:
			var n2 := child as Node2D
			if n2.position == Vector2(20, 680):
				seed_root = n2

	if seed_root:
		for c in seed_root.get_children():
			if c is Polygon2D:
				seed_dots.append(c)

	return money_label != null \
		and day_label != null \
		and time_label != null \
		and rent_label != null \
		and water_bar != null \
		and water_text != null \
		and seed_root != null \
		and holding_label != null \
		and hint_label != null \
		and seed_dots.size() == 10

func _restyle_bars() -> void:
	if top_bar:
		top_bar.color = BAR_COLOR
	if bottom_bar:
		bottom_bar.color = BAR_COLOR

# Center the four top-bar stats in equal quarters.
func _layout_top_bar() -> void:
	var quarter := VIEWPORT_WIDTH / 4.0
	_center_label(money_label, 0.0, 6.0, quarter)
	_center_label(day_label, quarter, 6.0, quarter)
	_center_label(time_label, quarter * 2.0, 6.0, quarter)
	_center_label(rent_label, quarter * 3.0, 6.0, quarter)

func _center_label(lbl: Label, x: float, y: float, w: float) -> void:
	if lbl == null:
		return
	lbl.position = Vector2(x, y)
	lbl.size = Vector2(w, 28)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

# Keeps the seed pouch (left) and watering can (right) where the scene
# places them, then re-arranges the middle column so the contextual hint
# sits inside the bar (used to float above it).
#   [Seeds + pouch] [Holding line]              [Watering can]
#                   [    Hint line (big)   ]
func _layout_bottom_bar() -> void:
	if holding_label:
		holding_label.position = Vector2(240, 655)
		holding_label.size = Vector2(800, 20)
		holding_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		holding_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		holding_label.add_theme_font_size_override("font_size", 13)
		holding_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.85))
	if hint_label:
		hint_label.position = Vector2(240, 678)
		hint_label.size = Vector2(800, 36)
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		hint_label.add_theme_font_size_override("font_size", 18)
		hint_label.add_theme_color_override("font_color", Color(1.00, 0.95, 0.55))

# Shrink the green play-area Background so it visually doesn't extend
# beneath the bars (they sit cleanly above/below the play zone).
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
	if money_label == null or day_label == null or time_label == null or rent_label == null \
			or water_bar == null or water_text == null or holding_label == null \
			or hint_label == null or seed_dots.size() < 10:
		return
	money_label.text = "$%d" % game.money
	day_label.text = "Day %d" % game.day
	var t: float = max(0.0, game.time_left)
	time_label.text = "%d:%02d" % [int(t) / 60, int(t) % 60]
	if t < 30.0:
		time_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	else:
		time_label.add_theme_color_override("font_color", Color.WHITE)
	rent_label.text = "Rent: $%d" % game.rent
	var p: Player = game.player
	if p == null:
		return
	water_bar.size.x = 200.0 * (p.water / Player.CAN_CAPACITY)
	water_text.text = "%d / %d" % [int(p.water), int(Player.CAN_CAPACITY)]
	# Seed pouch — leftmost = bottom of stack, rightmost = top (next to be popped)
	for i in 10:
		var dot: Polygon2D = seed_dots[i]
		if i < p.seed_stack.size():
			dot.color = FlowerDB.TYPE_COLORS[p.seed_stack[i]]
			dot.visible = true
		else:
			dot.visible = false
	# Holding — one tidy line: "Holding 3: Red×1, Yellow×2"
	if p.has_cut_flower():
		var counts: Array = p.cut_flower_counts_by_type()
		var parts: Array = []
		for i in FlowerDB.TYPE_COUNT:
			if counts[i] > 0:
				parts.append("%s×%d" % [FlowerDB.TYPE_NAMES[i], counts[i]])
		var breakdown := ""
		for i in parts.size():
			if i > 0:
				breakdown += ", "
			breakdown += parts[i]
		holding_label.text = "Holding %d: %s" % [p.cut_flower_count(), breakdown]
	else:
		holding_label.text = "Holding: nothing"
	if p.ui_open:
		hint_label.text = ""
	else:
		hint_label.text = (p.current_interactable.get_hint(p) if p.current_interactable else "")

func show_message(text: String, duration: float = 2.0) -> void:
	if day_panel:
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
	day_panel_label = Label.new()
	day_panel_label.text = text
	day_panel_label.size = Vector2(640, 140)
	day_panel_label.position = Vector2(320, 280)
	day_panel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_panel_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	day_panel_label.add_theme_font_size_override("font_size", 24)
	day_panel_label.add_theme_color_override("font_color", Color.WHITE)
	day_panel.add_child(day_panel_label)
	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(_clear_message)

func _clear_message() -> void:
	if day_panel:
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
	title.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	title.position = Vector2(0, 220)
	title.size = Vector2(VIEWPORT_WIDTH, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	var sub := Label.new()
	sub.text = "Couldn't pay rent — survived %d day%s" % [days_survived, "" if days_survived == 1 else "s"]
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color.WHITE)
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
