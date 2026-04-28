class_name Pot
extends Interactable

# Pot states:
#   EMPTY    -> 1/2/3 plants by type, F or Space plants top of seed stack (LIFO)
#   GROWING  -> Hold F to water; if water_level == 0 a red countdown shows the
#               drying timer and the flower wilts (squash X / stretch Y)
#   BLOOMED  -> Space cuts; player picks up a single flower of this type
#   DEAD     -> Space cleans

enum State {EMPTY, GROWING, BLOOMED, DEAD}

var state: int = State.EMPTY
var flower_type: int = 0
var growth: float = 0.0 # 0..100
var water_level: float = 0.0 # 0..100
var dry_acc: float = 0.0 # seconds at 0% water
var bloom_acc: float = 0.0 # seconds since blooming

var pot_visual: ColorRect
var soil_visual: ColorRect
var stem_visual: ColorRect
var flower_visual: Polygon2D
var growth_bar: ColorRect
var water_bar: ColorRect
var label_node: Label

func _ready() -> void:
	radius = 36.0
	super._ready()
	# Solid core — player can walk up close (interact zone is wider than this).
	add_solid_circle(22.0, Vector2(0, 0))
	if not _bind_existing_visual_nodes():
		push_error("Pot '%s' is missing required visual children in the scene." % name)
		set_process(false)
		return
	_refresh_visuals()

func _bind_existing_visual_nodes() -> bool:
	for child in get_children():
		if child is ColorRect:
			var rect := child as ColorRect
			if rect.size == Vector2(56, 36) and rect.position == Vector2(-28, -10):
				pot_visual = rect
			elif rect.size == Vector2(50, 8) and rect.position == Vector2(-25, -14):
				soil_visual = rect
			elif rect.size == Vector2(3, 28) and rect.position == Vector2(-1, -36):
				stem_visual = rect
			elif rect.size.y == 4.0 and rect.position == Vector2(-25, 18):
				growth_bar = rect
			elif rect.size.y == 3.0 and rect.position == Vector2(-25, 24):
				water_bar = rect
		elif child is Polygon2D and flower_visual == null:
			flower_visual = child as Polygon2D
		elif child is Label and label_node == null:
			label_node = child as Label
	return pot_visual != null and soil_visual != null and stem_visual != null and flower_visual != null and growth_bar != null and water_bar != null and label_node != null

func _process(delta: float) -> void:
	match state:
		State.GROWING:
			if water_level > 0.0:
				water_level = max(0.0, water_level - FlowerDB.WATER_DRAIN[flower_type] * delta)
				growth += (100.0 / FlowerDB.GROW_TIME[flower_type]) * delta
				dry_acc = 0.0
				if growth >= 100.0:
					growth = 100.0
					state = State.BLOOMED
					bloom_acc = 0.0
			else:
				dry_acc += delta
				if dry_acc >= FlowerDB.DRY_TIME[flower_type]:
					state = State.DEAD
		State.BLOOMED:
			bloom_acc += delta
			if bloom_acc >= FlowerDB.BLOSSOM_DECAY[flower_type]:
				state = State.DEAD
	_refresh_visuals()

