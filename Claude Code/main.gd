extends Node2D

# === Constants ===
const SCREEN_W := 640
const SCREEN_H := 480
const GRAVITY := 9.8
const EXPLOSION_RADIUS := 30
const GORILLA_SIZE := 20
const GORILLA_HIT_DIST := 18.0
const BANANA_SIZE := 6
const MIN_BUILDING_W := 30
const MAX_BUILDING_W := 50
const MIN_BUILDING_H := 80
const MAX_BUILDING_H := 280
const WINDOW_W := 4
const WINDOW_H := 6
const WINDOW_GAP_X := 8
const WINDOW_GAP_Y := 12
const PROJECTILE_SPEED := 1.5  # time multiplier for speed feel

const BUILDING_COLORS: Array[Color] = [
	Color(0.55, 0.15, 0.15),  # dark red
	Color(0.15, 0.45, 0.45),  # teal
	Color(0.4, 0.4, 0.4),     # gray
	Color(0.5, 0.3, 0.15),    # brown
	Color(0.3, 0.2, 0.5),     # purple
]

# === State ===
var city_image: Image
var city_texture: ImageTexture
var current_player := 1
var scores := [0, 0]
var wind := 0.0
var banana_active := false
var banana_t := 0.0
var banana_x0 := 0.0
var banana_y0 := 0.0
var banana_vx := 0.0
var banana_vy := 0.0
var gorilla1_pos := Vector2.ZERO
var gorilla2_pos := Vector2.ZERO
var explosion_timer := 0.0
var explosion_center := Vector2.ZERO
var showing_message := false
var message_timer := 0.0
var round_over := false
var building_tops: Array[float] = []  # y position of each building top
var building_xs: Array[float] = []    # x position of each building left edge
var building_ws: Array[float] = []    # width of each building
var gorilla_texture: ImageTexture
var banana_texture: ImageTexture
var flash_texture: ImageTexture
var flash_timer := 0.0

# === Node references ===
@onready var city_sprite: Sprite2D = $CitySprite
@onready var gorilla1_sprite: Sprite2D = $Gorilla1
@onready var gorilla2_sprite: Sprite2D = $Gorilla2
@onready var banana_sprite: Sprite2D = $Banana
@onready var wind_label: Label = $UILayer/WindLabel
@onready var turn_label: Label = $UILayer/TurnLabel
@onready var score_label: Label = $UILayer/ScoreLabel
@onready var angle_input: LineEdit = $UILayer/AngleInput
@onready var velocity_input: LineEdit = $UILayer/VelocityInput
@onready var fire_button: Button = $UILayer/FireButton
@onready var message_label: Label = $UILayer/MessageLabel


func _ready() -> void:
	randomize()
	gorilla_texture = create_gorilla_texture()
	banana_texture = create_banana_texture()
	fire_button.pressed.connect(_on_fire_pressed)
	angle_input.text_submitted.connect(func(_t: String) -> void: _on_fire_pressed())
	velocity_input.text_submitted.connect(func(_t: String) -> void: _on_fire_pressed())
	new_round()


func _process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		queue_redraw()

	if showing_message:
		message_timer -= delta
		if message_timer <= 0.0:
			showing_message = false
			message_label.text = ""
			if round_over:
				new_round()
		return

	if banana_active:
		update_banana(delta)


func _draw() -> void:
	# Draw explosion flash
	if flash_timer > 0.0:
		var alpha := flash_timer / 0.15
		draw_circle(explosion_center, EXPLOSION_RADIUS + 5, Color(1, 1, 0.5, alpha * 0.8))


# === City Generation ===

func generate_city() -> void:
	city_image = Image.create(SCREEN_W, SCREEN_H, false, Image.FORMAT_RGBA8)
	city_image.fill(Color(0, 0, 0, 0))
	building_tops.clear()
	building_xs.clear()
	building_ws.clear()

	var x := 0
	while x < SCREEN_W:
		var w := randi_range(MIN_BUILDING_W, MAX_BUILDING_W)
		if x + w > SCREEN_W:
			w = SCREEN_W - x
		var h := randi_range(MIN_BUILDING_H, MAX_BUILDING_H)
		var top := SCREEN_H - h
		var color: Color = BUILDING_COLORS[randi() % BUILDING_COLORS.size()]

		# Draw building body
		var building_rect := Rect2i(x, top, w, h)
		city_image.fill_rect(building_rect, color)

		# Draw windows
		var win_lit := Color(1, 1, 0.6)
		var win_dark := Color(0.15, 0.15, 0.1)
		var wy := top + 4
		while wy + WINDOW_H < SCREEN_H:
			var wx := x + 3
			while wx + WINDOW_W < x + w - 2:
				var wc: Color = win_lit if randf() > 0.35 else win_dark
				city_image.fill_rect(Rect2i(wx, wy, WINDOW_W, WINDOW_H), wc)
				wx += WINDOW_GAP_X
			wy += WINDOW_GAP_Y

		building_tops.append(float(top))
		building_xs.append(float(x))
		building_ws.append(float(w))
		x += w

	city_texture = ImageTexture.create_from_image(city_image)
	city_sprite.texture = city_texture


