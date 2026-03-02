extends Node
class_name WindSystem

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func next_wind(min_value: float, max_value: float) -> float:
	return _rng.randf_range(min_value, max_value)
