class_name InputManager

extends Node2D

@export var read_controller_input: bool
@export var player_prefix: String
@export var input_direction: Vector2
@export var input_deadzone: float
@export var double_tap_max_time: float

var last_direction: Vector2
var last_direction_nonzero: Vector2
var double_tap_timer: float

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
		input_direction = Input.get_vector(player_prefix+"left", player_prefix+"right", player_prefix+"up", player_prefix+"down")
		
		#Ignore inputs below a certain magnitude
		if input_direction.length() < input_deadzone:
			input_direction = Vector2.ZERO
		
		#Check for a double tap
		if input_direction != Vector2.ZERO and last_direction == Vector2.ZERO:
			var _this_direction = Vector2(input_direction.round())
			if double_tap_timer < double_tap_max_time and _this_direction == last_direction_nonzero:
				emit_signal("double_tap_direction", _this_direction)
				
			double_tap_timer = 0
			last_direction_nonzero = _this_direction
			
		last_direction = input_direction
		
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
