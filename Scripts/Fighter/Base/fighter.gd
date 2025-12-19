class_name Fighter

extends CollisionEntity

@export_group("Mortal Wombat")
@export var opponent: Node2D
## Either 1 or 2
@export var fighter_id: int

@export_group("Setup")

@export_flags_2d_physics var p1_hitbox_layer: int
@export_flags_2d_physics var p1_hurtbox_layer: int
@export_flags_2d_physics var p2_hitbox_layer: int
@export_flags_2d_physics var p2_hurtbox_layer: int

var shove_entities: Array[Node2D]

var moving_toward_opponent: int = 0
# 0 -- not moving
# 1 -- moving toward
# -1 -- moving away


var dashing: bool = false

func _ready() -> void:
	#Align input manager with player id
	$GenericAttributes/InputManager.player_prefix = "p"+str(fighter_id)+"-"
	
	#Align hurtbox with player id
	$SpecialAttributes/Hurtbox.collision_layer = p1_hurtbox_layer if fighter_id == 1 else p2_hurtbox_layer
	$SpecialAttributes/Hurtbox.collision_mask = p2_hitbox_layer if fighter_id == 1 else p1_hitbox_layer
	
	#Align all hitboxes with player id
	var _hitboxes = $SpecialAttributes/Hitboxes
	for area in _hitboxes.get_children():
		area.collision_layer = p2_hitbox_layer if fighter_id == 2 else p1_hitbox_layer
		area.collision_mask = p1_hurtbox_layer if fighter_id == 2 else p2_hurtbox_layer
		
func _physics_process(_delta: float) -> void:
	#Manage "shoving," aka moving opponent away if too close
	for _entity in shove_entities:
		var dir: int = -1 if _entity.global_position > global_position else 1
		move(Vector2.RIGHT * 40 * dir, _delta, false)
	super._physics_process(_delta)
	
#Impact == when my attack hits an opponent
func on_impact(_hitbox_data: HitboxData, _hurtbox: Hurtbox):
	var _knockback_total: Vector2 = Vector2(_hitbox_data.x_knockback, _hitbox_data.y_knockback)
	var _len = _knockback_total.length() / 120
	var _dir = _knockback_total.normalized()
	inflict_hitstun(_len, _dir, 1.0 / 60 * _hitbox_data.self_hitstun_duration_frames, 0)

func process_damage(_area):
	$SpecialAttributes/HurtManager.process_hurt(_area)

func _on_shove_box_area_entered(area: Area2D) -> void:
	if not area in shove_entities: shove_entities.append(area)

func _on_shove_box_area_exited(area: Area2D) -> void:
	if area in shove_entities: shove_entities.erase(area)
