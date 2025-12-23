class_name DuckState

extends ActionState

var inp: InputManager
var anim: AnimationTree

var duck_param: DuckParameters
var mov_param: EntityMovementParameters
var can_unduck: bool

func _ready() -> void:
	super._ready()
	inp = entity.get_node("GenericAttributes/InputManager")
	anim = entity.get_node("Art/AnimationTree")
	duck_param = entity.parameters["duck"]

func _start() -> void:
	super._start()
	entity.get_node("EnvironmentBox").shape = duck_param.collision_shape
	entity.get_node("EnvironmentBox").position = duck_param.collision_shape_position
	anim.get("parameters/AnimationNodeStateMachine/playback").start("Grounded", true)
	anim.get("parameters/AnimationNodeStateMachine/Grounded/playback").start("Duck", true)
	can_unduck = false

func _process(delta: float) -> void:
	if !active: return
	var _vert: float = inp.input_direction.y
	
	#Stop ducking
	if _vert <= 0.3 or not entity.is_on_floor():
		entity.switch_action_state_name("NormalState")
		return
	
	#Process input buffer
	if not entity.inputs_buffer.is_empty():
		for _i in range(entity.inputs_buffer.size()):
			var _input: Fighter.input_code = entity.inputs_buffer[_i]
			match(_input):
				Fighter.input_code.B:
					on_light_attack()
					entity.inputs_buffer.remove_at(_i)
					entity.inputs_buffer_times.remove_at(_i)
					return
				Fighter.input_code.C:
					on_heavy_attack()
					entity.inputs_buffer.remove_at(_i)
					entity.inputs_buffer_times.remove_at(_i)
					return
	#Decelerate
	entity.accelerate_x(duck_param.get_deceleration(entity) * delta, 0, false)
	if abs(entity.velocity.x) < duck_param.get_minimum_speed(entity):
		entity.velocity.x = 0
		
	var _art: Sprite2D = entity.get_node("Art")
	var _to_angle: float = (entity.get_floor_angle() * sign(entity.get_floor_normal().x))
	_art.global_rotation = lerp_angle(_art.global_rotation,_to_angle,delta * 10)

func on_light_attack():
	if not active: return
	var _attack: AttackState = entity.get_action_state_name("AttackState")
	entity.switch_action_state(_attack)
	_attack._initiate("duck light")
	
func on_heavy_attack():
	if not active: return
	var _attack: AttackState = entity.get_action_state_name("AttackState")
	var _uppercut = check_input_pattern(entity.uppercut_pattern_l) if entity.get_node("Art").flip_h else check_input_pattern(entity.uppercut_pattern_r)

	entity.switch_action_state(_attack)
	if _uppercut:
		_attack._initiate("heavy uppercut")
		_attack.post_attack_state = entity.get_action_state_name("NormalState")
	else:
		_attack._initiate("duck heavy")
	
func _end() -> void:
	super._end()
	anim.get("parameters/AnimationNodeStateMachine/playback").start("Grounded", true)
	anim.get("parameters/AnimationNodeStateMachine/Grounded/playback").start("Idle", true)

func check_input_pattern(_pattern: Array[Fighter.input_code]) -> bool:
	if entity.inputs_queue.size() < _pattern.size(): return false
	for i in range(_pattern.size()):
		if _pattern[i] != entity.inputs_queue[entity.inputs_queue.size() - _pattern.size() + i]:
			return false
	return true
