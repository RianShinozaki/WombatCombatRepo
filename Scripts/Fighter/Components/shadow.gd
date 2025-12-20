extends Sprite3D

@export var target: Node2D
@export var z_offset: float
@export var y: float
@export var pixel_scale: float

func _physics_process(_delta: float) -> void:
	global_position = pixel_scale * Vector3(target.global_position.x, y, z_offset)
