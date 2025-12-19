class_name EntityMovementParameters extends ParameterSet

##Auta's base top speed while running
@export var max_speed: float
##The speed Auta starts running at from a standstill
@export var initial_speed: float			
##The speed Auta starts running at from a standstill in the air
@export var initial_speed_in_air: float
##The speed where Auta stops completely when slowing down
@export var minimum_speed: float			
##The speed where Auta stops completely when slowing down in the air
@export var minimum_speed_in_air: float
##Auta's base acceleration
@export var acceleration: float
##Auta's base acceleration in air
@export var acceleration_in_air: float
##Auta's base deceleration
@export var deceleration: float
##Auta's base deceleration in air
@export var deceleration_in_air: float
##How quickly Auta returns to max speed if running ABOVE max speed
@export var deceleration_above_speed: float
##How quickly Auta returns to max speed if running ABOVE max speed in air
@export var deceleration_above_speed_in_air: float
@export var reverse_acceleration: float
@export var reverse_acceleration_in_air: float
@export var absolute_limit: float
@export var slope_uphill_influence: float
@export var slope_downhill_influence: float
@export var collision_shape: Shape2D
@export var collision_shape_position: Vector2

func get_max_speed() -> float:
	return max_speed
	
func get_acceleration(_entity: CollisionEntity) -> float:
	if abs(_entity.velocity.x) > max_speed:
		return deceleration_above_speed if _entity.is_on_floor() else deceleration_above_speed_in_air
	else: return acceleration if _entity.is_on_floor() else acceleration_in_air
	
func get_deceleration(_entity: CollisionEntity) -> float:
	return deceleration if _entity.is_on_floor() else deceleration_in_air
	
func get_initial_speed(_entity: CollisionEntity) -> float:
	return initial_speed if _entity.is_on_floor() else initial_speed_in_air
	
func get_minimum_speed(_entity: CollisionEntity) -> float:
	return minimum_speed if _entity.is_on_floor() else minimum_speed_in_air

func get_deceleration_above_speed(_entity: CollisionEntity) -> float:
	return deceleration_above_speed if _entity.is_on_floor() else deceleration_above_speed_in_air

func get_reverse_acceleration(_entity: CollisionEntity) -> float:
	return reverse_acceleration if _entity.is_on_floor() else reverse_acceleration_in_air
