extends CanvasLayer

# Modal panel for assembling a bouquet from a Workbench's inventory.
# 1/2/3 add by type, Backspace remove last, Enter confirm, Esc cancel.

const MAX_BOUQUET := 5

var workbench: Workbench
var player: Player
var game

var current_bouquet: Array = []
var bouquet_label: Label
var inv_buttons: Array = []
var price_label: Label

func _ready() -> void:
	layer = 100
	# Fully opaque background so the bustling shop doesn't peek through.
	var dim := ColorRect.new()
	dim.size = Vector2(1280, 720)
	dim.color = Color(0.10, 0.08, 0.14)
	add_child(dim)
	# Solid panel
	var panel := Panel.new()
	panel.size = Vector2(620, 420)
	panel.position = Vector2(330, 150)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.20, 0.18, 0.26)
	sb.border_color = Color(0.55, 0.50, 0.65)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var title := Label.new()
	title.text = "Compose bouquet"
	title.position = Vector2(20, 14)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	panel.add_child(title)
	var inv_lbl := Label.new()
	inv_lbl.text = "Inventory — press 1 / 2 / 3 or click"
	inv_lbl.position = Vector2(20, 60)
	inv_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	panel.add_child(inv_lbl)
	for i in FlowerDB.TYPE_COUNT:
		var btn := Button.new()
		btn.position = Vector2(20 + i * 195, 90)
		btn.size = Vector2(185, 70)
		btn.add_theme_font_size_override("font_size", 16)
		# Tint the button slightly toward the flower's color so it's
		# visually obvious which key plants which type.
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = FlowerDB.TYPE_COLORS[i].lerp(Color(0.20, 0.18, 0.26), 0.55)
		bsb.border_color = FlowerDB.TYPE_COLORS[i]
		bsb.border_width_left = 3
		bsb.border_width_right = 3
		bsb.border_width_top = 3
		bsb.border_width_bottom = 3
		bsb.corner_radius_top_left = 6
		bsb.corner_radius_top_right = 6
		bsb.corner_radius_bottom_left = 6
		bsb.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("normal", bsb)
		var bsb_hover := bsb.duplicate()
		bsb_hover.bg_color = bsb.bg_color.lightened(0.15)
		btn.add_theme_stylebox_override("hover", bsb_hover)
		btn.pressed.connect(_on_add.bind(i))
		panel.add_child(btn)
		inv_buttons.append(btn)
	var bouquet_title := Label.new()
	bouquet_title.text = "Bouquet:"
	bouquet_title.position = Vector2(20, 180)
	bouquet_title.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(bouquet_title)
	bouquet_label = Label.new()
	bouquet_label.position = Vector2(20, 210)
	bouquet_label.size = Vector2(580, 40)
	bouquet_label.add_theme_font_size_override("font_size", 22)
	bouquet_label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(bouquet_label)
	price_label = Label.new()
	price_label.position = Vector2(20, 252)
	price_label.size = Vector2(580, 24)
	price_label.add_theme_font_size_override("font_size", 14)
	price_label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.6))
	panel.add_child(price_label)
	var rm_btn := Button.new()
	rm_btn.position = Vector2(20, 296)
	rm_btn.size = Vector2(160, 44)
	rm_btn.text = "Remove last  (Backspace)"
	rm_btn.add_theme_font_size_override("font_size", 11)
	rm_btn.pressed.connect(_on_remove)
	panel.add_child(rm_btn)
	var cancel_btn := Button.new()
	cancel_btn.position = Vector2(200, 296)
	cancel_btn.size = Vector2(140, 44)
	cancel_btn.text = "Cancel  (Esc)"
	cancel_btn.add_theme_font_size_override("font_size", 12)
	cancel_btn.pressed.connect(_on_cancel)
	panel.add_child(cancel_btn)
	var confirm_btn := Button.new()
	confirm_btn.position = Vector2(360, 296)
	confirm_btn.size = Vector2(240, 44)
	confirm_btn.text = "Make bouquet  (Enter)"
	confirm_btn.add_theme_font_size_override("font_size", 14)
	confirm_btn.pressed.connect(_on_confirm)
	panel.add_child(confirm_btn)
	var hint := Label.new()
	hint.text = "Keys: 1 / 2 / 3 add  •  Backspace remove  •  Enter confirm  •  Esc cancel"
	hint.position = Vector2(20, 364)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	panel.add_child(hint)
	_refresh()

func _refresh() -> void:
	for i in FlowerDB.TYPE_COUNT:
		var avail: int = workbench.inventory[i] - current_bouquet.count(i)
		var btn: Button = inv_buttons[i]
		btn.text = "[%d]  %s\n%d available  (used %d)" % [i + 1, FlowerDB.TYPE_NAMES[i], avail, current_bouquet.count(i)]
		btn.disabled = avail <= 0 or current_bouquet.size() >= MAX_BOUQUET
	if current_bouquet.is_empty():
		bouquet_label.text = "(empty — pick at least one flower)"
		price_label.text = ""
	else:
		var s := ""
		var total := 3
		for t in current_bouquet:
			s += "[" + FlowerDB.TYPE_NAMES[t] + "] "
			total += FlowerDB.PRICE[t]
		bouquet_label.text = s
		price_label.text = "Sells for $%d if it matches an order" % total

func _on_add(t: int) -> void:
	if current_bouquet.size() >= MAX_BOUQUET:
		return
	if workbench.inventory[t] - current_bouquet.count(t) <= 0:
		return
	current_bouquet.append(t)
	_refresh()

func _on_remove() -> void:
	if not current_bouquet.is_empty():
		current_bouquet.pop_back()
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
