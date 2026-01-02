class_name Hurtbox

extends Area2D

var entity: CollisionEntity
func _ready() -> void:
	area_entered.connect(on_area_entered)
	entity = $"../.."
	
func on_area_entered(_area: Area2D):
	var _hb_data: HitboxData = _area.hitbox_data
	var _action_state = entity.current_action_state
	if _action_state.has_method("process_damage"):
		entity.current_action_state.process_damage(_area)
	else:
		entity.process_damage(_area)
	#_area.on_impact(self)
