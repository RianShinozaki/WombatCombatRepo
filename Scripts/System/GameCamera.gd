class_name GameCamera

extends Camera2D

@export var targets: Array[Node2D]
static var instance: GameCamera
@export var target_offset_y: float
@export var x_extents: Vector2
@export var y_extents: Vector2

var shake_amount: float = 0

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	await get_tree().process_frame
	targets.clear()
	print(Game.instance.fighter_1.name)
	targets.append(Game.instance.fighter_1.get_node("Fighter"))
	targets.append(Game.instance.fighter_2.get_node("Fighter"))

func lerp_zoom(_target: int, _trans_time: float = 0.3) -> void:
	var _targf: float = float(_target)
	create_tween().tween_property(self, "zoom", Vector2.ONE * _targf, _trans_time).set_trans(Tween.TRANS_SINE)

func _physics_process(_delta: float) -> void:
	var _cs = get_camera_size()
	if targets.is_empty(): return
	
	global_position = global_position.lerp(get_camera_target(), 4 * _delta)
	global_position.x = clamp(global_position.x, x_extents.x + _cs.x/2, x_extents.y - _cs.x/2)
	global_position.y = clamp(global_position.y, y_extents.x + _cs.y/2, y_extents.y - _cs.y/2)
	if shake_amount > 0:
		global_position += Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))

func get_camera_size():
	return get_viewport_rect().size/zoom.x
	
func get_camera_target() -> Vector2:
	var _avg_pos: Vector2 = Vector2.ZERO
	for _target in targets:
		_avg_pos += _target.global_position + Vector2.UP * target_offset_y
	return _avg_pos / targets.size()

func set_extents(_x_extents: Vector2, _y_extents: Vector2):
	x_extents = _x_extents
	y_extents = _y_extents

func shake_screen(_amount: float, _duration: float):
	if shake_amount > 0: return
	shake_amount = _amount
	await get_tree().create_timer(_duration).timeout
	shake_amount = 0
