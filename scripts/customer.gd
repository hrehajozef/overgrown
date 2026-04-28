class_name Customer
extends Node2D

# Walks in from the left edge, waits at a counter spot with an order bubble,
# leaves once served or after running out of patience.

const WALK_SPEED := 110.0

var spot_index: int = 0
var spot_position: Vector2 = Vector2.ZERO
var exit_x: float = -120.0 # x to walk to once leaving (sign comes from spawn side)
var order: Array = [] # sorted ints
var patience: float = 0.0 # 0 = infinite
var patience_left: float = 0.0
var at_spot: bool = false
var served: bool = false
var leaving: bool = false
var game

var bubble_root: Node2D
var patience_bar: ColorRect
var patience_bg: ColorRect

func _ready() -> void:
	z_index = 3
	var skin := Color(randf_range(0.85, 1.0), randf_range(0.7, 0.9), randf_range(0.6, 0.8))
	var shirt := Color(randf_range(0.3, 0.9), randf_range(0.3, 0.9), randf_range(0.3, 0.9))
	add_child(Interactable.make_circle(32, shirt))
	var head := Interactable.make_circle(20, skin)
	head.position = Vector2(0, -16)
	add_child(head)
	bubble_root = Node2D.new()
	bubble_root.position = Vector2(0, -50)
	add_child(bubble_root)
	var bubble := ColorRect.new()
	bubble.size = Vector2(86, 30)
	bubble.position = Vector2(-43, -15)
	bubble.color = Color(1, 1, 1, 0.95)
	bubble_root.add_child(bubble)
	var border := ColorRect.new()
	border.size = Vector2(86, 2)
	border.position = Vector2(-43, 13)
	border.color = Color(0, 0, 0, 0.4)
	bubble_root.add_child(border)
	var x := -43.0 + 8.0
	for t in order:
		var dot := Interactable.make_circle(6, FlowerDB.TYPE_COLORS[t], 16)
		dot.position = Vector2(x, 0)
		bubble_root.add_child(dot)
		x += 13.0
	if patience > 0.0:
		patience_bg = ColorRect.new()
		patience_bg.size = Vector2(86, 4)
		patience_bg.position = Vector2(-43, 18)
		patience_bg.color = Color(0, 0, 0, 0.5)
		bubble_root.add_child(patience_bg)
		patience_bar = ColorRect.new()
		patience_bar.size = Vector2(86, 4)
		patience_bar.position = Vector2(-43, 18)
		patience_bar.color = Color(0.4, 0.9, 0.3)
		bubble_root.add_child(patience_bar)
	bubble_root.visible = false
	patience_left = patience

func _process(delta: float) -> void:
	if leaving:
		var dir: float = sign(exit_x - position.x)
		if dir == 0.0:
			dir = 1.0
		position.x += dir * WALK_SPEED * delta
		modulate.a = max(0.0, modulate.a - delta * 0.6)
		if (dir > 0.0 and position.x > exit_x) or (dir < 0.0 and position.x < exit_x):
			if game:
				game.remove_customer(self )
		return
	if served:
		return
	if not at_spot:
		position = position.move_toward(spot_position, WALK_SPEED * delta)
		if position.distance_to(spot_position) < 1.0:
			at_spot = true
			bubble_root.visible = true
			if game and game.counter:
				game.counter.customer_arrived()
		return
	if patience > 0.0:
		patience_left -= delta
		var t: float = patience_left / patience
		patience_bar.size.x = 86.0 * clampf(t, 0.0, 1.0)
		if t < 0.3:
			patience_bar.color = Color(0.95, 0.30, 0.20)
		elif t < 0.6:
			patience_bar.color = Color(0.95, 0.80, 0.20)
		if patience_left <= 0.0:
			_leave(false)

func is_waiting() -> bool:
	return at_spot and not served and not leaving

func serve() -> void:
	served = true
	_leave(true)

func _leave(_happy: bool) -> void:
	leaving = true
	bubble_root.visible = false
