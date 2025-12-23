class_name Hitbox

extends Area2D

@export var hitbox_data: HitboxData
var disabled: bool = false

func _physics_process(_delta: float) -> void:
	if $CollisionShape2D.disabled: disabled = false
	
#When this hitbox hits an enemy, inform the root entity
func on_impact(_hurtbox: Area2D):
	$"../../..".on_impact(hitbox_data ,_hurtbox)
	disabled = true
