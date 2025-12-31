class_name DodgeState

extends ActionState

var inp: InputManager
var anim: AnimationTree

var mov_param: EntityMovementParameters
var jmp_param: EntityJumpParameters
var hurt_param: PlayerHurtParameters

var counter: float = 0
var animation_duration: float

func _ready() -> void:
	super._ready()
	inp = entity.get_node("GenericAttributes/InputManager")
	anim = entity.get_node("Art/AnimationTree")
	mov_param = entity.parameters["movement"]
	jmp_param = entity.parameters["jump"]
	hurt_param = entity.parameters["hurt"]
	$"../../Art/AnimationTree".animation_finished.connect(on_animation_finished)
	
func _start() -> void:
	super._start()
	entity.get_node("EnvironmentBox").set_deferred("shape", mov_param.collision_shape) 
	entity.get_node("EnvironmentBox").position = mov_param.collision_shape_position
	counter = 0
	
func _physics_process(delta: float) -> void:
	if !active: return
	if !entity.apply_physics: return


func on_animation_finished(_anim: StringName):
	if not active: return
	
	entity.switch_action_state_name("NormalState")
	anim.get("parameters/AnimationNodeStateMachine/playback").start("Grounded", true)
