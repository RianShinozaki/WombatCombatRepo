extends Hitbox

@export var entity: CollisionEntity

func on_impact(_hurtbox: Area2D):
	entity.on_impact(hitbox_data, _hurtbox)
