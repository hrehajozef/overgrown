extends CanvasLayer

# Modal panel for assembling a bouquet from a Workbench's inventory.
# Backdrop is fully transparent — only the centred panel itself is opaque,
# so the player can still see what is happening in the shop behind it.
# 1/2/3 add by type, Backspace remove last, Enter confirm, Esc cancel.

const MAX_BOUQUET := 5
const PANEL_W := 680.0
const PANEL_H := 470.0
const CARD_W := 200.0
const CARD_H := 138.0
const CARD_PAD := 14.0
const CARD_TOP := 92.0
const DOT_R := 13.0

# Visual palette — picked so the panel reads as a small, warm workshop card.
const PANEL_BG := Color(0.115, 0.115, 0.150, 0.98)
const PANEL_BORDER := Color(0.68, 0.54, 0.32, 0.55)
const TEXT_PRIMARY := Color(0.97, 0.95, 0.90)
const TEXT_MUTED := Color(0.68, 0.68, 0.74)
const TEXT_HEADER := Color(0.97, 0.86, 0.62)
const ACCENT_CONFIRM := Color(0.78, 0.58, 0.30)
const ACCENT_CANCEL := Color(0.28, 0.28, 0.34)
const ACCENT_REMOVE := Color(0.50, 0.24, 0.26)

var workbench: Workbench
var player: Player
var game

var current_bouquet: Array = []
var panel: Panel
var bouquet_dots_root: Node2D
var bouquet_text: Label
var price_label: Label
var card_visuals: Array = []  # array of {btn, status, count_badge}

