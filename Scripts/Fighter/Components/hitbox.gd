class_name Hitbox

extends Area2D

@export var hitbox_data: HitboxData
var disabled: bool = false

func _ready() -> void:
	area_entered.connect(on_impact)
	
func _physics_process(_delta: float) -> void:
	if $CollisionShape2D.disabled: 
		disabled = false
	
#When this hitbox hits an enemy, inform the root entity
func on_impact(area2D: Area2D):
	#if area2D is Hurtbox:
	$"../../..".on_impact(hitbox_data)
	set_deferred("disabled", true)
