class_name HUD
extends CanvasLayer

# Reads state from Main and the player(s) each frame.

const SEED_DOT_RADIUS := 7
const SEED_SLOT_WIDTH := 18

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
var day_panel: Control
var day_panel_label: Label

func _ready() -> void:
	layer = 10
	# Top status bar
	var top_bg := ColorRect.new()
	top_bg.size = Vector2(1280, 40)
	top_bg.color = Color(0, 0, 0, 0.55)
	add_child(top_bg)
	money_label = _mk("$0", Vector2(20, 8), 20)
	add_child(money_label)
	day_label = _mk("Day 1", Vector2(200, 8), 20)
	add_child(day_label)
	time_label = _mk("5:00", Vector2(360, 8), 20)
	add_child(time_label)
	rent_label = _mk("Rent: $40", Vector2(520, 8), 20)
	add_child(rent_label)
	# Bottom bar — seed pouch (left), holding (center), watering can (right).
	var bot_bg := ColorRect.new()
	bot_bg.size = Vector2(1280, 70)
	bot_bg.position = Vector2(0, 650)
	bot_bg.color = Color(0, 0, 0, 0.55)
	add_child(bot_bg)
	# ── Seed pouch (bottom-left) ─────────────────────────────────────
	add_child(_mk("Seeds  (1/2/3 plant by type, F LIFO)", Vector2(20, 658), 14))
	var pouch_bg := ColorRect.new()
	pouch_bg.size = Vector2(SEED_SLOT_WIDTH * 10 + 8, 22)
	pouch_bg.position = Vector2(20, 680)
	pouch_bg.color = Color(0, 0, 0, 0.45)
	add_child(pouch_bg)
	seed_root = Node2D.new()
	seed_root.position = Vector2(20, 680)
	add_child(seed_root)
	for i in 10:
		var slot_bg := ColorRect.new()
		slot_bg.size = Vector2(SEED_SLOT_WIDTH - 4, 18)
		slot_bg.position = Vector2(4 + i * SEED_SLOT_WIDTH, 2)
		slot_bg.color = Color(1, 1, 1, 0.08)
		seed_root.add_child(slot_bg)
		var dot := Interactable.make_circle(SEED_DOT_RADIUS, Color.WHITE, 16)
		dot.position = Vector2(4 + i * SEED_SLOT_WIDTH + (SEED_SLOT_WIDTH - 4) / 2, 11)
		dot.visible = false
		seed_root.add_child(dot)
		seed_dots.append(dot)
	# ── Holding label (center) ───────────────────────────────────────
	holding_label = _mk("Holding: nothing", Vector2(240, 658), 14)
	holding_label.size = Vector2(720, 50)
	holding_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(holding_label)
	# ── Watering can (bottom-right) ──────────────────────────────────
	add_child(_mk("Watering can", Vector2(1060, 658), 14))
	var wbg := ColorRect.new()
	wbg.size = Vector2(200, 16)
	wbg.position = Vector2(1060, 682)
	wbg.color = Color(0, 0, 0, 0.5)
	add_child(wbg)
	water_bar = ColorRect.new()
	water_bar.size = Vector2(200, 16)
	water_bar.position = Vector2(1060, 682)
	water_bar.color = Color(0.30, 0.70, 1.00)
	add_child(water_bar)
	water_text = _mk("0 / 0", Vector2(1060, 681), 12)
	water_text.size = Vector2(200, 18)
	water_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(water_text)
	# ── Floating action hint above the bottom bar ────────────────────
	hint_label = _mk("", Vector2(0, 614), 20)
	hint_label.size = Vector2(1280, 30)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_color", Color(1, 1, 0.6))
	add_child(hint_label)

func _mk(txt: String, pos: Vector2, sz: int) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", Color.WHITE)
	return l

func _process(_delta: float) -> void:
	if game == null:
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
	# Holding (count + breakdown by type)
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
		holding_label.text = "Holding: %d cut flower%s\n%s" % [
			p.cut_flower_count(),
			"" if p.cut_flower_count() == 1 else "s",
			breakdown,
		]
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
	day_panel.size = Vector2(1280, 720)
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
	panel.size = Vector2(1280, 720)
	add_child(panel)
	var dim := ColorRect.new()
	dim.size = Vector2(1280, 720)
	dim.color = Color(0, 0, 0, 0.75)
	panel.add_child(dim)
	var title := Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	title.position = Vector2(0, 220)
	title.size = Vector2(1280, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	var sub := Label.new()
	sub.text = "Couldn't pay rent — survived %d day%s" % [days_survived, "" if days_survived == 1 else "s"]
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color.WHITE)
	sub.position = Vector2(0, 320)
	sub.size = Vector2(1280, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(sub)
	var prompt := Label.new()
	prompt.text = "Press R to restart"
	prompt.add_theme_font_size_override("font_size", 18)
	prompt.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	prompt.position = Vector2(0, 380)
	prompt.size = Vector2(1280, 30)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(prompt)
