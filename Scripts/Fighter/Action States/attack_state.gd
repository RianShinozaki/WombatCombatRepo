class_name AttackState

extends ActionState

var inp: InputManager
var anim: AnimationTree

var mov_param: EntityMovementParameters
var jmp_param: EntityJumpParameters

@onready var sfx_light_attack: AudioStreamPlayer2D = $"../../SpecialAttributes/SFX/LightAttack"
@onready var sfx_heavy_attack: AudioStreamPlayer2D = $"../../SpecialAttributes/SFX/HeavyAttack"
@onready var sfx_magic_attack: AudioStreamPlayer2D = $"../../SpecialAttributes/SFX/MagicAttack"

@onready var post_attack_state: ActionState = $"../NormalState"

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
	post_attack_state = entity.last_action_state
	anim.get("parameters/AnimationNodeStateMachine/playback").start("Attack", true)
	
	var _input = inp.input_direction
	
	#Handle attack inputs
	if _status.contains("light"):
		if _status.contains("hadouken"):
			entity.velocity.x = 0
			play_animation_oneshot("Hadouken")
		elif _status.contains("duck"):
			entity.velocity.x = 0
			play_animation_oneshot("DuckPunch")
			sfx_light_attack.play()
		elif entity.is_on_floor():
			entity.velocity.x = 0
			play_animation_oneshot("Punch")
			sfx_light_attack.play()
		else:
			play_animation_oneshot("AirPunch")
			sfx_light_attack.play()
	
	if _status.contains("heavy"):
		if _status.contains("hadouken"):
			entity.velocity.x = 0
			play_animation_oneshot("Hadouken_Heavy")
		elif _status.contains("dash") and entity.is_on_floor():
			play_animation_oneshot("DashKick")
			sfx_heavy_attack.play()
		elif _status.contains("duck"):
			entity.velocity.x = 0
			play_animation_oneshot("LowKick")
			sfx_heavy_attack.play()
		elif entity.is_on_floor():
			entity.velocity.x = 0
			play_animation_oneshot("Kick")
			sfx_heavy_attack.play()
		else:
			play_animation_oneshot("AirKick")
			sfx_heavy_attack.play()
	
	
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
	entity.switch_action_state(post_attack_state)

func spawn_hadouken(_power: int):
	sfx_magic_attack.play()
	
	var _hadouken: Area2D
	if _power == 0:
		_hadouken = $"../../SpecialAttributes/HadoukenPool".spawn_object()
	else:
		_hadouken = $"../../SpecialAttributes/HadoukenHeavyPool".spawn_object()
	
	_hadouken.global_position = global_position + Vector2.RIGHT * (-20 if $"../../Art".flip_h else 20)
	_hadouken.get_node("Art").flip_h = $"../../Art".flip_h
	
	_hadouken.collision_layer = entity.p1_hitbox_layer if entity.fighter_id == 1 else entity.p2_hitbox_layer
	_hadouken.collision_mask = (entity.p2_hurtbox_layer + entity.p2_hitbox_layer) if entity.fighter_id == 1 else (entity.p1_hurtbox_layer + entity.p1_hitbox_layer)

func just_grounded(_normal: Vector2, _velocity: Vector2):
	#var fx: Node2D = land_fx_pool.spawn_object()
	#if fx != null:
	#	fx.global_position = entity.global_position + Vector2.DOWN*8;
	#	fx.rotation = entity.get_floor_angle() * sign(entity.get_floor_normal().x)
	if not active: return
	$"../../SpecialAttributes/SFX/Land".play()
