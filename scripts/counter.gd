class_name Counter
extends Interactable

# Display surface for finished bouquets. Customers auto-pick a matching one.
# Small vertical pillar — customers queue to its right.

const VISUAL_WIDTH := 60.0
const VISUAL_HEIGHT := 110.0
const BODY_WIDTH := 50.0
const BODY_HEIGHT := 100.0
const MAX_DISPLAY := 4

var bouquets: Array = []  # Array of sorted Array[int]
var visual_root: Node2D
var game

func _ready() -> void:
	radius = 50.0
	super._ready()
	# Solid body — blocks the player from crossing into the customer queue.
	add_solid_rect(Vector2(BODY_WIDTH, BODY_HEIGHT), Vector2(0, 0))
	# Pillar
	add_child(make_rect(Vector2(VISUAL_WIDTH, VISUAL_HEIGHT), Color(0.65, 0.45, 0.28),
		Vector2(-VISUAL_WIDTH / 2.0, -VISUAL_HEIGHT / 2.0)))
	# Top edge
	add_child(make_rect(Vector2(VISUAL_WIDTH, 6), Color(0.45, 0.30, 0.18),
		Vector2(-VISUAL_WIDTH / 2.0, -VISUAL_HEIGHT / 2.0)))
	# Tiny register
	add_child(make_rect(Vector2(22, 18), Color(0.20, 0.20, 0.20), Vector2(-11, -VISUAL_HEIGHT / 2.0 + 8)))
	add_child(make_rect(Vector2(16, 5), Color(0.85, 0.75, 0.20), Vector2(-8, -VISUAL_HEIGHT / 2.0 + 4)))
	# Vertical "Counter" label rotated for narrow pillar
	var lbl := Label.new()
	lbl.text = "Counter"
	lbl.position = Vector2(-VISUAL_WIDTH / 2.0 - 4, VISUAL_HEIGHT / 2.0 - 8)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.rotation = -PI / 2.0
	add_child(lbl)
	visual_root = Node2D.new()
	add_child(visual_root)

func add_bouquet(bouquet: Array) -> void:
	if bouquets.size() >= MAX_DISPLAY:
		return
	var copy: Array = bouquet.duplicate()
	copy.sort()
	bouquets.append(copy)
	_refresh_display()
	_check_match()

func _refresh_display() -> void:
	for c in visual_root.get_children():
		c.queue_free()
	# Stack bouquets above the counter pillar so they're visible despite the small surface.
	for i in bouquets.size():
		var b: Array = bouquets[i]
		var bx := -32
		var by := -VISUAL_HEIGHT / 2.0 - 24 - i * 28
		var bg := make_rect(Vector2(64, 22), Color(0.95, 0.95, 0.95, 0.95), Vector2(bx, by))
		visual_root.add_child(bg)
		var px: float = bx + 8
		for t in b:
			var dot := make_circle(5, FlowerDB.TYPE_COLORS[t], 16)
			dot.position = Vector2(px, by + 11)
			visual_root.add_child(dot)
			px += 11

func customer_arrived() -> void:
	_check_match()

func _check_match() -> void:
	if game == null:
		return
	var done := false
	while not done:
		done = true
		for c in game.customers:
			if not c.is_waiting():
				continue
			for j in range(bouquets.size()):
				if _arrays_equal(bouquets[j], c.order):
					bouquets.remove_at(j)
					game.add_money(_bouquet_price(c.order))
					c.serve()
					done = false
					break
			if not done:
				break
	_refresh_display()

func _arrays_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i] != b[i]:
			return false
	return true

func _bouquet_price(b: Array) -> int:
	var total := 3  # flat tip
	for t in b:
		total += FlowerDB.PRICE[t]
	return total

func get_hint(_player) -> String:
	return ""
