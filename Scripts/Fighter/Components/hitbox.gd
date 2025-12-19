class_name Hitbox

extends Area2D

@export var hitbox_data: HitboxData

#When this hitbox hits an enemy, inform the root entity
func on_impact(_hurtbox: Area2D):
	$"../../..".on_impact(hitbox_data ,_hurtbox)
