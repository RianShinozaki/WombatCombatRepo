class_name CPUController

extends Node

var active: bool = false
var opponent: Fighter
@onready var entity: Fighter = $".."
@onready var input: InputManager = $"../GenericAttributes/InputManager"

func activate():
	active = true
	opponent = Game.instance.fighter_1.get_node("Fighter")
	
func deactivate():
	active = false
