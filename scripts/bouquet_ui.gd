extends CanvasLayer

# Modal panel for assembling a bouquet from a Workbench's inventory.
# 1/2/3 add by type, Backspace remove last, Enter confirm, Esc cancel.

const MAX_BOUQUET := 5
const PANEL_W := 680.0
const PANEL_H := 470.0
const CARD_W := 200.0
const CARD_H := 138.0
const CARD_PAD := 14.0
const CARD_TOP := 92.0
const DOT_R := 13.0

const PANEL_BG := Color(0.115, 0.115, 0.150, 0.9)
const PANEL_BORDER := Color(1.0, 1.0, 1.0, 0.7)
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
var card_visuals: Array = []

func _ready() -> void:
	layer = 100

	var panel_x := (1280.0 - PANEL_W) / 2.0
	var panel_y := (720.0 - PANEL_H) / 2.0 - 75.0

	panel = Panel.new()
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.position = Vector2(panel_x, panel_y)
	panel.add_theme_stylebox_override("panel", _styled_panel(PANEL_BG, PANEL_BORDER, 14, 1))
	add_child(panel)

	panel.add_child(_make_text("Compose bouquet", Vector2(28, 18), Vector2(PANEL_W - 56, 36), 26, TEXT_HEADER, HORIZONTAL_ALIGNMENT_LEFT))
	panel.add_child(_make_text("Pick flowers - click a card or press 1 / 2 / 3", Vector2(28, 58), Vector2(PANEL_W - 56, 18), 13, TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))

	var divider := ColorRect.new()
	divider.size = Vector2(PANEL_W - 56, 1)
	divider.position = Vector2(28, 82)
	divider.color = Color(1, 1, 1, 0.06)
	panel.add_child(divider)

	for i in range(FlowerDB.TYPE_COUNT):
		var card_x := 28.0 + i * (CARD_W + CARD_PAD)
		card_visuals.append(_make_card(i, card_x, CARD_TOP))

	var bouquet_y := CARD_TOP + CARD_H + 18.0
	panel.add_child(_make_text("Your bouquet", Vector2(28, bouquet_y), Vector2(220, 18), 14, TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))

	bouquet_dots_root = Node2D.new()
	bouquet_dots_root.position = Vector2(28, bouquet_y + 36)
	panel.add_child(bouquet_dots_root)

	bouquet_text = _make_text("", Vector2(28, bouquet_y + 72), Vector2(PANEL_W - 236, 22), 14, TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_LEFT)
	panel.add_child(bouquet_text)

	price_label = _make_text("", Vector2(PANEL_W - 210, bouquet_y + 20), Vector2(180, 50), 30, Color(0.97, 0.83, 0.42), HORIZONTAL_ALIGNMENT_RIGHT)
	panel.add_child(price_label)

	var divider2 := ColorRect.new()
	divider2.size = Vector2(PANEL_W - 56, 1)
	divider2.position = Vector2(28, bouquet_y + 110)
	divider2.color = Color(1, 1, 1, 0.06)
	panel.add_child(divider2)

	var btn_y := bouquet_y + 124
	var btn_x := 28
	_make_button("Remove last  [Backspace]", Vector2(btn_x, btn_y), Vector2(btn_x + 200, 46), ACCENT_REMOVE, _on_remove)
	_make_button("Cancel  [Esc]", Vector2(btn_x + 240, btn_y), Vector2(btn_x + 120, 46), ACCENT_CANCEL, _on_cancel)
	_make_button("Make bouquet  [Enter]", Vector2(btn_x + 400, btn_y), Vector2(btn_x + 198, 46), ACCENT_CONFIRM, _on_confirm)

	_refresh()

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

