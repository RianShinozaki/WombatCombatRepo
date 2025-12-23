class_name CollisionEntity

extends CharacterBody2D

enum {COLLISION_MODE_FLOOR, COLLISION_MODE_FREE, COLLISION_MODE_BOUNCE}

@export_group("Collision")
@export var gravity: float
@export var collision_mode: int
@export_range(0, 1) var bounce_factor: float = 1

@export_group("States")
@export var apply_physics: bool
@export var previously_grounded: bool
@export var current_action_state: ActionState
@export var last_action_state: ActionState

@export_group("Parameters")
@export var parameters: Dictionary[String, ParameterSet]

signal just_grounded(normal: Vector2, velocity: Vector2)
signal just_bounced(normal: Vector2, velocity: Vector2)

var shake_level: float
var shake_direction: Vector2
var pre_move_velocity: Vector2

func _ready() -> void:
	velocity = Vector2.ZERO
	
var velocity_true: Vector2:
	get:
		if is_on_floor():
			return Vector2(-velocity.x * get_floor_normal().y, velocity.x * get_floor_normal().x)
		else:
			return velocity

func move(_velocity: Vector2, _delta: float, _update_velocity: bool) -> void:
	var _temp_velocity = velocity
	match collision_mode:
		COLLISION_MODE_FLOOR:
			velocity = _velocity
			motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
			move_and_slide()
		COLLISION_MODE_FREE:
			velocity = _velocity
			motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
			move_and_slide()
		COLLISION_MODE_BOUNCE:
			var _kc = move_and_collide(_velocity * _delta, true)
			if _kc != null:
				var _normal = _kc.get_normal()
				_velocity.y += gravity * _delta
				_velocity = -_velocity.reflect(_normal)
				var _loss_factor = Vector2(absf(_normal.x), absf(_normal.y)) * (1 - bounce_factor)
				var _impact_factor = Vector2(absf(_normal.x), absf(_normal.y)) * (bounce_factor)
				_velocity.x -= _loss_factor.x * _velocity.x
				_velocity.y -= _loss_factor.y * _velocity.y
				if(absf(_velocity.y) < 50): _velocity.y = 0
				emit_signal("just_bounced", _normal, _velocity)
			velocity = _velocity
			move_and_slide()
	
	if not _update_velocity:
		velocity = _temp_velocity
	
func _physics_process(delta: float) -> void:
	if !apply_physics: return
	
	if collision_mode == COLLISION_MODE_FLOOR:
		if is_on_floor() and velocity.y >= 0 and not previously_grounded:
			emit_signal("just_grounded", get_floor_normal(), velocity)
			velocity.y = 0
		if not is_on_floor() or velocity.y < 0:
			velocity.y += gravity * delta
	else:
		velocity.y += gravity * delta
	
	previously_grounded = is_on_floor()
	pre_move_velocity = velocity
	move(velocity, delta, true)
	
func accelerate_x(_amount: float, _limit: float, _toward: bool):
	velocity.x = move_toward(velocity.x, _limit, _amount * (sign(_amount) if _toward else 1))

func switch_action_state_name(_state: String) -> ActionState:
	var _action_state = get_action_state_name(_state)
	return switch_action_state(_action_state)

func get_action_state_name(_state: String) -> ActionState:
	return get_node("ActionStates/"+_state)
	
func switch_action_state(_state: ActionState) -> ActionState:
	if last_action_state != current_action_state:
		last_action_state = current_action_state
	if current_action_state != _state:
		current_action_state = _state
		last_action_state._end()
		current_action_state._start()
	return current_action_state

func inflict_hitstun(_shake_level: float, _shake_direction: Vector2, _duration: float, _stun_fx: float = 1.0):
	if not apply_physics: return
	apply_physics = false
	shake_level = _shake_level
	shake_direction = _shake_direction
	#$Art.material.set_shader_parameter("stunFX", _stun_fx)
	$Art/AnimationTree.set("parameters/TimeScale/scale", 0.0)
	await get_tree().create_timer(_duration).timeout
	#$Art.material.set_shader_parameter("stunFX", 0.0)
	$Art/AnimationTree.set("parameters/TimeScale/scale", 1.0)

	apply_physics = true
	shake_level = 0
	shake_direction = Vector2.ZERO

func on_impact(_hitbox_data: HitboxData, _hurtbox: Hurtbox):
	pass
