extends ObjectPool

@export var fx_dict: Dictionary[String, SpriteFrames]

func spawn_fx(_fx_name: String) -> Node2D:
	if not fx_dict.has(_fx_name):
		push_warning("FX name %s doesn't exist" % [_fx_name])
		return null
	var _object: OneShotAnimatedFX = spawn_object()
	_object.initiate(fx_dict[_fx_name])
	return _object
