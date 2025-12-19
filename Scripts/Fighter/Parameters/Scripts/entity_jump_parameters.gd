class_name EntityJumpParameters extends ParameterSet

##Base vertical speed when jumping
@export var jump_power: float
##Base gravity
@export var gravity: float
##Gravity scale at the peak of the jump
@export var normal_gravity_scale: float
##Gravity scale when jump is released while rising
@export var short_hop_gravity_scale: float
##Gravity scale when rising
@export var rising_gravity_scale: float
##Gravity scale when falling
@export var falling_gravity_scale: float
##The minimum vertical speed to be considered rising
@export var rising_threshold: float
##The minimum vertical speed to be considered falling
@export var falling_threshold: float
##The maximum falling speed
@export var max_falling_speed: float
@export var mult: float = 1

func get_jump_power() -> float:
	return jump_power
	
func get_gravity(_entity: CollisionEntity, _mult: float = 1) -> float:
	var _y = _entity.velocity.y
	if(_entity.is_on_floor()):
		return gravity * _mult
	elif(_y < rising_threshold):
		return gravity * rising_gravity_scale * _mult
	elif(rising_threshold < _y && _y < falling_threshold):
		return gravity * normal_gravity_scale * _mult
	return gravity * falling_gravity_scale * _mult
