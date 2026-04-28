class_name SeedBox
extends Interactable

@export var flower_type: int = 0

func _ready() -> void:
	radius = 40.0
	super._ready()
	add_solid_rect(Vector2(56, 40), Vector2(0, 0))
	if not _has_baked_visuals():
		push_error("SeedBox '%s' is missing visual children in the scene." % name)

func _has_baked_visuals() -> bool:
	for child in get_children():
		if child is Label:
			return true
	return false

func interact(player) -> void:
	if player.can_take_seed():
		player.push_seed(flower_type)

func get_hint(player) -> String:
	var size: int = player.seed_stack.size()
	if player.can_take_seed():
		return "[Space] Take %s seed (pouch %d/%d)" % [FlowerDB.TYPE_NAMES[flower_type], size, Player.MAX_SEEDS]
	return "Pouch full (%d/%d)" % [size, Player.MAX_SEEDS]
