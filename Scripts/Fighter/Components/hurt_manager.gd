class_name HurtManager

extends Node2D

@export var auto_hook: bool = true

## Basically the super-armor stat
@export var power_resistance: int
@export var capture_ui: bool = true

@onready var fx_pool = $"../OneShotFXPool"

var entity: Fighter

signal staggered

func _ready() -> void:
	if auto_hook: entity = get_parent().get_parent()
	
func process_hurt(_hitbox: Area2D):
	#Get hitbox data
	var _hb_data: HitboxData = _hitbox.hitbox_data
	
	var _ducking: bool = entity.current_action_state.name == "DuckState"
	var _blocked: bool = check_blocked(_hb_data)
	
	#Process X knockback direction
	var _x_knockback: float = _hb_data.x_knockback if not _blocked else _hb_data.x_knockback_on_block
	if _hb_data.x_knockback_is_relative:
		_x_knockback *= -1 if _hitbox.global_position.x > global_position.x else 1
	
	#Process Y knockback
	var _y_knockback: float = _hb_data.y_knockback if not _blocked else _hb_data.x_knockback_on_block
	
	#Apply knockback depending on "power" level and whether it was blocked
	if power_resistance < _hb_data.knockback_power or _blocked:
		if not _hb_data.x_knockback_is_additive:
			entity.velocity.x = _x_knockback
		else:
			entity.velocity.x += _x_knockback
		
		if not _hb_data.y_knockback_is_additive:
			entity.velocity.y = _y_knockback
		else:
			entity.velocity.y += _y_knockback
			
		var _hurt: HurtState = entity.switch_action_state_name("HurtState")
		
		#Apply the appropriate animation
		if not _blocked:
			$"../../Art/AnimationTree".get("parameters/AnimationNodeStateMachine/playback").start("Hurt", true)
		else:
			if _ducking:
				$"../../Art/AnimationTree".get("parameters/AnimationNodeStateMachine/playback").start("DuckBlock", true)
			else:
				$"../../Art/AnimationTree".get("parameters/AnimationNodeStateMachine/playback").start("Block", true)
		var _hurt_duration = _hb_data.force_hurt_duration_frames if not _blocked else _hb_data.force_hurt_duration_frames_on_block
		_hurt.animation_duration = frames_to_sec(_hurt_duration)
		emit_signal("staggered")
	
	#Get knockback attributes for hitstun
	var _knockback_total: Vector2 = Vector2(_x_knockback, _hb_data.y_knockback)
	var _len = _knockback_total.length() / 60
	var _dir = _knockback_total.normalized()
	var _hs = _hb_data.hitstun_duration_frames if not _blocked else _hb_data.hitstun_duration_frames_on_block
	
	GameCamera.instance.shake_screen(_len/(3 if not _blocked else 5), 0.25)
	entity.inflict_hitstun(_len, _dir, frames_to_sec(_hs))
	
	#Manage HP
	entity.get_node("GenericAttributes/EntityStatus").health -= float(_hb_data.damage) if not _blocked else float(_hb_data.damage)/4.0
	
	#Create FX
	var _impact_fx = _hb_data.impact_fx if not _blocked else "Blocked"
	if _impact_fx != "":
		var fx: Node2D = fx_pool.spawn_fx(_impact_fx)
		var offset_y: float = _hitbox.get_node("CollisionShape2D").global_position.y - entity.global_position.y
		var offset_x: float = sign(_hitbox.get_node("CollisionShape2D").global_position.x - entity.global_position.x)*4
		var offset: Vector2 = Vector2(offset_x, offset_y)
		if fx != null:
			fx.global_position = entity.global_position + offset
			fx.global_scale.x = sign(_x_knockback)
	
	#fx = object_pools.get_node("BloodSpurt").spawn_object()
	#if fx != null:
	#	fx.global_position = entity.global_position + offset
	#	fx.global_scale.x = sign(_x_knockback)
	
	#Set sort order
	entity.z_index = -1
	entity.opponent.z_index = 1
	
func frames_to_sec(_frames: int):
	return 1.0 / 60 * _frames

func check_blocked(_hitbox_data: HitboxData) -> bool:
	var _guard: bool = entity.moving_toward_opponent == -1
	var _ducking: bool = entity.current_action_state.name == "DuckState"
	
	if _guard and _ducking and _hitbox_data.damage_range != HitboxData.range_type.HIGH:
		return true
	if _guard and not _ducking and _hitbox_data.damage_range != HitboxData.range_type.LOW:
		return true
	return false
