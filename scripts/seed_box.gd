class_name SeedBox
extends Interactable

@export var flower_type: int = 0

# Loaded once and reused for every seed box.
const SEED_ICON := preload("res://assets/seeds_icon.png")

var icon_sprite: Sprite2D

func _ready() -> void:
	radius = 40.0
	super._ready()
	add_solid_rect(Vector2(56, 40), Vector2(0, 0))
	if get_node_or_null("SeedLabel") == null:
		push_error("SeedBox '%s' is missing visual children in the scene." % name)
	_add_icon()

func _add_icon() -> void:
	# Render the placeholder seed icon in the center of the box, tinted
	# black-on-color so it pops against the inner colored panel. The scene's
	# inner panel is ~48×32 (local units), so we shrink the source PNG to
	# fit comfortably with a little margin.
	icon_sprite = Sprite2D.new()
	icon_sprite.texture = SEED_ICON
	icon_sprite.position = Vector2(0, 0)
	# The texture is large (≈700px); aim for ~36px of width in local units.
	var tw: float = max(1.0, icon_sprite.texture.get_width())
	icon_sprite.scale = Vector2(36.0 / tw, 36.0 / tw)
	icon_sprite.modulate = Color(0.10, 0.10, 0.12, 0.95)
	icon_sprite.z_index = 1
	add_child(icon_sprite)

func interact(player) -> void:
	if player.can_take_seed():
		if player.push_seed(flower_type):
			AudioManager.play_sfx("seed_pick")
	else:
		AudioManager.play_sfx("pouch_full")

func get_hint(player) -> String:
	var size: int = player.seed_stack.size()
	if player.can_take_seed():
		return "[Space] Take %s seed (pouch %d/%d)" % [FlowerDB.TYPE_NAMES[flower_type], size, Player.MAX_SEEDS]
	return "Pouch full (%d/%d)" % [size, Player.MAX_SEEDS]
