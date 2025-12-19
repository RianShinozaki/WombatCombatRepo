extends Sprite2D

var base_offset: Vector2 
var entity: CollisionEntity

func _ready() -> void:
	base_offset = offset
	entity = get_parent()
	
func _process(_delta: float) -> void:
	#Handle shaking visuals, usually for hitstun
	if entity.shake_level > 0:
		var _lvl = entity.shake_level
		offset = base_offset + entity.shake_direction * randf_range(-_lvl, _lvl)
	else:
		offset = base_offset
