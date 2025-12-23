class_name HurtManager

extends Node2D

@export var auto_hook: bool = true

## Basically the super-armor stat
@export var power_resistance: int
@export var capture_ui: bool = true

@onready var fx_pool = $"../OneShotFXPool"
@onready var anim = $"../../Art/AnimationTree"
@onready var anim_playback: AnimationNodeStateMachinePlayback = anim.get("parameters/AnimationNodeStateMachine/playback")
@onready var entity_status: EntityStatus = $"../../GenericAttributes/EntityStatus"
@onready var shape: CollisionShape2D = $"../Hurtbox/CollisionShape2D"
@onready var anim_player: AnimationPlayer = $"../../Art/AnimationPlayer"

var entity: Fighter

signal staggered

@onready var sfx_light_hit: AudioStreamPlayer2D = $"../../SpecialAttributes/SFX/LightHit"
@onready var sfx_heavy_hit: AudioStreamPlayer2D = $"../../SpecialAttributes/SFX/HeavyHit"
@onready var sfx_magic_hit: AudioStreamPlayer2D = $"../../SpecialAttributes/SFX/MagicHit"

var knockdown_mult: float = 1.0
var last_hitbox: Hitbox

func _ready() -> void:
	if auto_hook: entity = get_parent().get_parent()
	
