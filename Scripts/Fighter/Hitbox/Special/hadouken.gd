class_name Hadouken

extends Hitbox

@onready var opo: ObjectPoolObject = $ObjectPoolObject
@onready var art: AnimatedSprite2D = $Art
@export var speed: float

var active: bool = false
var alive_counter: float = 0
var initial_damage: float = 0
var orig_damage: float = 0
var orig_knockdown: float = 0

func _ready() -> void:
	orig_damage = hitbox_data.damage
	orig_knockdown = hitbox_data.knockdown_power
	active = false
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	area_entered.connect(on_area_entered)

func _physics_process(delta: float) -> void:
	if not active: return
	global_position.x += speed * delta * (-1 if art.flip_h else 1)
	if abs(global_position).x > 150: despawn()
	alive_counter += delta
	hitbox_data.x_knockback = abs(hitbox_data.x_knockback) * (-1 if art.flip_h else 1)
	if alive_counter >= 0.3:
		alive_counter -= 0.3
		@warning_ignore("narrowing_conversion")
		hitbox_data.damage -= orig_damage/4.0
		hitbox_data.knockdown_power -= orig_knockdown/5.0
		scale -= Vector2.ONE*0.1
		if hitbox_data.damage <= 0:
			despawn()

func despawn():
	active = false
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	opo.despawn()
	$MagicLoop.stop()
	
func on_spawn():
	scale = Vector2.ONE
	@warning_ignore("narrowing_conversion")
	hitbox_data.damage = orig_damage
	hitbox_data.knockdown_power = orig_knockdown
	active = true
	visible = true
	$CollisionShape2D.set_deferred("disabled", false)
	$MagicLoop.play()

func on_area_entered(_area: Area2D):
	despawn()
