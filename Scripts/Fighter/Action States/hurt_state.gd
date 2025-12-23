class_name HurtState

extends ActionState

@onready var inp: InputManager = $"../../GenericAttributes/InputManager"
@onready var anim: AnimationTree = $"../../Art/AnimationTree"
@onready var hurtbox: CollisionShape2D = $"../../SpecialAttributes/Hurtbox/CollisionShape2D"
@onready var anim_playback: AnimationNodeStateMachinePlayback = anim.get("parameters/AnimationNodeStateMachine/playback")
@onready var entity_status: EntityStatus = $"../../GenericAttributes/EntityStatus"

var mov_param: EntityMovementParameters
var jmp_param: EntityJumpParameters
var hurt_param: PlayerHurtParameters

var counter: float = 0
var animation_duration: float
var knockdown: knockdown_state
var knockdown_timer: float = 0.0
var slam_number: int = 0

enum knockdown_state {UPRIGHT, KNOCKDOWN, PRONE, GETUP}

const KNOCKDOWN_I_TIME: float = 2

func _ready() -> void:
	super._ready()
	mov_param = entity.parameters["hurt"]
	jmp_param = entity.parameters["jump"]
	hurt_param = entity.parameters["hurt"]
	
func _start() -> void:
	super._start()
	entity.get_node("EnvironmentBox").set_deferred("shape", mov_param.collision_shape) 
	entity.get_node("EnvironmentBox").position = mov_param.collision_shape_position
	counter = 0
	slam_number = 0
	
func _physics_process(delta: float) -> void:
	if !active: return
	if !entity.apply_physics: return
	
	#Decelerate
	entity.accelerate_x(mov_param.get_deceleration(entity) * delta, 0, true)
	entity.gravity = jmp_param.get_gravity(entity, 1.0)
	entity.velocity.y = min(entity.velocity.y, jmp_param.max_falling_speed)
	
	#Check for wall slam
	if entity.is_on_wall() and abs(entity.pre_move_velocity.x) > 50:
		var _len = entity.pre_move_velocity.length()/60
		var _dir = entity.pre_move_velocity.normalized()
		
		entity.inflict_hitstun(_len, _dir, 0.1)
		entity.velocity.x = -(entity.pre_move_velocity.x) * 0.7
		GameCamera.instance.shake_screen(_len/3, 0.25)
		slam_number += 1
		if slam_number >= 3:
			hurtbox.set_deferred("disabled", true)
			
	#Check for floor slam
	if entity.is_on_floor() and (entity.pre_move_velocity.y > 80 or abs(entity.pre_move_velocity).x > 100):
		var _len = entity.pre_move_velocity.length()/60
		var _dir = entity.pre_move_velocity.normalized()
		
		entity.inflict_hitstun(_len, _dir, 0.05)
		entity.velocity.y = -70
		entity.velocity.x = entity.pre_move_velocity.x*0.8
		GameCamera.instance.shake_screen(_len/3, 0.25)
		slam_number += 1
		if slam_number >= 3:
			hurtbox.set_deferred("disabled", true)
		
	elif entity.is_on_floor() and knockdown == knockdown_state.KNOCKDOWN and entity.pre_move_velocity.y > 0:
		anim_playback.start("KnockedDown", true)
		knockdown = knockdown_state.PRONE
		knockdown_timer = 0.0
		hurtbox.set_deferred("disabled", true)
		
	#Bottom out speed
	if abs(entity.velocity.x) < mov_param.get_minimum_speed(entity):
		entity.velocity.x = 0
	
	counter += delta
	
	#End hurt animation after certain time
	if counter >= animation_duration and not knockdown:
		entity.switch_action_state(entity.after_hurt_state)
		anim_playback.start("Grounded", true)
	
	#Try getup if prone
	if knockdown == knockdown_state.PRONE and entity_status.health > 0:
		knockdown_timer = move_toward(knockdown_timer, KNOCKDOWN_I_TIME, delta)
		if knockdown_timer == KNOCKDOWN_I_TIME:
			hurtbox.set_deferred("disabled", false)
		var _hor: float = inp.input_direction.x
		if _hor != 0:
			knockdown = knockdown_state.GETUP
			anim_playback.start("GetUp", true)
			await anim.animation_finished
			entity.switch_action_state_name("NormalState")
			anim_playback.start("Grounded", true)
		
func _end() -> void:
	super._end()
	print("hurt end")
	knockdown = knockdown_state.UPRIGHT
	hurtbox.set_deferred("disabled", false)
