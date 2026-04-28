class_name Player
extends CharacterBody2D

# Free 8-direction movement.
# Held items:
#   * Watering can — always in pocket, capacity in `water` (0..CAN_CAPACITY)
#   * Seed pouch  — stack of up to MAX_SEEDS seed types (LIFO)
#   * Cut flowers  — unlimited stack of bloomed flowers, each with a type
#
# Designed so a 2nd player can be spawned later with player_id = 1 and a
# distinct input action prefix (e.g. "p2_move_left").

const SPEED := 350.0
const CAN_CAPACITY := 300.0
const CAN_REFILL_RATE := 150.0 # %/sec at the tap → 2 seconds for an empty can
const CAN_USE_RATE := 50.0 # %/sec into a pot
const MAX_SEEDS := 10
const BODY_RADIUS := 18.0
const INTERACT_RADIUS := 40.0

@export var player_id: int = 0
@export var input_prefix: String = ""

var game

var water: float = CAN_CAPACITY
var ui_open: bool = false
var seed_stack: Array = [] # ints (FlowerDB.Type); top = back()
var cut_flower_stack: Array = [] # ints; unlimited

var interact_area: Area2D
var current_interactable: Interactable = null
var held_icon: Polygon2D = null
var held_count_label: Label = null

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var body_shape := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = BODY_RADIUS
	body_shape.shape = body_circle
	add_child(body_shape)

	# Visuals — body + hat (so a 2nd player can be tinted later).
	add_child(Interactable.make_circle(BODY_RADIUS, Color(0.20, 0.40, 0.80)))
	var hat := Interactable.make_circle(11.0, Color(0.85, 0.65, 0.30))
	hat.position = Vector2(0, -12)
	add_child(hat)

	# Detector area for nearby Interactables.
	interact_area = Area2D.new()
	interact_area.collision_layer = 0
	interact_area.collision_mask = 8
	interact_area.monitoring = true
	interact_area.monitorable = false
	var ia_shape := CollisionShape2D.new()
	var ia_circle := CircleShape2D.new()
	ia_circle.radius = INTERACT_RADIUS
	ia_shape.shape = ia_circle
	interact_area.add_child(ia_shape)
	add_child(interact_area)

	z_index = 5

func _physics_process(_delta: float) -> void:
	if ui_open:
		velocity = Vector2.ZERO
		return
	var dir := Vector2(
		Input.get_axis(_a("move_left"), _a("move_right")),
		Input.get_axis(_a("move_up"), _a("move_down")),
	)
	if dir.length() > 0.001:
		velocity = dir.normalized() * SPEED
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func _process(delta: float) -> void:
	_update_current_interactable()
	if ui_open:
		return
	if current_interactable == null:
		return
	if Input.is_action_just_pressed(_a("interact")):
		current_interactable.interact(self )
	if Input.is_action_just_pressed(_a("action2")):
		current_interactable.action2_press(self )
	if Input.is_action_pressed(_a("action2")):
		current_interactable.continuous_action(self , delta)
	if current_interactable is Pot:
		var pot: Pot = current_interactable
		for i in FlowerDB.TYPE_COUNT:
			if Input.is_action_just_pressed(_a("plant_%d" % (i + 1))):
				pot.plant_seed_of_type(self , i)

func _a(action: String) -> String:
	return input_prefix + action

func _update_current_interactable() -> void:
	var areas: Array = interact_area.get_overlapping_areas()
	var best: Interactable = null
	var best_d := INF
	for a in areas:
		if not a.has_meta("owner_interactable"):
			continue
		var owner_obj = a.get_meta("owner_interactable")
		if owner_obj == null or not is_instance_valid(owner_obj):
			continue
		var d: float = global_position.distance_squared_to(owner_obj.global_position)
		if d < best_d:
			best_d = d
			best = owner_obj
	current_interactable = best

# ── Cut flower stack (unlimited) ───────────────────────────────────────
func has_cut_flower() -> bool:
	return not cut_flower_stack.is_empty()

func cut_flower_count() -> int:
	return cut_flower_stack.size()

func pick_up_cut_flower(t: int) -> void:
	cut_flower_stack.append(t)
	_update_held_icon()

func drain_cut_flowers() -> Array:
	var arr: Array = cut_flower_stack.duplicate()
	cut_flower_stack.clear()
	_update_held_icon()
	return arr

func cut_flower_counts_by_type() -> Array:
	var counts := []
	for i in FlowerDB.TYPE_COUNT:
		counts.append(0)
	for t in cut_flower_stack:
		counts[t] += 1
	return counts

# ── Seed stack (LIFO, max 10) ──────────────────────────────────────────
func can_take_seed() -> bool:
	return seed_stack.size() < MAX_SEEDS

func push_seed(t: int) -> bool:
	if not can_take_seed():
		return false
	seed_stack.append(t)
	return true

func has_seeds() -> bool:
	return not seed_stack.is_empty()

func top_seed() -> int:
	return seed_stack.back() if not seed_stack.is_empty() else -1

func pop_seed() -> int:
	if seed_stack.is_empty():
		return -1
	return seed_stack.pop_back()

func pop_seed_of_type(t: int) -> bool:
	for i in range(seed_stack.size() - 1, -1, -1):
		if seed_stack[i] == t:
			seed_stack.remove_at(i)
			return true
	return false

func seed_count_of(t: int) -> int:
	var count := 0
	for s in seed_stack:
		if s == t:
			count += 1
	return count

# ── Watering can ───────────────────────────────────────────────────────
func add_water(amount: float) -> void:
	water = clamp(water + amount, 0.0, CAN_CAPACITY)

func use_water(amount: float) -> float:
	var used: float = min(amount, water)
	water -= used
	return used

# ── Visuals ────────────────────────────────────────────────────────────
func _update_held_icon() -> void:
	if held_icon:
		held_icon.queue_free()
		held_icon = null
	if held_count_label:
		held_count_label.queue_free()
		held_count_label = null
	if cut_flower_stack.is_empty():
		return
	var top: int = cut_flower_stack.back()
	held_icon = Interactable.make_circle(9.0, FlowerDB.TYPE_COLORS[top])
	held_icon.position = Vector2(20, -22)
	add_child(held_icon)
	if cut_flower_stack.size() > 1:
		held_count_label = Label.new()
		held_count_label.text = "x%d" % cut_flower_stack.size()
		held_count_label.position = Vector2(28, -34)
		held_count_label.add_theme_font_size_override("font_size", 12)
		held_count_label.add_theme_color_override("font_color", Color.WHITE)
		add_child(held_count_label)
