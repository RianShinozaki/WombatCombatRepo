class_name ObjectPoolObject

extends Node

var object_pool: ObjectPool
var index: int

func spawn():
	get_parent().on_spawn()

func despawn():
	if is_instance_valid(object_pool):
		object_pool.return_object_to_pool(self)
	else:
		queue_free()