func _ready() -> void:
	layer = 100
	# No backdrop ColorRect — game world remains fully visible behind.
	var panel_x: float = (1280.0 - PANEL_W) / 2.0
	var panel_y: float = (720.0 - PANEL_H) / 2.0 - 20.0
	# Soft drop shadow under the panel
	var shadow := ColorRect.new()
	shadow.size = Vector2(PANEL_W + 22, PANEL_H + 28)
	shadow.position = Vector2(panel_x - 11, panel_y - 6)
	shadow.color = Color(0, 0, 0, 0.32)
	add_child(shadow)
	# Panel
	panel = Panel.new()
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.position = Vector2(panel_x, panel_y)
	panel.add_theme_stylebox_override("panel", _styled_panel(PANEL_BG, PANEL_BORDER, 14, 1))
	add_child(panel)
	# Title row
	var title := _make_text("Compose bouquet", Vector2(28, 18), Vector2(PANEL_W - 56, 36), 26, TEXT_HEADER, HORIZONTAL_ALIGNMENT_LEFT)
	panel.add_child(title)
	var subtitle := _make_text("Pick flowers — click a card or press 1 / 2 / 3", Vector2(28, 58), Vector2(PANEL_W - 56, 18), 13, TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	panel.add_child(subtitle)
	# Thin divider under header
	var div := ColorRect.new()
	div.size = Vector2(PANEL_W - 56, 1)
	div.position = Vector2(28, 82)
	div.color = Color(1, 1, 1, 0.06)
	panel.add_child(div)
	# Flower cards
	for i in FlowerDB.TYPE_COUNT:
		var card_x: float = 28.0 + i * (CARD_W + CARD_PAD)
		card_visuals.append(_make_card(panel, i, card_x, CARD_TOP))
	# Bouquet preview block
	var by: float = CARD_TOP + CARD_H + 18.0  # ~248
	var bouquet_lbl := _make_text("Your bouquet", Vector2(28, by), Vector2(220, 18), 14, TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	panel.add_child(bouquet_lbl)
	# Dots row
	bouquet_dots_root = Node2D.new()
	bouquet_dots_root.position = Vector2(28, by + 36)
	panel.add_child(bouquet_dots_root)
	# Breakdown text
	bouquet_text = _make_text("", Vector2(28, by + 72), Vector2(PANEL_W - 56 - 180, 22), 14, TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_LEFT)
	panel.add_child(bouquet_text)
	# Price (right side of bouquet block)
	price_label = _make_text("", Vector2(PANEL_W - 210, by + 20), Vector2(180, 50), 30, Color(0.97, 0.83, 0.42), HORIZONTAL_ALIGNMENT_RIGHT)
	panel.add_child(price_label)
	# Divider above buttons
	var div2 := ColorRect.new()
	div2.size = Vector2(PANEL_W - 56, 1)
	div2.position = Vector2(28, by + 110)
	div2.color = Color(1, 1, 1, 0.06)
	panel.add_child(div2)
	# Action buttons
	var btn_y: float = by + 124
	_make_btn(panel, "Remove last  ⌫", Vector2(28, btn_y), Vector2(170, 46), ACCENT_REMOVE, _on_remove)
	_make_btn(panel, "Cancel  Esc", Vector2(208, btn_y), Vector2(140, 46), ACCENT_CANCEL, _on_cancel)
	_make_btn(panel, "Make bouquet  ↵", Vector2(358, btn_y), Vector2(PANEL_W - 28 - 358, 46), ACCENT_CONFIRM, _on_confirm)
	_refresh()

# ── Builders ──────────────────────────────────────────────────────────

func _styled_panel(bg: Color, border: Color, radius: int, border_w: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = border_w
	sb.border_width_right = border_w
	sb.border_width_top = border_w
	sb.border_width_bottom = border_w
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 0
	return sb

func _make_text(text: String, pos: Vector2, sz: Vector2, font_size: int, col: Color, halign: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = sz
	l.horizontal_alignment = halign
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	return l

func _make_card(parent_panel: Panel, t: int, x: float, y: float) -> Dictionary:
	var root := Control.new()
	root.position = Vector2(x, y)
	root.size = Vector2(CARD_W, CARD_H)
	parent_panel.add_child(root)
	# Background button covers the whole card so the entire surface is clickable.
	var btn := Button.new()
	btn.size = Vector2(CARD_W, CARD_H)
	btn.flat = false
	var type_col: Color = FlowerDB.TYPE_COLORS[t]
	var bg: Color = type_col.lerp(PANEL_BG, 0.72)
	var border: Color = type_col.darkened(0.05)
	btn.add_theme_stylebox_override("normal", _styled_panel(bg, border, 12, 2))
	btn.add_theme_stylebox_override("hover", _styled_panel(type_col.lerp(PANEL_BG, 0.55), border, 12, 2))
	btn.add_theme_stylebox_override("pressed", _styled_panel(type_col.lerp(PANEL_BG, 0.38), border, 12, 2))
	btn.add_theme_stylebox_override("disabled", _styled_panel(Color(0.14, 0.14, 0.17, 0.9), Color(0.30, 0.30, 0.35, 0.7), 12, 1))
	btn.pressed.connect(_on_add.bind(t))
	root.add_child(btn)
	# Key hint (top-right)
	var key_lbl := _make_text("[%d]" % (t + 1), Vector2(CARD_W - 42, 8), Vector2(34, 18), 14, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_RIGHT)
	key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(key_lbl)
	# Color swatch
	var swatch := Polygon2D.new()
	var pts := PackedVector2Array()
	var n := 28
	for i in n:
		var a: float = i * TAU / n
		pts.append(Vector2(cos(a), sin(a)) * 22.0)
	swatch.polygon = pts
	swatch.color = type_col
	swatch.position = Vector2(CARD_W / 2.0, 46)
	root.add_child(swatch)
	# Inner highlight on swatch — a smaller, lighter circle near top-left
	var hl := Polygon2D.new()
	var hl_pts := PackedVector2Array()
	for i in n:
		var a: float = i * TAU / n
		hl_pts.append(Vector2(cos(a), sin(a)) * 6.0)
	hl.polygon = hl_pts
	hl.color = Color(1, 1, 1, 0.30)
	hl.position = Vector2(CARD_W / 2.0 - 8, 38)
	root.add_child(hl)
	# Name
	var name_lbl := _make_text(FlowerDB.TYPE_NAMES[t], Vector2(0, 80), Vector2(CARD_W, 22), 18, TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(name_lbl)
	# Status
	var status_lbl := _make_text("", Vector2(0, 108), Vector2(CARD_W, 18), 12, TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(status_lbl)
	# Used-count badge (top-left circle with number)
	var badge_root := Control.new()
	badge_root.position = Vector2(8, 8)
	badge_root.size = Vector2(28, 22)
	badge_root.visible = false
	badge_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(badge_root)
	var badge_bg := ColorRect.new()
	badge_bg.size = Vector2(28, 22)
	badge_bg.color = Color(0.97, 0.83, 0.42, 0.95)
	badge_root.add_child(badge_bg)
	var badge_lbl := _make_text("", Vector2(0, 0), Vector2(28, 22), 13, Color(0.15, 0.10, 0.05), HORIZONTAL_ALIGNMENT_CENTER)
	badge_root.add_child(badge_lbl)
	return {
		"btn": btn,
		"status": status_lbl,
		"badge_root": badge_root,
		"badge_label": badge_lbl,
	}

func _make_btn(parent_panel: Panel, text: String, pos: Vector2, sz: Vector2, col: Color, callable: Callable) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size = sz
	btn.text = text
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.58))
	btn.add_theme_stylebox_override("normal", _styled_panel(col, col.lightened(0.12), 9, 1))
	btn.add_theme_stylebox_override("hover", _styled_panel(col.lightened(0.08), col.lightened(0.20), 9, 1))
	btn.add_theme_stylebox_override("pressed", _styled_panel(col.darkened(0.10), col.darkened(0.05), 9, 1))
	btn.add_theme_stylebox_override("disabled", _styled_panel(Color(0.20, 0.20, 0.22, 0.9), Color(0.30, 0.30, 0.35, 0.7), 9, 1))
	btn.pressed.connect(callable)
	parent_panel.add_child(btn)
	return btn

# ── State ────────────────────────────────────────────────────────────

func _refresh() -> void:
	for i in FlowerDB.TYPE_COUNT:
		var data: Dictionary = card_visuals[i]
		var btn: Button = data.btn
		var status_lbl: Label = data.status
		var badge_root: Control = data.badge_root
		var badge_lbl: Label = data.badge_label
		var avail: int = workbench.inventory[i] - current_bouquet.count(i)
		var used: int = current_bouquet.count(i)
		btn.disabled = avail <= 0 or current_bouquet.size() >= MAX_BOUQUET
		status_lbl.text = "%d available  ·  %d in bouquet" % [avail, used]
		badge_root.visible = used > 0
		badge_lbl.text = "×%d" % used
	# Dots row
	for c in bouquet_dots_root.get_children():
		c.queue_free()
	if current_bouquet.is_empty():
		bouquet_text.text = "(empty — pick at least one flower)"
		bouquet_text.add_theme_color_override("font_color", TEXT_MUTED)
		price_label.text = "—"
		price_label.add_theme_color_override("font_color", TEXT_MUTED)
	else:
		var total: int = 3  # flat tip
		for i in current_bouquet.size():
			var t: int = current_bouquet[i]
			total += FlowerDB.PRICE[t]
			var dot := _make_swatch(DOT_R, FlowerDB.TYPE_COLORS[t])
			dot.position = Vector2(DOT_R + i * (DOT_R * 2 + 10), DOT_R)
			bouquet_dots_root.add_child(dot)
			# slot empty markers for the rest of the max bouquet
		# Empty slots after the picked ones
		for j in range(current_bouquet.size(), MAX_BOUQUET):
			var empty := _make_ring(DOT_R, Color(1, 1, 1, 0.12))
			empty.position = Vector2(DOT_R + j * (DOT_R * 2 + 10), DOT_R)
			bouquet_dots_root.add_child(empty)
		# Breakdown
		var counts := [0, 0, 0]
		for t in current_bouquet:
			counts[t] += 1
		var parts: Array = []
		for i in FlowerDB.TYPE_COUNT:
			if counts[i] > 0:
				parts.append("%s × %d" % [FlowerDB.TYPE_NAMES[i], counts[i]])
		var s := ""
		for i in parts.size():
			if i > 0:
				s += "   ·   "
			s += parts[i]
		bouquet_text.text = s
		bouquet_text.add_theme_color_override("font_color", TEXT_PRIMARY)
		price_label.text = "$%d" % total
		price_label.add_theme_color_override("font_color", Color(0.97, 0.83, 0.42))

func _make_swatch(r: float, col: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	var n := 22
	for i in n:
		var a: float = i * TAU / n
		pts.append(Vector2(cos(a), sin(a)) * r)
	poly.polygon = pts
	poly.color = col
	return poly

func _make_ring(r: float, col: Color) -> Line2D:
	var line := Line2D.new()
	var pts := PackedVector2Array()
	var n := 24
	for i in n + 1:
		var a: float = i * TAU / n
		pts.append(Vector2(cos(a), sin(a)) * r)
	line.points = pts
	line.width = 1.5
	line.default_color = col
	return line

# ── Inputs ───────────────────────────────────────────────────────────

func _on_add(t: int) -> void:
	if current_bouquet.size() >= MAX_BOUQUET:
		return
	if workbench.inventory[t] - current_bouquet.count(t) <= 0:
		return
	current_bouquet.append(t)
	AudioManager.play_sfx("workbench_flower")
	_refresh()

func _on_remove() -> void:
	if not current_bouquet.is_empty():
		current_bouquet.pop_back()
		AudioManager.play_sfx("workbench_remove")
		_refresh()

func _on_cancel() -> void:
	_close()

func _on_confirm() -> void:
	if current_bouquet.is_empty():
		return
	var bouquet: Array = current_bouquet.duplicate()
	bouquet.sort()
	if not workbench.consume_bouquet(bouquet):
		return
	if game and game.counter:
		game.counter.add_bouquet(bouquet)
	_close()

func _close() -> void:
	AudioManager.play_sfx("workbench_modal_pop")
	workbench.close_ui()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1: _on_add(0)
		KEY_2: _on_add(1)
		KEY_3: _on_add(2)
		KEY_BACKSPACE: _on_remove()
		KEY_ENTER, KEY_KP_ENTER: _on_confirm()
		KEY_ESCAPE: _on_cancel()
