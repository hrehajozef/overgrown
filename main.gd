extends Node2D

# Top-level game manager: uses nodes from the scene instead of building them.

const POT_POSITIONS := [
	Vector2(320, 110), Vector2(540, 110), Vector2(760, 110), Vector2(980, 110),
]
const CUSTOMER_SPOTS := [
	Vector2(900, 605),
	Vector2(1030, 605),
	Vector2(1160, 605),
]
const CUSTOMER_SPAWN_X := 1400.0
const CUSTOMER_EXIT_X := 1400.0

const DAY_LENGTH := 300.0
const STARTING_MONEY := 30
const STARTING_RENT := 40
const RENT_INCREASE_PER_DAY := 20

const PATIENCE_LOW := 100.0
const PATIENCE_HIGH := 130.0
const PATIENCE_STEP := 5.0
const PATIENCE_FLOOR := 15.0

var money: int = STARTING_MONEY
var day: int = 1
var rent: int = STARTING_RENT
var time_left: float = DAY_LENGTH
var customer_spawn_timer: float = 6.0
var day_active: bool = true
var game_over: bool = false
var time_warning_played: bool = false

var counter: Counter
var workbench: Workbench
var player: Player
var hud: HUD
var customers: Array = []

func _ready() -> void:
	randomize()
	_setup_input_map()
	
	# LINKING NODES: Find nodes already present in the scene tree.
	# Adjust the names inside get_node() if you named them differently in the editor.
	# The "$" symbol is a shorthand for get_node().
	counter = get_node_or_null("Counter")
	workbench = get_node_or_null("Workbench")
	player = get_node_or_null("Player")
	hud = get_node_or_null("HUD")
	
	# Ensure the objects know about the game manager
	if counter: counter.game = self
	if workbench: workbench.game = self
	if player: player.game = self
	if hud: hud.game = self
	
	_build_world() # This is now empty or only for small adjustments

func _setup_input_map() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("move_up", [KEY_W, KEY_UP])
	_bind("move_down", [KEY_S, KEY_DOWN])
	_bind("interact", [KEY_SPACE])
	_bind("action2", [KEY_F])
	_bind("plant_1", [KEY_1])
	_bind("plant_2", [KEY_2])
	_bind("plant_3", [KEY_3])
	_bind("restart", [KEY_R])

func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.keycode = k
		InputMap.action_add_event(action, ev)

func _build_world() -> void:
	# Keep this empty since we now have everything in the .tscn scene file.
	# You can use this for one-time initialization if needed.
	hud.show_message("Day 1\nGrow flowers, fill orders, pay rent.", 2.5)

func _zone(pos: Vector2, size: Vector2, col: Color) -> void:
	# No longer needed as we use ColorRects in the scene.
	pass

func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return
	if not day_active:
		return
	time_left -= delta
	customer_spawn_timer -= delta
	# One-shot warning beep when time crosses below 30s for the current day.
	if not time_warning_played and time_left <= 30.0 and time_left > 0.0:
		time_warning_played = true
		AudioManager.play_sfx("time_warning")
	var max_customers: int = min(CUSTOMER_SPOTS.size(), 1 + (day + 1) / 2)
	if customer_spawn_timer <= 0.0 and customers.size() < max_customers and time_left > 15.0:
		_spawn_customer()
		customer_spawn_timer = randf_range(_spawn_min(), _spawn_max())
	if time_left <= 0.0:
		_end_day()

func _spawn_min() -> float:
	return max(4.0, 12.0 - day * 0.5)

func _spawn_max() -> float:
	return max(8.0, 22.0 - day * 0.7)

func _spawn_customer() -> void:
	var taken := {}
	for c in customers:
		taken[c.spot_index] = true
	var spot_idx := -1
	for i in CUSTOMER_SPOTS.size():
		if not taken.has(i):
			spot_idx = i
			break
	if spot_idx == -1:
		return
	var c := Customer.new()
	c.spot_index = spot_idx
	c.spot_position = CUSTOMER_SPOTS[spot_idx]
	c.position = Vector2(CUSTOMER_SPAWN_X, CUSTOMER_SPOTS[spot_idx].y)
	c.exit_x = CUSTOMER_EXIT_X
	c.order = _random_order()
	if day == 1:
		c.patience = 0.0
	else:
		var off: float = (day - 2) * PATIENCE_STEP
		var low: float = max(PATIENCE_FLOOR, PATIENCE_LOW - off)
		var high: float = max(low + 1.0, PATIENCE_HIGH - off)
		c.patience = randf_range(low, high)
	c.game = self
	customers.append(c)
	add_child(c)

func _random_order() -> Array:
	var size := randi_range(2, 4)
	if day >= 4 and randf() < 0.4:
		size = randi_range(3, 5)
	var order: Array = []
	for i in size:
		order.append(randi() % FlowerDB.TYPE_COUNT)
	order.sort()
	return order

func remove_customer(c: Customer) -> void:
	customers.erase(c)
	c.queue_free()

func add_money(amount: int) -> void:
	money += amount

func _end_day() -> void:
	day_active = false
	for c in customers.duplicate():
		remove_customer(c)
	if money >= rent:
		money -= rent
		AudioManager.play_sfx("day_complete")
		hud.show_message("Day %d cleared!\nPaid $%d rent. Money left: $%d." % [day, rent, money], 2.5)
		day += 1
		rent += RENT_INCREASE_PER_DAY
		time_left = DAY_LENGTH
		customer_spawn_timer = 6.0
		time_warning_played = false
		day_active = true
	else:
		game_over = true
		AudioManager.play_sfx("game_over")
		hud.show_game_over(day - 1 if day > 1 else 0)
