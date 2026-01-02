class_name NormalState

extends ActionState

@onready var entity_status: EntityStatus = $"../../GenericAttributes/EntityStatus"
#@onready var land_fx_pool = $"../../SpecialAttributes/ObjectPools/Land"
var inp: InputManager
var anim: AnimationTree

var mov_param: EntityMovementParameters
var jmp_param: EntityJumpParameters
var can_short_hop: bool
var jump_initiated: bool

func _ready() -> void:
	super._ready()
	inp = entity.get_node("GenericAttributes/InputManager")
	mov_param = entity.parameters["movement"]
	jmp_param = entity.parameters["jump"]
	anim = entity.get_node("Art/AnimationTree")
	
	#inp.action_a_just_pressed.connect(on_jump)
	#inp.action_b_just_pressed.connect(on_light_attack)
	#inp.action_c_just_pressed.connect(on_heavy_attack)
	
	inp.double_tap_direction.connect(on_double_tap)
	entity.just_grounded.connect(just_grounded)

func _start() -> void:
	super._start()
	
	#Apply appropriate collision boxes
	entity.get_node("EnvironmentBox").shape = mov_param.collision_shape
	entity.get_node("EnvironmentBox").position = mov_param.collision_shape_position
	can_short_hop = false
	jump_initiated = false
	
func _process(delta: float) -> void:
	super._process(delta)
	if not active: return
	
	#Check for duck input
	if entity.is_on_floor(): 
		#entity.get_node("Art/AfterImageGenerator").call("stop_afterimages")
		if inp.get_input_y() > 0.3:
			entity.switch_action_state_name("DuckState")
			
	#Process input buffer
	if not entity.inputs_buffer.is_empty():
		for _i in range(entity.inputs_buffer.size()):
			var _input: Fighter.input_code = entity.inputs_buffer[_i]
			match(_input):
				Fighter.input_code.A:
					if entity.jumps > 1 and not jump_initiated:
						jump_initiated = true
						entity.jumps -= 1
						on_jump()
						entity.inputs_buffer.remove_at(_i)
						entity.inputs_buffer_times.remove_at(_i)
						return
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
			
	
	#Accelerate
	var hor = inp.get_input_x()
	if abs(hor) > 0 && (sign(hor) == sign(entity.velocity.x) || entity.velocity.x == 0):
		entity.accelerate_x(mov_param.get_acceleration(entity) * delta * sign(hor), sign(hor) * mov_param.get_max_speed(), true)
		if abs(entity.velocity.x) < mov_param.get_initial_speed(entity):
			entity.velocity.x = mov_param.get_initial_speed(entity) * sign(hor)
	
	#Accelerate when running counter to current momentum
	if abs(hor) > 0 && sign(hor) != sign(entity.velocity.x):
		entity.accelerate_x(mov_param.get_reverse_acceleration(entity) * delta, 0, false)
	
	# Decelerate
	if abs(hor) == 0 or sign(hor) == -sign(entity.velocity.x):
		entity.dashing = false
		entity.accelerate_x(mov_param.get_deceleration(entity) * delta, 0, false)
		if abs(entity.velocity.x) < mov_param.get_minimum_speed(entity):
			entity.velocity.x = 0
	
	#Turn the player around
	entity.get_node("Art").flip_h = false if entity.opponent.global_position.x > entity.global_position.x else true
	entity.get_node("SpecialAttributes/Hitboxes").scale.x = -1 if entity.get_node("Art").flip_h else 1
			
	#Update gravity
	if(entity.velocity.y > jmp_param.falling_threshold): can_short_hop = false
	var _do_short_hop = can_short_hop and not inp.action_a_pressed
	entity.gravity = jmp_param.get_gravity(entity, jmp_param.short_hop_gravity_scale if _do_short_hop else 1.0)
	entity.velocity.y = min(entity.velocity.y, jmp_param.max_falling_speed)
	
	var _art: Sprite2D = entity.get_node("Art")
	var _to_angle: float = 0
	_art.global_rotation = lerp_angle(_art.global_rotation,_to_angle,delta * 10)


func _end() -> void:
	entity.set_deferred("dashing", false)
	super._end()

func on_jump():
	if not active: return
	anim.get("parameters/AnimationNodeStateMachine/playback").start("JumpSquat", true)
	var _anim = await anim.animation_finished
	jump_initiated = false
	if _anim == "JumpSquat":
		var _hor = sign(inp.get_input_x())
		entity.velocity.x = mov_param.max_speed * _hor
		can_short_hop = true
		entity.velocity.y = jmp_param.get_jump_power()
		$"../../SpecialAttributes/SFX/Jump".play()

func on_light_attack():
	if not active: return
	
	#check for hadouken input
	var _hadouken = check_input_pattern(entity.hadouken_pattern_l) if entity.get_node("Art").flip_h else check_input_pattern(entity.hadouken_pattern_r)
	var _uppercut = check_input_pattern(entity.uppercut_pattern_l) if entity.get_node("Art").flip_h else check_input_pattern(entity.uppercut_pattern_r)
	
	var _attack: AttackState = entity.get_action_state_name("AttackState")
	entity.switch_action_state(_attack)
	if _uppercut:
		_attack._initiate("uppercut")
		_attack.post_attack_state = entity.get_action_state_name("NormalState")
	elif _hadouken:
		_attack._initiate("light hadouken")
	else:
		_attack._initiate("light")
	
func on_heavy_attack():
	if not active: return
	#check for hadouken input
	var _hadouken = check_input_pattern(entity.hadouken_pattern_2_l) if entity.get_node("Art").flip_h else check_input_pattern(entity.hadouken_pattern_2_r)
	var _topspin = check_input_pattern(entity.topspin_pattern_l) if entity.get_node("Art").flip_h else check_input_pattern(entity.topspin_pattern_r)

	var _attack: AttackState = entity.get_action_state_name("AttackState")
	entity.switch_action_state(_attack)
	
	if _topspin:
		_attack._initiate("heavy topspin")
	elif _hadouken:
		_attack._initiate("heavy hadouken")
	elif entity.dashing:
		_attack._initiate("heavy dash")
	else:
		_attack._initiate("heavy")

func on_double_tap(_direction: Vector2):
	if _direction.x != 0:
		entity.velocity.x = mov_param.get_max_speed() * 1.6 * _direction.x
		entity.dashing = true
	
#Grounded animation handler
func just_grounded(_normal: Vector2, _velocity: Vector2):
	if not active: return
	entity_status.knockdown = 0.0
	$"../../SpecialAttributes/SFX/Land".play()
	play_animation_oneshot("Land")

func play_animation_oneshot(_anim: String):
	anim.get("parameters/AnimationNodeStateMachine/Grounded/playback").start(_anim, true)

func check_input_pattern(_pattern: Array[Fighter.input_code]) -> bool:
	if entity.inputs_queue.size() < _pattern.size(): return false
	for i in range(_pattern.size()):
		if _pattern[i] != entity.inputs_queue[entity.inputs_queue.size() - _pattern.size() + i]:
			return false
	return true