func _make_text(text: String, pos: Vector2, size: Vector2, font_size: int, col: Color, halign: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.size = size
	lbl.horizontal_alignment = halign
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", col)
	return lbl

func _make_card(flower_type: int, x: float, y: float) -> Dictionary:
	var root := Control.new()
	root.position = Vector2(x, y)
	root.size = Vector2(CARD_W, CARD_H)
	panel.add_child(root)

	var btn := Button.new()
	btn.size = Vector2(CARD_W, CARD_H)
	var type_col: Color = FlowerDB.TYPE_COLORS[flower_type]
	var bg: Color = type_col.lerp(PANEL_BG, 0.72)
	var border: Color = type_col.darkened(0.05)
	btn.add_theme_stylebox_override("normal", _styled_panel(bg, border, 12, 2))
	btn.add_theme_stylebox_override("hover", _styled_panel(type_col.lerp(PANEL_BG, 0.55), border, 12, 2))
	btn.add_theme_stylebox_override("pressed", _styled_panel(type_col.lerp(PANEL_BG, 0.38), border, 12, 2))
	btn.add_theme_stylebox_override("disabled", _styled_panel(Color(0.14, 0.14, 0.17, 0.9), Color(0.30, 0.30, 0.35, 0.7), 12, 1))
	btn.pressed.connect(_on_add.bind(flower_type))
	root.add_child(btn)

	var key_lbl := _make_text("[%d]" % (flower_type + 1), Vector2(CARD_W - 42, 8), Vector2(34, 18), 14, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_RIGHT)
	key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(key_lbl)

	var swatch := _make_swatch(22.0, type_col)
	swatch.position = Vector2(CARD_W / 2.0, 46)
	root.add_child(swatch)

	var highlight := _make_swatch(6.0, Color(1, 1, 1, 0.30))
	highlight.position = Vector2(CARD_W / 2.0 - 8, 38)
	root.add_child(highlight)

	var name_lbl := _make_text(FlowerDB.TYPE_NAMES[flower_type], Vector2(0, 80), Vector2(CARD_W, 22), 18, TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(name_lbl)

	var status_lbl := _make_text("", Vector2(0, 108), Vector2(CARD_W, 18), 12, TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(status_lbl)

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

	var badge_lbl := _make_text("", Vector2.ZERO, Vector2(28, 22), 13, Color(0.15, 0.10, 0.05), HORIZONTAL_ALIGNMENT_CENTER)
	badge_root.add_child(badge_lbl)

	return {
		"btn": btn,
		"status": status_lbl,
		"badge_root": badge_root,
		"badge_label": badge_lbl,
	}

func _make_button(text: String, pos: Vector2, size: Vector2, col: Color, callable: Callable) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size = size
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
	panel.add_child(btn)
	return btn

func _refresh() -> void:
	var bouquet_counts := _count_flowers(current_bouquet)

	for i in range(FlowerDB.TYPE_COUNT):
		var data: Dictionary = card_visuals[i]
		var btn: Button = data["btn"]
		var status_lbl: Label = data["status"]
		var badge_root: Control = data["badge_root"]
		var badge_lbl: Label = data["badge_label"]
		var used: int = bouquet_counts[i]
		var avail: int = workbench.inventory[i] - used

		btn.disabled = avail <= 0 or current_bouquet.size() >= MAX_BOUQUET
		status_lbl.text = "%d available  .  %d in bouquet" % [avail, used]
		badge_root.visible = used > 0
		badge_lbl.text = "x%d" % used

	for child in bouquet_dots_root.get_children():
		child.queue_free()

	if current_bouquet.is_empty():
		bouquet_text.text = "(empty - pick at least one flower)"
		bouquet_text.add_theme_color_override("font_color", TEXT_MUTED)
		price_label.text = "-"
		price_label.add_theme_color_override("font_color", TEXT_MUTED)
		return

	var total := 1
	for i in range(current_bouquet.size()):
		var flower_type: int = current_bouquet[i]
		total += FlowerDB.PRICE[flower_type]
		var dot := _make_swatch(DOT_R, FlowerDB.TYPE_COLORS[flower_type])
		dot.position = Vector2(DOT_R + i * (DOT_R * 2 + 10), DOT_R)
		bouquet_dots_root.add_child(dot)

	for i in range(current_bouquet.size(), MAX_BOUQUET):
		var empty := _make_ring(DOT_R, Color(1, 1, 1, 0.12))
		empty.position = Vector2(DOT_R + i * (DOT_R * 2 + 10), DOT_R)
		bouquet_dots_root.add_child(empty)

	var parts: Array = []
	for i in range(FlowerDB.TYPE_COUNT):
		if bouquet_counts[i] > 0:
			parts.append("%s x %d" % [FlowerDB.TYPE_NAMES[i], bouquet_counts[i]])

	var breakdown := ""
	for i in range(parts.size()):
		if i > 0:
			breakdown += "   .   "
		breakdown += parts[i]

	bouquet_text.text = breakdown
	bouquet_text.add_theme_color_override("font_color", TEXT_PRIMARY)
	price_label.text = "$%d" % total
	price_label.add_theme_color_override("font_color", Color(0.97, 0.83, 0.42))

func _count_flowers(flowers: Array) -> Array:
	var counts: Array = []
	counts.resize(FlowerDB.TYPE_COUNT)
	for i in range(FlowerDB.TYPE_COUNT):
		counts[i] = 0
	for flower_type in flowers:
		counts[flower_type] += 1
	return counts

func _make_swatch(radius: float, col: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(22):
		var a: float = i * TAU / 22.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	poly.polygon = pts
	poly.color = col
	return poly

func _make_ring(radius: float, col: Color) -> Line2D:
	var line := Line2D.new()
	var pts := PackedVector2Array()
	for i in range(25):
		var a: float = i * TAU / 24.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	line.points = pts
	line.width = 1.5
	line.default_color = col
	return line

func _on_add(flower_type: int) -> void:
	if current_bouquet.size() >= MAX_BOUQUET:
		return
	if workbench.inventory[flower_type] - _count_flowers(current_bouquet)[flower_type] <= 0:
		return
	current_bouquet.append(flower_type)
	AudioManager.play_sfx("workbench_flower")
	_refresh()

func _on_remove() -> void:
	if current_bouquet.is_empty():
		return
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
	if game != null and game.counter != null:
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
		KEY_1:
			_on_add(0)
		KEY_2:
			_on_add(1)
		KEY_3:
			_on_add(2)
		KEY_BACKSPACE:
			_on_remove()
		KEY_ENTER, KEY_KP_ENTER:
			_on_confirm()
		KEY_ESCAPE:
			_on_cancel()
