extends Node2D

# Top-level game manager: builds the world, runs the day timer + economy,
# spawns customers. Designed so a 2nd Player can be added later.

# ── Layout (1280×720) ───────────────────────────────────────────
# Customers walk in from the left, queue at three counter spots.
# Counter on left, then workbench, then a 3×2 pot grid, then seed
# boxes and the water tap on the right wall.

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

const DAY_LENGTH := 300.0          # 5 minutes
const STARTING_MONEY := 30
const STARTING_RENT := 40
const RENT_INCREASE_PER_DAY := 20

# Patience schedule: day 1 is infinite, day 2 starts at [PATIENCE_LOW, PATIENCE_HIGH],
# both bounds drop by PATIENCE_STEP per following day, clamped to PATIENCE_FLOOR.
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

var counter: Counter
var workbench: Workbench
var player: Player
var hud: HUD
var customers: Array = []

func _ready() -> void:
	randomize()
	_setup_input_map()
	_build_world()

func _setup_input_map() -> void:
	# Bind keys programmatically so we don't depend on project.godot input format.
	# When adding a 2nd player later, register a parallel set with prefix "p2_".
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
	# Floor
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.74, 0.45)
	bg.size = Vector2(1280, 720)
	bg.z_index = -10
	add_child(bg)
	# Decorative zone tiles
	# Floor zones — soft tan rugs around each work area, matching the layout sketch.
	_zone(Vector2(20, 140), Vector2(140, 480), Color(0.86, 0.82, 0.70))    # supply column (seeds)
	_zone(Vector2(1100, 120), Vector2(160, 200), Color(0.86, 0.82, 0.70))  # tap nook
	_zone(Vector2(180, 540), Vector2(380, 180), Color(0.85, 0.74, 0.55))   # workbench area
	_zone(Vector2(720, 540), Vector2(560, 180), Color(0.85, 0.74, 0.55))   # counter + customers
	_zone(Vector2(220, 50), Vector2(880, 130), Color(0.50, 0.66, 0.40))    # garden patch (top)
	# Pots — 4 in a row at the top
	for p in POT_POSITIONS:
		var pot := Pot.new()
		pot.position = p
		add_child(pot)
	# Seed boxes — vertical column on the left wall (Red top, Yellow middle, Blue bottom)
	for i in FlowerDB.TYPE_COUNT:
		var sb := SeedBox.new()
		sb.flower_type = i
		sb.position = Vector2(90, 220 + i * 180)
		add_child(sb)
	# Water tap — top right
	var tap := WaterTap.new()
	tap.position = Vector2(1180, 220)
	add_child(tap)
	# Workbench — bottom-left, wide horizontal
	workbench = Workbench.new()
	workbench.position = Vector2(370, 620)
	workbench.game = self
	add_child(workbench)
	# Counter — small vertical pillar at bottom-center, customers queue to its right
	counter = Counter.new()
	counter.position = Vector2(760, 605)
	counter.game = self
	add_child(counter)
	# HUD
	hud = HUD.new()
	hud.game = self
	add_child(hud)
	# Player
	player = Player.new()
	player.position = Vector2(640, 380)
	player.game = self
	add_child(player)
	hud.show_message("Day 1\nGrow flowers, fill orders, pay rent.", 2.5)

func _zone(pos: Vector2, size: Vector2, col: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = col
	r.z_index = -9
	add_child(r)

func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return
	if not day_active:
		return
	time_left -= delta
	customer_spawn_timer -= delta
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
		c.patience = 0.0  # infinite on day 1 — no patience bar, never leaves angry
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
	# Bigger orders later
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
	# Clear waiting customers (the day ended).
	for c in customers.duplicate():
		remove_customer(c)
	if money >= rent:
		money -= rent
		hud.show_message("Day %d cleared!\nPaid $%d rent. Money left: $%d." % [day, rent, money], 2.5)
		day += 1
		rent += RENT_INCREASE_PER_DAY
		time_left = DAY_LENGTH
		customer_spawn_timer = 6.0
		day_active = true
	else:
		game_over = true
		hud.show_game_over(day - 1 if day > 1 else 0)
