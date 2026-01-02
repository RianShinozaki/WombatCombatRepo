class_name ShikuCPU1

extends CPUController

enum state {NEUTRAL, DEFEND, ATTACK}

var current_state: state = state.NEUTRAL

@export var difficulty_level: float


@export var aggression_baseline: float
@export var difficulty_aggression_factor: float
# "factor" means "how much is this thing affected by aggression"
#Neutral state
@export var neutral_footsie_time_base: float
@export var neutral_footsie_time_delta_factor: float
@export var neutral_footsie_time_variance_base: float
@export var neutral_footsie_time_variance_factor: float
@export var footsie_distance_base: float
@export var footsie_distance_delta_factor: float
@export var neutral_state_max_time: float = 0

var neutral_footsie_timer: float = 0
var neutral_footsie_direction: int = 0
var neutral_footsie_timer_max: float
var current_aggression: float = 0

#Attack state
@export var attack_state_max_time: float = 0

var state_timer: float = 0

func _physics_process(_delta: float) -> void:
	if not active: return
	
	match current_state:
		state.NEUTRAL:
			var _distance_to_opponent: float = entity.global_position.x - opponent.global_position.x
			current_aggression = clamp(10-abs(_distance_to_opponent)*0.05, 0, 1) + aggression_baseline + difficulty_aggression_factor * difficulty_level
			footsie(_delta)
			state_timer += _delta * current_aggression
			if state_timer > neutral_state_max_time:
				current_state = state.ATTACK
				state_timer = 0
				
		state.ATTACK:
			var _distance_to_opponent: float = entity.global_position.x - opponent.global_position.x
			var _dir_to_opponent: int = sign(_distance_to_opponent)
			input.set_input_direction(Vector2.RIGHT * -_dir_to_opponent)
			if abs(_distance_to_opponent) > 64 and entity.is_on_floor():
				input.press_button("a")
			if abs(_distance_to_opponent) < 20:
				var _choice: int = randi_range(0, 2)
				if _choice == 0:
					input.press_button("c")
				else:
					input.press_button("b")
			
			state_timer += _delta
			if state_timer > attack_state_max_time:
				current_state = state.NEUTRAL
				state_timer = 0

func footsie(_delta: float):
	if entity.current_action_state.name != "NormalState": return
	neutral_footsie_timer += _delta
			
	#Make a decision when footsie timer is up
	if neutral_footsie_timer > neutral_footsie_timer_max:
		if neutral_footsie_direction == 0:
			var _distance_to_opponent: float = entity.global_position.x - opponent.global_position.x
			var _dir_to_opponent: int = sign(_distance_to_opponent)
			#move away if too close
			var _too_close_distance = footsie_distance_base - footsie_distance_delta_factor * current_aggression
			var _too_far_distance = footsie_distance_base + footsie_distance_delta_factor * current_aggression
			if abs(_distance_to_opponent) < _too_close_distance:
				input.set_input_direction(Vector2.RIGHT * _dir_to_opponent)
			elif abs(_distance_to_opponent) > _too_far_distance:
				input.set_input_direction(Vector2.RIGHT * -_dir_to_opponent)
			else:
				var _rand = randi_range(0, 1)
				input.set_input_direction(Vector2.RIGHT * (-1 if _rand == 0 else 1))
				
			neutral_footsie_direction = 1
		else:
			neutral_footsie_direction = 0
			input.set_input_direction(Vector2.ZERO)
		
		#Reset footsie counter and set new max
		neutral_footsie_timer = 0
		var _footsie_variance: float = neutral_footsie_time_variance_factor * current_aggression * randf_range(-neutral_footsie_time_variance_base, neutral_footsie_time_variance_base)
		neutral_footsie_timer_max = neutral_footsie_time_base + current_aggression * neutral_footsie_time_delta_factor + _footsie_variance
