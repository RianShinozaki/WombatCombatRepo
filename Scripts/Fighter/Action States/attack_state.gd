class_name AttackState

extends ActionState

var inp: InputManager
var anim: AnimationTree

var mov_param: EntityMovementParameters
var jmp_param: EntityJumpParameters

var can_short_hop:
	get:
		return entity.get_node("ActionStates/NormalState").can_short_hop
	set(_value):
		entity.get_node("ActionStates/NormalState").can_short_hop = _value
		
var combo_number: int = 0
var combo_timer: float
var combo_max_time: float

func _ready() -> void:
	super._ready()
	inp = entity.get_node("GenericAttributes/InputManager")
	mov_param = entity.parameters["attack_movement"]
	jmp_param = entity.parameters["jump"]
	anim = entity.get_node("Art/AnimationTree")

func _start() -> void:
	super._start()

func _initiate(_status: String = ""):
	var _direction = inp.input_direction

	anim.get("parameters/AnimationNodeStateMachine/playback").start("Attack", true)
	
	var _input = inp.input_direction
	
	#Handle attack inputs
	if _status.contains("light"):
		if _status.contains("duck"):
			entity.velocity.x = 0
			play_animation_oneshot("DuckPunch")
		elif entity.is_on_floor():
			entity.velocity.x = 0
			play_animation_oneshot("Punch")
		else:
			play_animation_oneshot("AirPunch")
	
	if _status.contains("heavy"):
		if _status.contains("dash") and entity.is_on_floor():
			play_animation_oneshot("DashKick")
		elif _status.contains("duck"):
			entity.velocity.x = 0
			play_animation_oneshot("LowKick")
		elif entity.is_on_floor():
			entity.velocity.x = 0
			play_animation_oneshot("Kick")
		else:
			play_animation_oneshot("AirKick")
	
	
func _process(delta: float) -> void:
	super._process(delta)
	if not active: return
	
	#Decelerate
	if entity.is_on_floor():
		entity.accelerate_x(mov_param.get_deceleration(entity) * delta, 0, false)
		if abs(entity.velocity.x) < mov_param.get_minimum_speed(entity):
			entity.velocity.x = 0
				
	#Update gravity
	if(entity.velocity.y > jmp_param.rising_gravity_scale): can_short_hop = false
	var _do_short_hop = can_short_hop and not inp.action_a_pressed
	entity.gravity = jmp_param.get_gravity(entity, jmp_param.short_hop_gravity_scale if _do_short_hop else 1.0)
	entity.velocity.y = min(entity.velocity.y, jmp_param.max_falling_speed)
	
	var _art: Sprite2D = entity.get_node("Art")
	var _to_angle: float = 0
	_art.global_rotation = lerp_angle(_art.global_rotation,_to_angle,delta * 10)

func _end() -> void:
	super._end()
	can_short_hop = false

func play_animation_oneshot(_anim: String):
	anim.get("parameters/AnimationNodeStateMachine/Attack/playback").start(_anim, true)
	
func animation_cancel():
	entity.switch_action_state_name("NormalState")
