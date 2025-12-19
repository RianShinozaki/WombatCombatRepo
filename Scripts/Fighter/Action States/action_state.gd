class_name ActionState

extends Node2D

signal state_begun()
signal state_ended()

@export var active: bool
@export var auto_hook: bool = true

var entity: CollisionEntity

func _ready() -> void:
	if auto_hook: entity = get_parent().get_parent()
	
func _start() -> void:
	active = true
	emit_signal("state_begun")	

func _process(_delta: float) -> void:
	pass

func _end() -> void:
	active = false
	emit_signal("state_ended")
