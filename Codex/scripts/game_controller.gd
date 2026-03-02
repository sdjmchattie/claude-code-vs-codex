extends Node2D

const BuildingScene = preload("res://scenes/Building.tscn")
const PlayerScene = preload("res://scenes/Player.tscn")
const BananaScene = preload("res://scenes/BananaProjectile.tscn")

enum TurnPhase {
	ROUND_SETUP,
	TURN_INPUT,
	PROJECTILE_IN_FLIGHT,
	RESOLUTION,
	MATCH_END
}

@export var config: MatchConfig
@export var ground_y: float = 640.0

@onready var skyline_container: Node2D = %SkylineContainer
@onready var actors_container: Node2D = %ActorsContainer
@onready var projectile_layer: Node2D = %ProjectileLayer
@onready var effects_layer: Node2D = %EffectsLayer
@onready var hud: HUD = %HUD
@onready var wind_system: WindSystem = %WindSystem
@onready var skyline_provider: FixedSkylineProvider = %FixedSkylineProvider
@onready var explosion_system: ExplosionSystem = %ExplosionSystem

var _phase: TurnPhase = TurnPhase.ROUND_SETUP
var _scores: Array[int] = [0, 0]
var _active_player_id: int = 0
var _current_wind: float = 0.0
var _players: Array[PlayerController] = []
var _buildings: Array[Building] = []
var _active_shooter: PlayerController

func _ready() -> void:
	if config == null:
		config = MatchConfig.new()
	hud.throw_submitted.connect(_on_throw_submitted)
	hud.restart_requested.connect(_start_new_match)
	hud.reset_for_match()
	_start_new_match()

func _start_new_match() -> void:
	_scores = [0, 0]
	_active_player_id = 0
	hud.set_scores(_scores, config.points_to_win)
	hud.reset_for_match()
	_setup_round()
	_start_turn()

func _setup_round() -> void:
	_phase = TurnPhase.ROUND_SETUP
	_clear_children(projectile_layer)
	_clear_children(effects_layer)
	_clear_children(skyline_container)
	_clear_children(actors_container)
	_buildings.clear()
	_players.clear()

	var view_size: Vector2 = get_viewport_rect().size
	var specs := skyline_provider.generate_specs(view_size, ground_y)
	for spec in specs:
		var building: Building = BuildingScene.instantiate()
		building.position = spec["position"]
		building.configure(spec["size"], spec["color"])
		skyline_container.add_child(building)
		_buildings.append(building)

	if _buildings.size() < 2:
		push_error("Need at least two buildings to place players.")
		return

	var spawn_pair := _pick_spawn_buildings(view_size.x)
	_spawn_player(0, spawn_pair[0])
	_spawn_player(1, spawn_pair[1])

func _spawn_player(player_id: int, building: Building) -> void:
	var player: PlayerController = PlayerScene.instantiate()
	player.player_id = player_id
	player.body_color = Color("f5bd62") if player_id == 0 else Color("7adf8a")
	var center_x: float = building.position.x + (building.size.x * 0.5)
	var rooftop_y: float = building.position.y
	player.position = Vector2(center_x, rooftop_y - 26.0)
	actors_container.add_child(player)
	_players.append(player)

func _start_turn() -> void:
	if _phase == TurnPhase.MATCH_END:
		return
	_phase = TurnPhase.TURN_INPUT
	_current_wind = wind_system.next_wind(config.wind_min, config.wind_max)
	hud.set_turn_state(_active_player_id, _current_wind, true)
	hud.set_scores(_scores, config.points_to_win)

func _on_throw_submitted(angle_deg: float, speed: float) -> void:
	if _phase != TurnPhase.TURN_INPUT:
		return
	if angle_deg < config.min_angle_deg or angle_deg > config.max_angle_deg:
		hud.set_message("Angle must be between %.0f and %.0f." % [config.min_angle_deg, config.max_angle_deg])
		return
	if speed < config.min_speed or speed > config.max_speed:
		hud.set_message("Velocity must be between %.0f and %.0f." % [config.min_speed, config.max_speed])
		return

	_active_shooter = _get_player_by_id(_active_player_id)
	if _active_shooter == null:
		return

	_phase = TurnPhase.PROJECTILE_IN_FLIGHT
	hud.set_input_enabled(false)
	hud.set_message("Banana in flight...")
	_launch_projectile(_active_shooter, angle_deg, speed)

