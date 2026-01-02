extends ProgressBar

@export var player_1: bool
@export var target: CollisionEntity
var true_bar: ProgressBar

var status: EntityStatus
var value_drag: float = 1

func _ready() -> void:
	await get_tree().process_frame
	var _target_parent = Game.instance.fighter_1 if player_1 else Game.instance.fighter_2
	target = _target_parent.get_node("Fighter")
	status = target.get_node("GenericAttributes/EntityStatus")
	true_bar = get_child(0)
	
func _process(delta: float) -> void:
	value_drag = move_toward(value_drag, status.health/status.max_health, delta*0.25)
	value = value_drag
	true_bar.value = status.health/status.max_health
