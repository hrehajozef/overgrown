class_name SeedBox
extends Interactable

@export var flower_type: int = 0

func _ready() -> void:
	radius = 36.0
	super._ready()
	add_child(make_rect(Vector2(64, 48), Color(0.55, 0.40, 0.25), Vector2(-32, -24)))
	add_child(make_rect(Vector2(48, 32), FlowerDB.TYPE_COLORS[flower_type] * 0.8, Vector2(-24, -16)))
	add_child(make_label(FlowerDB.TYPE_NAMES[flower_type] + " seeds", Vector2(-50, -44), 100))

func interact(player) -> void:
	if player.can_take_seed():
		player.push_seed(flower_type)

func get_hint(player) -> String:
	var size: int = player.seed_stack.size()
	if player.can_take_seed():
		return "[Space] Take %s seed (pouch %d/%d)" % [FlowerDB.TYPE_NAMES[flower_type], size, Player.MAX_SEEDS]
	return "Pouch full (%d/%d)" % [size, Player.MAX_SEEDS]