func _refresh_visuals() -> void:
	match state:
		State.EMPTY:
			stem_visual.visible = false
			flower_visual.visible = false
			growth_bar.visible = false
			water_bar.visible = false
			label_node.text = ""
		State.GROWING:
			var ft: int = flower_type
			var col: Color = FlowerDB.TYPE_COLORS[ft]
			var grow_t: float = growth / 100.0
			stem_visual.visible = grow_t > 0.15
			stem_visual.color = Color(0.20, 0.55, 0.20)
			flower_visual.visible = grow_t > 0.3
			flower_visual.color = col.lerp(Color(0.4, 0.6, 0.4), 0.6 * (1.0 - grow_t))
			# Wilting squash/stretch when drying — only one half-cycle so the
			# flower returns to base shape between pulses.
			var base_s: float = 0.4 + 0.6 * grow_t
			var amp: float = 0.0
			if water_level <= 0.0:
				amp = max(0.0, 0.22 * sin(dry_acc * 3.0))
			flower_visual.scale = Vector2(base_s * (1.0 + amp), base_s * (1.0 - amp))
			growth_bar.visible = true
			growth_bar.size.x = 50.0 * grow_t
			water_bar.visible = true
			if water_level > 0.0:
				water_bar.color = Color(0.30, 0.70, 1.00)
				water_bar.size.x = 50.0 * (water_level / 100.0)
			else:
				# Drying countdown — full at the moment water hit 0, empties as we approach death.
				water_bar.color = Color(0.95, 0.30, 0.20)
				var dry_t: float = 1.0 - dry_acc / FlowerDB.DRY_TIME[ft]
				water_bar.size.x = 50.0 * clampf(dry_t, 0.0, 1.0)
			label_node.text = FlowerDB.TYPE_NAMES[ft]
		State.BLOOMED:
			stem_visual.visible = true
			stem_visual.color = Color(0.20, 0.55, 0.20)
			flower_visual.visible = true
			flower_visual.scale = Vector2(1, 1)
			flower_visual.color = FlowerDB.TYPE_COLORS[flower_type]
			growth_bar.visible = false
			water_bar.visible = true
			var t: float = 1.0 - bloom_acc / FlowerDB.BLOSSOM_DECAY[flower_type]
			water_bar.size.x = 50.0 * clampf(t, 0.0, 1.0)
			water_bar.color = Color(1.00, 0.65, 0.20)
			label_node.text = "Ready!"
		State.DEAD:
			stem_visual.visible = true
			stem_visual.color = Color(0.30, 0.20, 0.10)
			flower_visual.visible = true
			flower_visual.scale = Vector2(0.7, 0.7)
			flower_visual.color = Color(0.30, 0.20, 0.10)
			growth_bar.visible = false
			water_bar.visible = false
			label_node.text = "Dead"

func interact(player) -> void:
	match state:
		State.EMPTY:
			if player.has_seeds():
				_plant(player.pop_seed())
		State.BLOOMED:
			player.pick_up_cut_flower(flower_type)
			_reset()
		State.DEAD:
			_reset()
		_:
			pass

# F just-pressed: plant top-of-stack at an empty pot.
func action2_press(player) -> void:
	if state == State.EMPTY and player.has_seeds():
		_plant(player.pop_seed())

# F held: water a growing pot.
func continuous_action(player, delta: float) -> void:
	if state == State.GROWING and water_level < 100.0:
		var want: float = Player.CAN_USE_RATE * delta
		var used: float = player.use_water(want)
		water_level = clampf(water_level + used, 0.0, 100.0)

# Plant a specific seed type (1/2/3 hotkeys) — pops the latest matching
# seed from the player's pouch.
func plant_seed_of_type(player, t: int) -> void:
	if state == State.EMPTY and player.pop_seed_of_type(t):
		_plant(t)

func _plant(t: int) -> void:
	flower_type = t
	growth = 0.0
	water_level = 0.0
	dry_acc = 0.0
	state = State.GROWING

func _reset() -> void:
	state = State.EMPTY
	growth = 0.0
	water_level = 0.0
	dry_acc = 0.0
	bloom_acc = 0.0

func get_hint(player) -> String:
	match state:
		State.EMPTY:
			if player.has_seeds():
				var top: int = player.top_seed()
				return "[1/2/3] Plant by type   [F/Space] Plant top: %s" % FlowerDB.TYPE_NAMES[top]
			return "Need a seed (go to seed boxes)"
		State.GROWING:
			if water_level <= 0.0:
				if player.water > 0.0:
					return "[Hold F] Water — drying!"
				return "Drying — refill the can!"
			if water_level < 100.0 and player.water > 0.0:
				return "[Hold F] Water"
			return ""
		State.BLOOMED:
			if player.has_cut_flower():
				return "[Space] Cut flower (carrying %d)" % player.cut_flower_count()
			return "[Space] Cut flower"
		State.DEAD:
			return "[Space] Clean pot"
	return ""
