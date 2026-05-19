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
# Snapshot of how grown the plant was when it died (0..1). Used so a
# flower that died of drought retains its actual height, while one that
# wilted after blooming stays at full size.
var dead_grow_t: float = 1.0

var pot_visual: ColorRect
var soil_visual: ColorRect
var stem_visual: ColorRect
var flower_visual: Polygon2D
var growth_bar: ColorRect
var water_bar: ColorRect
var label_node: Label

# Thought-bubble that floats above the flower for "Ready!" / "Dead" states.
var bubble: Node2D
var bubble_label: Label

func _ready() -> void:
	radius = 36.0
	super._ready()
	# Solid core — player can walk up close (interact zone is wider than this).
	add_solid_circle(22.0, Vector2(0, 0))
	if not _bind_existing_visual_nodes():
		push_error("Pot '%s' is missing required visual children in the scene." % name)
		set_process(false)
		return
	# Hide the plain scene Label — the bubble replaces it for status text.
	label_node.visible = false
	_configure_overlay_bars()
	_create_bubble()
	_refresh_visuals()

func _configure_overlay_bars() -> void:
	growth_bar.z_as_relative = false
	growth_bar.z_index = 25
	water_bar.z_as_relative = false
	water_bar.z_index = 25

func _create_bubble() -> void:
	# Sits well above the flower so it doesn't cover the bloom/dead stub.
	# Tail tip lands ~3 px above the flower top (local y = -50 with scale 1).
	bubble = Node2D.new()
	bubble.position = Vector2(0, -66)
	bubble.visible = false
	bubble.z_as_relative = false
	bubble.z_index = 26
	add_child(bubble)
	var bg := ColorRect.new()
	bg.size = Vector2(60, 16)
	bg.position = Vector2(-30, -8)
	bg.color = Color(1, 1, 1, 0.97)
	bubble.add_child(bg)
	# Subtle border on top/bottom edges
	var border_top := ColorRect.new()
	border_top.size = Vector2(60, 1)
	border_top.position = Vector2(-30, -8)
	border_top.color = Color(0.65, 0.65, 0.70, 0.9)
	bubble.add_child(border_top)
	var border_bot := ColorRect.new()
	border_bot.size = Vector2(60, 1)
	border_bot.position = Vector2(-30, 7)
	border_bot.color = Color(0.65, 0.65, 0.70, 0.9)
	bubble.add_child(border_bot)
	# Tail pointing down toward the flower
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(-4, 8), Vector2(4, 8), Vector2(0, 14)])
	tail.color = Color(1, 1, 1, 0.97)
	bubble.add_child(tail)
	bubble_label = Label.new()
	bubble_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.18))
	bubble_label.add_theme_font_size_override("font_size", 12)
	bubble_label.clip_contents = false
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	bubble.add_child(bubble_label)
	# Use offsets directly (Control inside Node2D — anchors stay at 0/0/0/0)
	# so the text rect is the same as the bubble bg rect, centered on bubble.
	bubble_label.anchor_left = 0.0
	bubble_label.anchor_right = 0.0
	bubble_label.anchor_top = 0.0
	bubble_label.anchor_bottom = 0.0
	bubble_label.offset_left = -30.0
	bubble_label.offset_right = 30.0
	bubble_label.offset_top = -8.0
	bubble_label.offset_bottom = 8.0
	bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _bind_existing_visual_nodes() -> bool:
	pot_visual = get_node_or_null("PotVisual") as ColorRect
	soil_visual = get_node_or_null("SoilVisual") as ColorRect
	stem_visual = get_node_or_null("StemVisual") as ColorRect
	flower_visual = get_node_or_null("FlowerVisual") as Polygon2D
	growth_bar = get_node_or_null("GrowthBar") as ColorRect
	water_bar = get_node_or_null("WaterBar") as ColorRect
	label_node = get_node_or_null("StatusLabel") as Label
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
					AudioManager.play_sfx("flower_ready")
			else:
				dry_acc += delta
				if dry_acc >= FlowerDB.DRY_TIME[flower_type]:
					dead_grow_t = clampf(growth / 100.0, 0.0, 1.0)
					state = State.DEAD
					AudioManager.play_sfx("flower_dead")
		State.BLOOMED:
			bloom_acc += delta
			if bloom_acc >= FlowerDB.BLOSSOM_DECAY[flower_type]:
				dead_grow_t = 1.0
				state = State.DEAD
				AudioManager.play_sfx("flower_dead")
	_refresh_visuals()

func _refresh_visuals() -> void:
	# label_node stays hidden — bubble drives state badges
	if bubble:
		bubble.visible = false
	match state:
		State.EMPTY:
			stem_visual.visible = false
			flower_visual.visible = false
			growth_bar.visible = false
			water_bar.visible = false
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
			if bubble:
				bubble.visible = true
				bubble_label.text = "Ready!"
				bubble_label.add_theme_color_override("font_color", Color(0.10, 0.45, 0.18))
		State.DEAD:
			# Freeze the flower at the size it had when it died, matching
			# the same base-scale formula used while growing.
			var dead_s: float = 0.4 + 0.6 * dead_grow_t
			stem_visual.visible = dead_grow_t > 0.1
			stem_visual.color = Color(0.30, 0.20, 0.10)
			flower_visual.visible = dead_grow_t > 0.05
			flower_visual.scale = Vector2(dead_s, dead_s)
			flower_visual.color = Color(0.30, 0.20, 0.10)
			growth_bar.visible = false
			water_bar.visible = false
			if bubble:
				bubble.visible = true
				bubble_label.text = "Dead"
				bubble_label.add_theme_color_override("font_color", Color(0.55, 0.10, 0.10))

func interact(player) -> void:
	match state:
		State.EMPTY:
			if player.has_seeds():
				_plant(player.pop_seed())
		State.BLOOMED:
			AudioManager.play_sfx("flower_harvest")
			player.pick_up_cut_flower(flower_type)
			_reset()
		State.DEAD:
			AudioManager.play_sfx("pot_clean")
			_reset()
		_:
			pass

# F just-pressed: plant top-of-stack at an empty pot, or give negative
# feedback when the player tries to water with an empty can.
func action2_press(player) -> void:
	if state == State.EMPTY and player.has_seeds():
		_plant(player.pop_seed())
	elif state == State.GROWING and water_level < 100.0 and player.water <= 0.0:
		AudioManager.play_sfx("can_empty")

# F held: water a growing pot.
func continuous_action(player, delta: float) -> void:
	if state == State.GROWING and water_level < 100.0 and player.water > 0.0:
		var want: float = Player.CAN_USE_RATE * delta
		var used: float = player.use_water(want)
		water_level = clampf(water_level + used, 0.0, 100.0)
		AudioManager.tick_water()

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
	dead_grow_t = 1.0
	state = State.GROWING
	AudioManager.play_sfx("seed_place")

func _reset() -> void:
	state = State.EMPTY
	growth = 0.0
	water_level = 0.0
	dry_acc = 0.0
	bloom_acc = 0.0
	dead_grow_t = 1.0

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