func _launch_projectile(shooter: PlayerController, angle_deg: float, speed: float) -> void:
	var projectile: BananaProjectile = BananaScene.instantiate()
	projectile.position = shooter.get_launch_position()
	projectile.wind_force = _current_wind
	projectile.projectile_impacted.connect(_on_projectile_impacted)
	projectile_layer.add_child(projectile)

	var angle_rad := deg_to_rad(angle_deg)
	var direction := 1.0 if shooter.player_id == 0 else -1.0
	var velocity := Vector2(cos(angle_rad) * speed * direction, -sin(angle_rad) * speed)
	projectile.launch(velocity, config.gravity_scale)

func _on_projectile_impacted(impact_position: Vector2, _hit_target: Variant) -> void:
	if _phase != TurnPhase.PROJECTILE_IN_FLIGHT:
		return
	_phase = TurnPhase.RESOLUTION

	var result: ExplosionSystem.HitResult = explosion_system.resolve_hit(
		impact_position,
		_active_shooter,
		_players,
		_buildings,
		config.explosion_radius,
		config.crater_radius,
		effects_layer
	)
	_apply_hit_result(result)

func _apply_hit_result(result: ExplosionSystem.HitResult) -> void:
	match result:
		ExplosionSystem.HitResult.HIT_PLAYER_A:
			_scores[1] += 1
			hud.set_message("Player 2 scores.")
		ExplosionSystem.HitResult.HIT_PLAYER_B:
			_scores[0] += 1
			hud.set_message("Player 1 scores.")
		ExplosionSystem.HitResult.SELF_HIT:
			var winner := 1 - _active_player_id
			_scores[winner] += 1
			hud.set_message("Self-hit. Player %d scores." % [winner + 1])
		_:
			hud.set_message("Miss.")

	hud.set_scores(_scores, config.points_to_win)
	if _scores[0] >= config.points_to_win:
		_phase = TurnPhase.MATCH_END
		hud.set_match_over(0)
		return
	if _scores[1] >= config.points_to_win:
		_phase = TurnPhase.MATCH_END
		hud.set_match_over(1)
		return

	_active_player_id = 1 - _active_player_id
	_start_turn()

func _get_player_by_id(player_id: int) -> PlayerController:
	for player in _players:
		if player.player_id == player_id:
			return player
	return null

func _pick_spawn_buildings(viewport_width: float) -> Array[Building]:
	var visible: Array[Building] = []
	for building in _buildings:
		var center_x: float = building.position.x + (building.size.x * 0.5)
		if center_x >= 0.0 and center_x <= viewport_width:
			visible.append(building)

	if visible.size() < 2:
		return [_buildings[0], _buildings[_buildings.size() - 1]]

	var left_target: float = viewport_width * 0.2
	var right_target: float = viewport_width * 0.8
	var left_choice: Building = visible[0]
	var right_choice: Building = visible[visible.size() - 1]
	var left_best: float = INF
	var right_best: float = INF

	for building in visible:
		var center_x: float = building.position.x + (building.size.x * 0.5)
		var left_distance: float = absf(center_x - left_target)
		if left_distance < left_best:
			left_best = left_distance
			left_choice = building
		var right_distance: float = absf(center_x - right_target)
		if right_distance < right_best:
			right_best = right_distance
			right_choice = building

	if left_choice == right_choice:
		var left_index: int = visible.find(left_choice)
		var alt_index: int = clampi(left_index + 1, 0, visible.size() - 1)
		right_choice = visible[alt_index]
		if right_choice == left_choice:
			alt_index = clampi(left_index - 1, 0, visible.size() - 1)
			right_choice = visible[alt_index]

	return [left_choice, right_choice]

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
