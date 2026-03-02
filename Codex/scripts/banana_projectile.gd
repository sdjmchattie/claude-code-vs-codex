extends RigidBody2D
class_name BananaProjectile

signal projectile_impacted(position: Vector2, hit_target: Variant)

@export var wind_force: float = 0.0

var _impacted: bool = false

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

func launch(initial_velocity: Vector2, gravity_scale_value: float) -> void:
	linear_velocity = initial_velocity
	gravity_scale = gravity_scale_value

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _impacted:
		return
	state.apply_central_force(Vector2(wind_force * mass, 0.0))

func _physics_process(_delta: float) -> void:
	if _impacted:
		return
	var viewport_rect: Rect2 = get_viewport_rect().grow(180.0)
	if not viewport_rect.has_point(global_position):
		_emit_impact(null)

func _on_body_entered(body: Node) -> void:
	_emit_impact(body)

func _emit_impact(hit_target: Variant) -> void:
	if _impacted:
		return
	_impacted = true
	freeze = true
	projectile_impacted.emit(global_position, hit_target)
	queue_free()
