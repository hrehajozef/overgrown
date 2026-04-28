class_name Player
extends CharacterBody2D

# Free 8-direction movement.
# Held items:
#   * Watering can — always in pocket, capacity in `water` (0..CAN_CAPACITY)
#   * Seed pouch  — stack of up to MAX_SEEDS seed types (LIFO)
#   * One cut flower — single, in hands (`holding == CUT_FLOWER`)
#
# Designed so a 2nd player can be spawned later with player_id = 1 and a
# distinct input action prefix (e.g. "p2_move_left").

const SPEED := 220.0
const CAN_CAPACITY := 300.0
const CAN_REFILL_RATE := 150.0   # %/sec at the tap → 2 seconds for an empty can
const CAN_USE_RATE := 50.0       # %/sec into a pot
const MAX_SEEDS := 10

enum Holding { NONE, CUT_FLOWER }

@export var player_id: int = 0
@export var input_prefix: String = ""

var game

var holding: int = Holding.NONE
var holding_type: int = 0         # only valid when holding == CUT_FLOWER
var water: float = CAN_CAPACITY
var ui_open: bool = false
var seed_stack: Array = []        # ints (FlowerDB.Type); top = back()

var interact_area: Area2D
var current_interactable: Interactable = null
var held_icon: Polygon2D = null

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var body_shape := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 14.0
	body_shape.shape = body_circle
	add_child(body_shape)

	# Visuals — body + hat (so a 2nd player can be tinted later).
	add_child(Interactable.make_circle(14.0, Color(0.20, 0.40, 0.80)))
	var hat := Interactable.make_circle(8.0, Color(0.85, 0.65, 0.30))
	hat.position = Vector2(0, -10)
	add_child(hat)

	# Detector area for nearby Interactables.
	interact_area = Area2D.new()
	interact_area.collision_layer = 0
	interact_area.collision_mask = 8
	interact_area.monitoring = true
	interact_area.monitorable = false
	var ia_shape := CollisionShape2D.new()
	var ia_circle := CircleShape2D.new()
	ia_circle.radius = 38.0
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
		current_interactable.interact(self)
	if Input.is_action_just_pressed(_a("action2")):
		current_interactable.action2_press(self)
	if Input.is_action_pressed(_a("action2")):
		current_interactable.continuous_action(self, delta)
	# Plant-by-type hotkeys only meaningful at a Pot.
	if current_interactable is Pot:
		var pot: Pot = current_interactable
		for i in FlowerDB.TYPE_COUNT:
			if Input.is_action_just_pressed(_a("plant_%d" % (i + 1))):
				pot.plant_seed_of_type(self, i)

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

# ── Cut flower ─────────────────────────────────────────────────────────
func has_cut_flower() -> bool:
	return holding == Holding.CUT_FLOWER

func pick_up_cut_flower(t: int) -> void:
	holding = Holding.CUT_FLOWER
	holding_type = t
	_update_held_icon()

func drop_cut_flower() -> int:
	var t := holding_type
	holding = Holding.NONE
	holding_type = 0
	_update_held_icon()
	return t

# ── Seed stack (LIFO) ──────────────────────────────────────────────────
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

# Pop the most-recent seed of a given type (LIFO within type). Returns true
# if a seed was consumed.
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
	if holding == Holding.CUT_FLOWER:
		var col: Color = FlowerDB.TYPE_COLORS[holding_type]
		held_icon = Interactable.make_circle(8.0, col)
		held_icon.position = Vector2(16, -16)
		add_child(held_icon)
