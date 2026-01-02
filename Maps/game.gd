class_name Game

extends Node2D

@export var fighter_1: Node2D
@export var fighter_2: Node2D
@onready var timer: Label = $UI/GameHUD/Timer

static var instance: Game

var game_time: float = 99
var game_active: bool = false

func _ready() -> void:
	instance = self
	
func game_start():
	fighter_1.get_node("Fighter").activate()
	fighter_2.get_node("Fighter").activate()
	fighter_1.get_node("Fighter").knockout.connect(on_knockout)
	fighter_2.get_node("Fighter").knockout.connect(on_knockout)
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
	fighter_1.get_node("Fighter").deactivate()
	fighter_2.get_node("Fighter").deactivate()
	Engine.time_scale = 0.5
	await get_tree().create_timer(1.2).timeout
	$AnimationPlayer.play("GAMESET")
	Engine.time_scale = 1
