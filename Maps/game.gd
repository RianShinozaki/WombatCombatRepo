class_name Game

extends Node2D

@export var fighter_1: Fighter
@export var fighter_2: Fighter
@onready var timer: Label = $UI/GameHUD/Timer

var game_time: float = 99
var game_active: bool = false

func game_start():
	fighter_1.activate()
	fighter_2.activate()
	fighter_1.knockout.connect(on_knockout)
	fighter_2.knockout.connect(on_knockout)
	game_active = true
	
func _process(delta: float) -> void:
	if not game_active: return
	game_time -= delta
	if game_time <= 0:
		timer.text = "0"
		on_knockout(null)
		return
	
	timer.text = str(roundi(game_time))

func on_knockout(_fighter_kod: Fighter):
	game_active = false
	fighter_1.deactivate()
	fighter_2.deactivate()
	Engine.time_scale = 0.5
	await get_tree().create_timer(1.2).timeout
	$AnimationPlayer.play("GAMESET")
	Engine.time_scale = 1
