extends ProgressBar

@export var target: CollisionEntity

var status: EntityStatus

func _ready() -> void:
	status = target.get_node("GenericAttributes/EntityStatus")
	
func _process(delta: float) -> void:
	value = status.health/status.max_health
