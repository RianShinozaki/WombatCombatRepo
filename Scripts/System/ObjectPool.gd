class_name ObjectPool

extends Node

static var instance: ObjectPool

@export var object: PackedScene
@export var count: int

@export var inactive_objects: Array[int]
@export var active_objects: Array[int]

func _enter_tree() -> void:
	for i in range(count):
		var _object = object.instantiate()
		_object.get_node("ObjectPoolObject").object_pool = self
		_object.get_node("ObjectPoolObject").index = i
		add_child(_object)
		inactive_objects.append(i)

func spawn_object() -> Node:
	if inactive_objects.is_empty(): return null
	var object_index: int = inactive_objects[0]
	inactive_objects.erase(object_index)
	active_objects.append(object_index)
	var _object: Node = get_child(object_index)
	_object.get_node("ObjectPoolObject").spawn()
	return _object

func return_object_to_pool(_object: ObjectPoolObject):
	var object_index: int = _object.index
	active_objects.erase(object_index)
	inactive_objects.append(object_index)
