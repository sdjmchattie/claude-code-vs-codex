extends StaticBody2D
class_name PlayerController

@export var player_id: int = 0
@export var body_color: Color = Color("f4b860")

@onready var visual: Polygon2D = $Polygon2D
@onready var launch_point: Marker2D = $LaunchPoint

func _ready() -> void:
	visual.color = body_color

func get_launch_position() -> Vector2:
	return launch_point.global_position
