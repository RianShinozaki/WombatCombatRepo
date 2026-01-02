class_name Fighter

extends CollisionEntity

@export_group("Mortal Wombat")
@export var opponent: Node2D
## Either 1 or 2
@export var fighter_id: int

@export_group("Setup")

@export_flags_2d_physics var p1_hitbox_layer: int
@export_flags_2d_physics var p1_hitbox_mask: int
@export_flags_2d_physics var p1_hurtbox_layer: int
@export_flags_2d_physics var p2_hitbox_layer: int
@export_flags_2d_physics var p2_hitbox_mask: int
@export_flags_2d_physics var p2_hurtbox_layer: int

@export_group("Input")
enum input_code {RIGHT, RIGHT_DOWN, DOWN, LEFT_DOWN, LEFT, LEFT_UP, UP, RIGHT_UP, A, B, C}

@export var inputs_queue: Array[input_code]
@export var inputs_buffer: Array[input_code]
@export var inputs_buffer_times: Array[float]

@export var input_queue_max_frames: int
@export var input_buffer_max_frames: int

@onready var input: InputManager = $GenericAttributes/InputManager
@onready var after_hurt_state: ActionState = $ActionStates/NormalState

var shove_entities: Array[Node2D]
var moving_toward_opponent: int = 0
# 0 -- not moving
# 1 -- moving toward
# -1 -- moving away

var dashing: bool = false
var input_queue_time: float = 0.0

var hadouken_pattern_r: Array[input_code] = [input_code.DOWN, input_code.RIGHT_DOWN, input_code.RIGHT, input_code.B]
var hadouken_pattern_l: Array[input_code] = [input_code.DOWN, input_code.LEFT_DOWN, input_code.LEFT, input_code.B]

var hadouken_pattern_2_r: Array[input_code] = [input_code.DOWN, input_code.RIGHT_DOWN, input_code.RIGHT, input_code.C]
var hadouken_pattern_2_l: Array[input_code] = [input_code.DOWN, input_code.LEFT_DOWN, input_code.LEFT, input_code.C]

var uppercut_pattern_r: Array[input_code] = [input_code.RIGHT, input_code.RIGHT_UP, input_code.UP, input_code.B]
var uppercut_pattern_l: Array[input_code] = [input_code.LEFT, input_code.LEFT_UP, input_code.UP, input_code.B]

var topspin_pattern_l: Array[input_code] = [input_code.DOWN, input_code.RIGHT_DOWN, input_code.RIGHT, input_code.C]
var topspin_pattern_r: Array[input_code] = [input_code.DOWN, input_code.LEFT_DOWN, input_code.LEFT, input_code.C]

var jumps = 2

signal knockout(_fighter_kod: Fighter)

var active: bool

func _ready() -> void:
	await get_tree().process_frame

	opponent = Game.instance.fighter_1.get_node("Fighter") if fighter_id == 2 else Game.instance.fighter_2.get_node("Fighter")
	#Align input manager with player id
	input.player_prefix = "p"+str(fighter_id)+"-"
	
	#Align hurtbox with player id
	$SpecialAttributes/Hurtbox.collision_layer = p1_hurtbox_layer if fighter_id == 1 else p2_hurtbox_layer
	$SpecialAttributes/Hurtbox.collision_mask = p2_hitbox_layer if fighter_id == 1 else p1_hitbox_layer
	
	#Align all hitboxes with player id
	var _hitboxes = $SpecialAttributes/Hitboxes
	for area in _hitboxes.get_children():
		area.collision_layer = p2_hitbox_layer if fighter_id == 2 else p1_hitbox_layer
		area.collision_mask = p2_hitbox_mask if fighter_id == 2 else p1_hitbox_mask
	
	input.direction_input_code.connect(on_direction_input_code)
	input.action_a_just_pressed.connect(on_a_pressed)
	input.action_b_just_pressed.connect(on_b_pressed)
	input.action_c_just_pressed.connect(on_c_pressed)
	$SpecialAttributes/HurtManager.knockout.connect(on_knockout)

func activate():
	if get_node_or_null("CPU") == null:
		input.read_controller_input = true
	else:
		get_node_or_null("CPU").activate()
	active = true

func deactivate():
	if get_node_or_null("CPU") == null:
		input.read_controller_input = false
	else:
		get_node_or_null("CPU").deactivate()
	active = false
	
func _physics_process(_delta: float) -> void:
	
	if active:
	
		#Manage "shoving," aka moving opponent away if too close
		for _entity in shove_entities:
			var dir: int = -1 if _entity.global_position > global_position else 1
			move(Vector2.RIGHT * 40 * dir, _delta, false)
		
		#Clear input queue if no input has happened in a while
		if input_queue_time > 0.0:
			input_queue_time = move_toward(input_queue_time, 0.0, _delta)
			if input_queue_time == 0:
				inputs_queue.clear()
		
		#Clear out inputs from buffer after a certain time
		var _size = inputs_buffer.size()
		for i in range(_size):
			var _index = _size-1-i
			inputs_buffer_times[_index] = move_toward(inputs_buffer_times[_index], 0.0, _delta)
			if inputs_buffer_times[_index] == 0:
				inputs_buffer.remove_at(_index)
				inputs_buffer_times.remove_at(_index)
		
		#Get the "moving toward" value
		var _hor: float = input.input_direction.x
		moving_toward_opponent = 0
		if opponent.global_position.x > global_position.x:
			if _hor > 0:
				moving_toward_opponent = 1
			if _hor < 0:
				moving_toward_opponent = -1
		if opponent.global_position.x < global_position.x:
			if _hor > 0:
				moving_toward_opponent = -1
			if _hor < 0:
				moving_toward_opponent = 1
		
		#Restore jumps if grounded
		if is_on_floor():
			jumps = 2
	
	super._physics_process(_delta)
	
#Impact == when my attack hits an opponent
func on_impact(_hitbox_data: HitboxData):
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

#Get direction input to add to queue
func on_direction_input_code(_input_code: input_code):
	inputs_queue.append(_input_code)
	input_queue_time = 1.0 / 60 * float(input_queue_max_frames)
	inputs_buffer.append(_input_code)
	inputs_buffer_times.append(1.0 / 60 * float(input_buffer_max_frames))
	
func on_a_pressed():
	inputs_queue.append(input_code.A)
	inputs_buffer.append(input_code.A)
	inputs_buffer_times.append(1.0 / 60 * float(input_buffer_max_frames))
	input_queue_time = 1.0 / 60 * float(input_queue_max_frames)
	
func on_b_pressed():
	inputs_queue.append(input_code.B)
	inputs_buffer.append(input_code.B)
	inputs_buffer_times.append(1.0 / 60 * float(input_buffer_max_frames))
	input_queue_time = 1.0 / 60 * float(input_queue_max_frames)

func on_c_pressed():
	inputs_queue.append(input_code.C)
	inputs_buffer.append(input_code.C)
	inputs_buffer_times.append(1.0 / 60 * float(input_buffer_max_frames))
	input_queue_time = 1.0 / 60 * float(input_queue_max_frames)

func on_knockout():
	emit_signal("knockout", self)
