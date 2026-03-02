extends Node
class_name ExplosionSystem

enum HitResult {
	NO_HIT,
	HIT_PLAYER_A,
	HIT_PLAYER_B,
	SELF_HIT
}

func resolve_hit(
	impact_position: Vector2,
	shooter: PlayerController,
	players: Array[PlayerController],
	buildings: Array[Building],
	explosion_radius: float,
	crater_radius: float,
	effects_parent: Node
) -> HitResult:
	_spawn_explosion_visual(impact_position, explosion_radius, effects_parent)
	for building in buildings:
		if _building_near_impact(building, impact_position, crater_radius):
			building.apply_crater(impact_position, crater_radius)

	for player in players:
		if player.global_position.distance_to(impact_position) <= explosion_radius:
			if player == shooter:
				return HitResult.SELF_HIT
			if player.player_id == 0:
				return HitResult.HIT_PLAYER_A
			return HitResult.HIT_PLAYER_B
	return HitResult.NO_HIT

func _building_near_impact(building: Building, point: Vector2, radius: float) -> bool:
	var rect := Rect2(building.global_position, building.size)
	var nearest := Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)
	return nearest.distance_to(point) <= radius

func _spawn_explosion_visual(position: Vector2, radius: float, parent: Node) -> void:
	var visual := Node2D.new()
	visual.position = position
	var ring := Polygon2D.new()
	ring.color = Color(1.0, 0.75, 0.2, 0.55)
	ring.polygon = _make_circle_polygon(radius, 24)
	visual.add_child(ring)
	var inner := Polygon2D.new()
	inner.color = Color(1.0, 0.45, 0.1, 0.8)
	inner.polygon = _make_circle_polygon(radius * 0.6, 20)
	visual.add_child(inner)
	parent.add_child(visual)

	var tween := visual.create_tween()
	tween.tween_property(visual, "scale", Vector2(1.3, 1.3), 0.15)
	tween.parallel().tween_property(visual, "modulate:a", 0.0, 0.2)
	tween.finished.connect(visual.queue_free)

func _make_circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var arr: PackedVector2Array = PackedVector2Array()
	for i in points:
		var angle := TAU * (float(i) / float(points))
		arr.push_back(Vector2(cos(angle), sin(angle)) * radius)
	return arr
