class_name InputManager

extends Node2D

@export var read_controller_input: bool
@export var player_prefix: String
@export var input_direction: Vector2
@export var input_direction_rounded: Vector2
@export var input_deadzone: float
@export var input_angle: float
@export var double_tap_max_time: float

var last_direction: Vector2
var last_direction_rounded: Vector2
var last_direction_nonzero: Vector2
var double_tap_timer: float
var last_input_angle: float
var last_input_was_zero: bool = false
var direction_just_pressed: bool = false

signal direction_input(input: Vector2)
signal direction_input_code(input_code: Fighter.input_code)

signal action_a_just_pressed
var action_a_pressed: bool
signal action_a_just_released

signal action_b_just_pressed
var action_b_pressed: bool
signal action_b_just_released

signal action_c_just_pressed
var action_c_pressed: bool
signal action_c_just_released

signal double_tap_direction(_direction: Vector2)

func _process(_delta: float) -> void:
	double_tap_timer = move_toward(double_tap_timer, double_tap_max_time, _delta)
	
	if read_controller_input:
		var _input_raw = Input.get_vector(player_prefix+"left", player_prefix+"right", player_prefix+"up", player_prefix+"down")
		input_direction = input_direction.move_toward(_input_raw, 0.5)
		input_direction_rounded = input_direction.round()
		#Ignore inputs below a certain magnitude
		direction_just_pressed = false
		if input_direction.length() < input_deadzone:
			input_direction = Vector2.ZERO
			last_input_was_zero = true
		else:
			if last_input_was_zero:
				direction_just_pressed = true
			last_input_was_zero = false
		
		if input_direction != Vector2.ZERO:
			var _angle: float = input_direction.angle()
			_angle = snapped(_angle, PI/4)
			_angle = wrap(_angle, 0, 2*PI)
			input_angle = _angle
			
			if double_tap_timer < double_tap_max_time and last_input_angle == input_angle and direction_just_pressed:
				emit_signal("double_tap_direction", Vector2.from_angle(input_angle))
				
			double_tap_timer = 0
			last_direction_nonzero = input_direction_rounded
			
			#Emit signal
			if last_input_angle != input_angle:
				emit_signal("direction_input", Vector2.from_angle(input_angle))
				var _input_code: Fighter.input_code = roundi(input_angle * (8/(2*PI))) as Fighter.input_code
				emit_signal("direction_input_code", _input_code)
			
		last_direction_rounded = input_direction_rounded
		last_input_angle = input_angle
		
		#I don't know a better way to do this
		if Input.is_action_just_pressed(player_prefix+"A"):
			emit_signal("action_a_just_pressed")
		if Input.is_action_just_released(player_prefix+"A"):
			emit_signal("action_a_just_released")
		action_a_pressed = Input.is_action_pressed(player_prefix+"A")

		if Input.is_action_just_pressed(player_prefix+"B"):
			emit_signal("action_b_just_pressed")
		if Input.is_action_just_released(player_prefix+"B"):
			emit_signal("action_b_just_released")
		action_b_pressed = Input.is_action_pressed(player_prefix+"B")
		
		if Input.is_action_just_pressed(player_prefix+"C"):
			emit_signal("action_c_just_pressed")
		if Input.is_action_just_released(player_prefix+"C"):
			emit_signal("action_c_just_released")
		action_c_pressed = Input.is_action_pressed(player_prefix+"C")

func set_input_direction(direction: Vector2):
	input_direction = direction

func press_button(_button: String):
	var _button_lower = _button.to_lower()
	emit_signal("action_" + _button_lower + "_just_pressed")

func get_input_x() -> float:
	if input_direction == Vector2.ZERO: return 0
	var _vec = Vector2.from_angle(input_angle).normalized()
	return snapped(_vec.x, 0.01)

func get_input_y() -> float:
	if input_direction == Vector2.ZERO: return 0
	var _vec = Vector2.from_angle(input_angle).normalized()
	return snapped(_vec.y, 0.01)
