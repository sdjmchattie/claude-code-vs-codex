extends CanvasLayer
class_name HUD

signal throw_submitted(angle_deg: float, speed: float)
signal restart_requested

@onready var active_player_label: Label = %ActivePlayerLabel
@onready var score_label: Label = %ScoreLabel
@onready var wind_label: Label = %WindLabel
@onready var wind_arrow_label: Label = %WindArrowLabel
@onready var message_label: Label = %MessageLabel
@onready var angle_input: LineEdit = %AngleInput
@onready var speed_input: LineEdit = %SpeedInput
@onready var launch_button: Button = %LaunchButton
@onready var restart_button: Button = %RestartButton

func _ready() -> void:
	launch_button.pressed.connect(_on_launch_pressed)
	restart_button.pressed.connect(func() -> void: restart_requested.emit())

func set_turn_state(player_id: int, wind: float, can_launch: bool) -> void:
	active_player_label.text = "Player %d Turn" % [player_id + 1]
	wind_label.text = "Wind: %+.1f" % wind
	wind_arrow_label.text = _wind_arrow(wind)
	set_input_enabled(can_launch)
	if can_launch:
		message_label.text = "Enter angle and velocity."

func set_scores(scores: Array[int], points_to_win: int) -> void:
	score_label.text = "P1 %d  -  P2 %d  (first to %d)" % [scores[0], scores[1], points_to_win]

func set_message(message: String) -> void:
	message_label.text = message

func set_input_enabled(enabled: bool) -> void:
	angle_input.editable = enabled
	speed_input.editable = enabled
	launch_button.disabled = not enabled

func set_match_over(winner_id: int) -> void:
	set_input_enabled(false)
	message_label.text = "Player %d wins the match." % [winner_id + 1]
	restart_button.visible = true

func reset_for_match() -> void:
	restart_button.visible = false
	angle_input.text = "45"
	speed_input.text = "520"

func _on_launch_pressed() -> void:
	var angle := angle_input.text.to_float()
	var speed := speed_input.text.to_float()
	throw_submitted.emit(angle, speed)

func _wind_arrow(wind: float) -> String:
	if absf(wind) < 1.0:
		return "Wind: ->"
	if wind > 0.0:
		return "Wind: -> ->"
	return "Wind: <- <-"
