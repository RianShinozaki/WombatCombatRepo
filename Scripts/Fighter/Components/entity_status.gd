class_name EntityStatus

extends Node2D

@export var max_health: float
var health: float

@export var max_knockdown: float
var knockdown: float

func _ready() -> void:
	health = max_health
	knockdown = 0.0
