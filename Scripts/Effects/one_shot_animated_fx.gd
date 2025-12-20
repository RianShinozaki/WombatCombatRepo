class_name OneShotAnimatedFX

extends AnimatedSprite2D

@onready var opo: ObjectPoolObject  = get_node("ObjectPoolObject")

func _ready() -> void:
	visible = false
	
func on_spawn():
	pass

func initiate(_sprite: SpriteFrames):
	sprite_frames = _sprite
	play("default")
	visible = true

func _on_animation_finished() -> void:
	opo.despawn()
	visible = false
	stop()