# === Gorilla Texture ===

func create_gorilla_texture() -> ImageTexture:
	var img := Image.create(GORILLA_SIZE, GORILLA_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var brown := Color(0.55, 0.3, 0.1)
	var face := Color(0.8, 0.6, 0.35)
	var dark := Color(0.3, 0.15, 0.05)

	# Body (center mass)
	img.fill_rect(Rect2i(6, 4, 8, 10), brown)
	# Head
	img.fill_rect(Rect2i(7, 1, 6, 5), brown)
	# Face
	img.fill_rect(Rect2i(8, 2, 4, 3), face)
	# Eyes
	img.set_pixel(9, 2, dark)
	img.set_pixel(11, 2, dark)
	# Mouth
	img.set_pixel(9, 4, dark)
	img.set_pixel(10, 4, dark)
	# Arms
	img.fill_rect(Rect2i(3, 5, 3, 6), brown)
	img.fill_rect(Rect2i(14, 5, 3, 6), brown)
	# Legs
	img.fill_rect(Rect2i(7, 14, 3, 4), brown)
	img.fill_rect(Rect2i(11, 14, 3, 4), brown)
	# Feet
	img.fill_rect(Rect2i(6, 17, 4, 2), dark)
	img.fill_rect(Rect2i(10, 17, 4, 2), dark)
	# Chest
	img.fill_rect(Rect2i(8, 7, 4, 3), face)

	return ImageTexture.create_from_image(img)


# === Banana Texture ===

func create_banana_texture() -> ImageTexture:
	var img := Image.create(BANANA_SIZE, BANANA_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var yellow := Color(1, 1, 0)
	# Simple cross shape for banana
	img.fill_rect(Rect2i(1, 2, 4, 2), yellow)
	img.fill_rect(Rect2i(2, 1, 2, 4), yellow)
	return ImageTexture.create_from_image(img)


# === Gorilla Placement ===

func place_gorillas() -> void:
	# Player 1: left third of buildings
	var left_count := int(building_tops.size() / 3.0)
	left_count = max(left_count, 1)
	var b1 := randi_range(1, left_count)
	var g1x := building_xs[b1] + building_ws[b1] / 2.0 - GORILLA_SIZE / 2.0
	var g1y := building_tops[b1] - GORILLA_SIZE
	gorilla1_pos = Vector2(g1x + GORILLA_SIZE / 2.0, g1y + GORILLA_SIZE / 2.0)
	gorilla1_sprite.texture = gorilla_texture
	gorilla1_sprite.position = Vector2(g1x, g1y)

	# Player 2: right third of buildings
	var right_start := int(building_tops.size() * 2.0 / 3.0)
	right_start = min(right_start, building_tops.size() - 2)
	var b2 := randi_range(right_start, building_tops.size() - 1)
	var g2x := building_xs[b2] + building_ws[b2] / 2.0 - GORILLA_SIZE / 2.0
	var g2y := building_tops[b2] - GORILLA_SIZE
	gorilla2_pos = Vector2(g2x + GORILLA_SIZE / 2.0, g2y + GORILLA_SIZE / 2.0)
	gorilla2_sprite.texture = gorilla_texture
	gorilla2_sprite.position = Vector2(g2x, g2y)


# === Wind ===

func randomize_wind() -> void:
	wind = randf_range(-5.0, 5.0)
	var arrows := ""
	var strength := int(abs(wind) * 2)
	if wind < -0.3:
		for i in range(strength):
			arrows += "<"
		wind_label.text = "Wind: " + arrows
	elif wind > 0.3:
		for i in range(strength):
			arrows += ">"
		wind_label.text = "Wind: " + arrows
	else:
		wind_label.text = "Wind: ---"


# === New Round ===

func new_round() -> void:
	round_over = false
	banana_active = false
	banana_sprite.visible = false
	message_label.text = ""
	showing_message = false
	current_player = 1

	generate_city()
	place_gorillas()
	randomize_wind()
	update_ui()
	enable_input(true)


# === UI ===

func update_ui() -> void:
	turn_label.text = "PLAYER " + str(current_player)
	score_label.text = "Player 1: " + str(scores[0]) + "  Player 2: " + str(scores[1])


func enable_input(on: bool) -> void:
	angle_input.editable = on
	velocity_input.editable = on
	fire_button.disabled = !on
	if on:
		angle_input.grab_focus()


func show_message(text: String, duration: float) -> void:
	message_label.text = text
	showing_message = true
	message_timer = duration


# === Firing ===

func _on_fire_pressed() -> void:
	if banana_active or showing_message or round_over:
		return

	var angle_text := angle_input.text.strip_edges()
	var vel_text := velocity_input.text.strip_edges()

	if !angle_text.is_valid_float() or !vel_text.is_valid_float():
		show_message("Enter valid numbers!", 1.0)
		return

	var angle_deg := clampf(float(angle_text), 0, 360)
	var velocity := clampf(float(vel_text), 0, 200)

	var angle_rad: float
	if current_player == 1:
		# Player 1 fires to the right; angle measured from horizontal
		angle_rad = deg_to_rad(angle_deg)
		banana_x0 = gorilla1_pos.x + GORILLA_SIZE / 2.0
		banana_y0 = gorilla1_pos.y - GORILLA_SIZE / 2.0
		banana_vx = cos(angle_rad) * velocity
		banana_vy = -sin(angle_rad) * velocity  # negative = upward in screen coords
	else:
		# Player 2 fires to the left; mirror the angle
		angle_rad = deg_to_rad(angle_deg)
		banana_x0 = gorilla2_pos.x - GORILLA_SIZE / 2.0
		banana_y0 = gorilla2_pos.y - GORILLA_SIZE / 2.0
		banana_vx = -cos(angle_rad) * velocity
		banana_vy = -sin(angle_rad) * velocity

	banana_t = 0.0
	banana_active = true
	banana_sprite.visible = true
	banana_sprite.texture = banana_texture
	enable_input(false)


# === Projectile Update ===

func update_banana(delta: float) -> void:
	var dt := delta * PROJECTILE_SPEED
	var steps := 3  # substeps for interpolation to prevent tunneling
	var sub_dt := dt / float(steps)

	for _i in range(steps):
		banana_t += sub_dt
		var bx := banana_x0 + banana_vx * banana_t + 0.5 * wind * banana_t * banana_t
		var by := banana_y0 + banana_vy * banana_t + 0.5 * GRAVITY * banana_t * banana_t

		banana_sprite.position = Vector2(bx - BANANA_SIZE / 2.0, by - BANANA_SIZE / 2.0)
		banana_sprite.rotation += delta * 10.0  # spin

		# Check out of bounds
		if bx < -50 or bx > SCREEN_W + 50 or by > SCREEN_H + 50:
			banana_miss()
			return

		# Check gorilla hit (opponent only)
		var target_pos: Vector2
		if current_player == 1:
			target_pos = gorilla2_pos
		else:
			target_pos = gorilla1_pos

		if Vector2(bx, by).distance_to(target_pos) < GORILLA_HIT_DIST:
			banana_hit_gorilla(Vector2(bx, by))
			return

		# Check terrain hit (pixel alpha)
		var px := int(bx)
		var py := int(by)
		if px >= 0 and px < SCREEN_W and py >= 0 and py < SCREEN_H:
			var pixel := city_image.get_pixel(px, py)
			if pixel.a > 0.5:
				banana_hit_terrain(Vector2(bx, by))
				return


func banana_miss() -> void:
	banana_active = false
	banana_sprite.visible = false
	switch_turn()


func banana_hit_terrain(pos: Vector2) -> void:
	banana_active = false
	banana_sprite.visible = false
	carve_terrain(pos, EXPLOSION_RADIUS)
	explosion_center = pos
	flash_timer = 0.15
	queue_redraw()
	switch_turn()


func banana_hit_gorilla(pos: Vector2) -> void:
	banana_active = false
	banana_sprite.visible = false
	carve_terrain(pos, EXPLOSION_RADIUS)
	explosion_center = pos
	flash_timer = 0.15
	queue_redraw()

	var winner := current_player
	scores[winner - 1] += 1
	update_ui()
	round_over = true

	# Hide the hit gorilla
	if current_player == 1:
		gorilla2_sprite.visible = false
	else:
		gorilla1_sprite.visible = false

	show_message("PLAYER " + str(winner) + " WINS!", 2.5)


func switch_turn() -> void:
	current_player = 2 if current_player == 1 else 1
	update_ui()
	enable_input(true)


# === Terrain Destruction ===

func carve_terrain(center: Vector2, radius: int) -> void:
	var cx := int(center.x)
	var cy := int(center.y)
	var transparent := Color(0, 0, 0, 0)

	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				var px := cx + dx
				var py := cy + dy
				if px >= 0 and px < SCREEN_W and py >= 0 and py < SCREEN_H:
					city_image.set_pixel(px, py, transparent)

	city_texture.update(city_image)
