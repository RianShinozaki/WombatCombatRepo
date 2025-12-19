class_name EntityStatus

extends Node2D

@export var max_health: float
var health: float

func _ready() -> void:
	health = max_health