func process_hurt(_hitbox: Hitbox):
	if _hitbox.disabled: return
	#Get hitbox data
	var _hb_data: HitboxData = _hitbox.hitbox_data
	
	var _ducking: bool = entity.current_action_state.name == "DuckState"
	var _blocked: bool = check_blocked(_hb_data)
	var _knockdown: bool = false
	var _hurt: HurtState = entity.switch_action_state_name("HurtState")
	
	#Process X knockback direction
	var _x_knockback: float = _hb_data.x_knockback if not _blocked else _hb_data.x_knockback_on_block
	if _hb_data.x_knockback_is_relative:
		_x_knockback *= -1 if _hitbox.global_position.x > global_position.x else 1
	
	#Process Y knockback
	var _y_knockback: float = _hb_data.y_knockback if not _blocked else _hb_data.x_knockback_on_block
	
	#Get knockdown total
	if last_hitbox == _hitbox:
		knockdown_mult += 0.8
	var _knockdown_total: float = _hb_data.knockdown_power * knockdown_mult
	knockdown_mult += 0.2
	
	#Get knockback attributes for hitstun
	var _knockback_total: Vector2 = Vector2(_x_knockback, _hb_data.y_knockback)
	var _len = _knockback_total.length() / 60
	var _dir = _knockback_total.normalized()
	var _hs = _hb_data.hitstun_duration_frames if not _blocked else _hb_data.hitstun_duration_frames_on_block
	
	#Get the hurt animation duration
	var _hurt_duration = _hb_data.force_hurt_duration_frames if not _blocked else _hb_data.force_hurt_duration_frames_on_block
		
	#Manage HP
	var _blocked_damage: float = float(_hb_data.damage)-3.0
	if _blocked_damage <= 1: _blocked_damage = 0
	
	#Apply knockback (or ignore knockback if knockdown is too high)
	if _knockdown_total > 2.0:
		return
		
	entity_status.health -= float(_hb_data.damage) if not _blocked else _blocked_damage
	
	if entity_status.health <= 0:
		shape.set_deferred("disabled", true)
		_blocked = false
	
	#Check knockdown
	if not _blocked:
		entity_status.knockdown += _knockdown_total
		if entity_status.knockdown >= entity_status.max_knockdown:
			_knockdown = true
			
	if entity_status.health <= 0:
		_knockdown = true
		
	#Apply knockback depending on "power" level and whether it was blocked
	if power_resistance < _hb_data.knockback_power or _blocked:
		#Apply the appropriate animation
		if not _blocked:
			#Knockdown if appropriate
			if _knockdown and _hurt.knockdown != HurtState.knockdown_state.PRONE and _hurt.knockdown != HurtState.knockdown_state.GETUP:
				anim_playback.start("KnockedAir", true)
				
				#Quickly shift body upwards if switching into knocked air
				if _hurt.knockdown == HurtState.knockdown_state.UPRIGHT:
					var _vel_store: Vector2 = entity.velocity
					entity.velocity.x = 0
					entity.velocity.y = -5*60
					entity.move_and_slide()
					entity.velocity = _vel_store
				
				_hurt.knockdown = HurtState.knockdown_state.KNOCKDOWN
			#Initiate "Air flip back" for strong enough aerial hits
			elif (entity.is_on_floor() == false and _knockdown_total >= entity_status.max_knockdown/2) or (_hurt.knockdown == HurtState.knockdown_state.PRONE or _hurt.knockdown == HurtState.knockdown_state.GETUP):
				_hurt.knockdown = HurtState.knockdown_state.UPRIGHT
				anim_playback.start("HurtAir", true)
				_hurt_duration = anim_player.get_animation("HurtAir").length * 60
				_x_knockback = 140 * sign(_x_knockback)
				_y_knockback = -60
				entity.velocity.y = 0
			else:
				anim_playback.start("Hurt", true)
		else:
			if _ducking:
				anim_playback.start("DuckBlock", true)
			else:
				anim_playback.start("Block", true)

		if not _hb_data.x_knockback_is_additive:
			entity.velocity.x = _x_knockback
		else:
			entity.velocity.x += _x_knockback
		
		if not _hb_data.y_knockback_is_additive:
			entity.velocity.y = _y_knockback
		else:
			entity.velocity.y += _y_knockback
			
		_hurt.animation_duration = frames_to_sec(_hurt_duration)
		emit_signal("staggered")
	
	#Process screenshake
	GameCamera.instance.shake_screen(_len/(3 if not _blocked else 5), 0.25)
	
	#Process hitstun
	if _hurt.knockdown == HurtState.knockdown_state.KNOCKDOWN:
		entity.inflict_hitstun(_len, _dir, frames_to_sec(_hs)/4)
	else:
		entity.inflict_hitstun(_len, _dir, frames_to_sec(_hs))
	
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
	
	#Set sort order
	if not _blocked:
		entity.z_index = -1
		entity.opponent.z_index = 1
	if _blocked:
		entity.z_index = 1
		entity.opponent.z_index = -1
	
	#Play sound
	if not _blocked:
		match _hb_data.impact_fx:
			"Small Hit":
				sfx_light_hit.play()
			"Med Hit":
				sfx_heavy_hit.play()
			"Hadouken":
				sfx_magic_hit.play()
		
	#Cache hitbox
	last_hitbox = _hitbox
	
	#Store correct recovery state
	if _blocked and _ducking:
		entity.after_hurt_state = entity.get_action_state_name("DuckState")
	else:
		entity.after_hurt_state = entity.get_action_state_name("NormalState")

func _physics_process(_delta: float) -> void:
	var _hurt: HurtState = entity.get_action_state_name("HurtState")
	if _hurt.knockdown == HurtState.knockdown_state.PRONE or entity.current_action_state != entity.get_action_state_name("HurtState"):
		knockdown_mult = 1.0
		entity_status.knockdown = 0
		last_hitbox = null
		
func frames_to_sec(_frames: int):
	return 1.0 / 60 * _frames

func check_blocked(_hitbox_data: HitboxData) -> bool:
	#Can't block in the air
	if not entity.is_on_floor():
		return false
		
	#Can only block in normal or ducking state
	var _state_name = entity.current_action_state.name
	if _state_name != "NormalState" and _state_name != "DuckState":
		return false
	var _guard: bool = entity.moving_toward_opponent == -1
	var _ducking: bool = entity.current_action_state.name == "DuckState"
	
	if _guard and _ducking and _hitbox_data.damage_range != HitboxData.range_type.HIGH:
		return true
	if _guard and not _ducking and _hitbox_data.damage_range != HitboxData.range_type.LOW:
		return true
	return false
