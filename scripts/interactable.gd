class_name Interactable
extends Node2D

# Base for any object the player can stand near and act on.
# Sub-classes override interact(), continuous_action(), get_hint().
# An Area2D child is created on layer 4 (bit value 8) so the player's
# detector area picks it up via get_overlapping_areas().

@export var radius: float = 40.0
@export var hint: String = ""

var area: Area2D

func _ready() -> void:
	area = Area2D.new()
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	area.set_meta("owner_interactable", self)

func interact(_player) -> void:
	pass

# Called once on the frame F is pressed (before continuous_action).
func action2_press(_player) -> void:
	pass

# Called every frame while F is held.
func continuous_action(_player, _delta: float) -> void:
	pass

func get_hint(_player) -> String:
	return hint

# Small helpers shared by sub-classes (placeholder visuals).
static func make_circle(r: float, col: Color, segments: int = 24) -> Polygon2D:
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in segments:
		var a: float = i * TAU / segments
		pts.append(Vector2(cos(a), sin(a)) * r)
	poly.polygon = pts
	poly.color = col
	return poly

static func make_rect(size: Vector2, col: Color, offset: Vector2 = Vector2.ZERO) -> ColorRect:
	var r := ColorRect.new()
	r.size = size
	r.color = col
	r.position = offset
	return r

static func make_label(text: String, pos: Vector2, w: float = 100.0, font_size: int = 11, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(w, 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l
