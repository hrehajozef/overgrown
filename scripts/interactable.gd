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
	area = _find_direct_area()
	if area == null:
		push_error("Missing Area2D child on '%s'. Add it in the scene." % name)
		return
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	var shape := _find_direct_collision_shape(area)
	if shape == null:
		push_error("Missing CollisionShape2D under Area2D on '%s'. Add it in the scene." % name)
		return
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	area.set_meta("owner_interactable", self )

# Adds a non-moving collision body so the player can't walk through this
# station. The body is on layer 1 (Player has collision_mask = 1).
func add_solid_rect(size: Vector2, offset: Vector2 = Vector2.ZERO) -> void:
	var body := _find_direct_static_body()
	if body == null:
		push_error("Missing StaticBody2D child on '%s'. Add it in the scene." % name)
		return
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := _find_direct_collision_shape(body)
	if shape == null:
		push_error("Missing CollisionShape2D under StaticBody2D on '%s'. Add it in the scene." % name)
		return
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = offset

func add_solid_circle(r: float, offset: Vector2 = Vector2.ZERO) -> void:
	var body := _find_direct_static_body()
	if body == null:
		push_error("Missing StaticBody2D child on '%s'. Add it in the scene." % name)
		return
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := _find_direct_collision_shape(body)
	if shape == null:
		push_error("Missing CollisionShape2D under StaticBody2D on '%s'. Add it in the scene." % name)
		return
	var circ := CircleShape2D.new()
	circ.radius = r
	shape.shape = circ
	shape.position = offset

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

func _find_direct_area() -> Area2D:
	for child in get_children():
		if child is Area2D:
			return child as Area2D
	return null

func _find_direct_static_body() -> StaticBody2D:
	for child in get_children():
		if child is StaticBody2D:
			return child as StaticBody2D
	return null

func _find_direct_collision_shape(parent_node: Node) -> CollisionShape2D:
	for child in parent_node.get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null

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
