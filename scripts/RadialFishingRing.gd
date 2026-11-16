class_name RadialFishingRing
extends Control

signal fish_caught(species_id: String, length_cm: int)
signal fishing_cancelled()

var active_species_id: String = "sabalo"
var is_active: bool = false
var needle_angle_deg: float = 0.0
var needle_dir: float = 1.0
var needle_speed_deg: float = 130.0
var green_center_deg: float = 90.0
var green_half_arc_deg: float = 28.0
var reel_progress: float = 0.35
var _erratic_timer: float = 0.0
var _reversal_cooldown: float = 2.2
var _telegraph_timer: float = 0.0
var _flash_timer: float = 0.0
var _flash_color: Color = Color.WHITE

var sfx_tick: AudioStreamPlayer
var sfx_catch: AudioStreamPlayer

func _ready() -> void:
	visible = false
	sfx_tick = AudioStreamPlayer.new()
	sfx_tick.stream = load("res://Used_Assets/audio/fishing_tick.wav")
	add_child(sfx_tick)
	sfx_catch = AudioStreamPlayer.new()
	sfx_catch.stream = load("res://Used_Assets/audio/fishing_catch.wav")
	add_child(sfx_catch)

func start_minigame(species_id: String) -> void:
	active_species_id = species_id
	var spec: Dictionary = GameState.SPECIES_CATALOG.get(species_id, GameState.SPECIES_CATALOG["sabalo"])

	var has_cana: bool = bool(GameState.upgrades.get("cana_tacuara", false))
	var has_linea: bool = bool(GameState.upgrades.get("linea_trenzada", false))
	var is_common: bool = (species_id == "sabalo" or species_id == "boga")

	# Common fish stay accessible on Day 1; trophy/protected species run a faster stepped curve unless upgraded
	var speed_factor: float = 76.0 if is_common else 86.0
	needle_speed_deg = float(spec["needle_speed"]) * speed_factor * (0.72 if has_cana else 1.0)

	var arc_factor: float = 0.60 if is_common else 0.50
	green_half_arc_deg = float(spec["green_arc_deg"]) * arc_factor * (1.42 if has_linea else 1.0)

	needle_angle_deg = 0.0
	needle_dir = 1.0
	reel_progress = 0.44 if has_linea else (0.36 if is_common else 0.30)
	_erratic_timer = 0.0
	_reversal_cooldown = 2.0
	_telegraph_timer = 0.0
	_randomize_green_zone()
	is_active = true
	visible = true
	queue_redraw()

func stop_minigame() -> void:
	is_active = false
	visible = false

func _process(delta: float) -> void:
	if not is_active:
		return
	var is_heavy: bool = (active_species_id == "surubi" or active_species_id == "pati")
	var is_erratic: bool = (active_species_id == "dorado" or active_species_id == "pacu")
	var has_cana: bool = bool(GameState.upgrades.get("cana_tacuara", false))
	var has_linea: bool = bool(GameState.upgrades.get("linea_trenzada", false))
	var has_senuelo: bool = bool(GameState.upgrades.get("senuelo_litoral", false))

	var spd_mult: float = 1.0
	if is_erratic:
		_erratic_timer += delta
		var osc_amp: float = 0.12 if has_senuelo else 0.34
		spd_mult = 1.0 + sin(_erratic_timer * 5.8) * osc_amp
		if _telegraph_timer > 0.0:
			_telegraph_timer -= delta
			spd_mult *= 0.45
			if _telegraph_timer <= 0.0:
				needle_dir *= -1.0
				_reversal_cooldown = randf_range(3.6, 5.2) if has_senuelo else randf_range(1.65, 2.45)
		else:
			_reversal_cooldown -= delta
			if _reversal_cooldown <= 0.0:
				_telegraph_timer = 0.42

	needle_angle_deg = fposmod(needle_angle_deg + needle_dir * needle_speed_deg * spd_mult * delta, 360.0)

	var pull_drain: float = 0.020
	if active_species_id == "surubi":
		pull_drain = 0.078 * (0.45 if has_cana else 1.0)
	elif is_heavy or is_erratic:
		pull_drain = 0.062 * (0.48 if has_cana else 1.0)
	if has_linea:
		pull_drain *= 0.70

	reel_progress = clampf(reel_progress - pull_drain * delta, 0.0, 1.0)
	if _flash_timer > 0.0:
		_flash_timer = maxf(0.0, _flash_timer - delta)
	if reel_progress <= 0.01:
		stop_minigame()
		GameState.emit_signal("notification_requested", "¡Cortó la tanza! Ese ejemplar grande pide mejor caña o línea.", Color(0.95, 0.55, 0.35))
		emit_signal("fishing_cancelled")
		return
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			attempt_strike()
			accept_event()

func attempt_strike() -> void:
	if not is_active:
		return
	var diff: float = absf(wrapf(needle_angle_deg - green_center_deg, -180.0, 180.0))
	if diff <= green_half_arc_deg:
		sfx_tick.pitch_scale = randf_range(0.95, 1.15)
		sfx_tick.play()
		var is_common: bool = (active_species_id == "sabalo" or active_species_id == "boga")
		reel_progress += 0.36 if is_common else 0.31
		_flash_color = Color(0.35, 0.95, 0.55)
		_flash_timer = 0.18
		if reel_progress >= 1.0:
			sfx_catch.play()
			stop_minigame()
			var spec: Dictionary = GameState.SPECIES_CATALOG.get(active_species_id, GameState.SPECIES_CATALOG["sabalo"])
			var rng_cm: Vector2i = spec["range_cm"] as Vector2i
			var min_roll: int = rng_cm.x
			if bool(GameState.upgrades.get("senuelo_litoral", false)):
				min_roll = roundi(lerpf(float(rng_cm.x), float(rng_cm.y), 0.45))
			var caught_cm: int = randi_range(min_roll, rng_cm.y)
			emit_signal("fish_caught", active_species_id, caught_cm)
			return
		_randomize_green_zone()
	else:
		sfx_tick.pitch_scale = 0.65
		sfx_tick.play()
		var is_heavy: bool = (active_species_id == "surubi" or active_species_id == "pati")
		var is_erratic: bool = (active_species_id == "dorado" or active_species_id == "pacu")
		var has_cana: bool = bool(GameState.upgrades.get("cana_tacuara", false))
		var penalty: float = 0.11
		if is_heavy:
			penalty = 0.26 * (0.45 if has_cana else 1.0)
		elif is_erratic:
			penalty = 0.22 * (0.55 if has_cana else 1.0)
		reel_progress = maxf(0.02, reel_progress - penalty)
		_flash_color = Color(0.95, 0.32, 0.28)
		_flash_timer = 0.22

func _randomize_green_zone() -> void:
	green_center_deg = fposmod(needle_angle_deg + randf_range(95.0, 255.0), 360.0)

func _draw() -> void:
	if not is_active:
		return
	var center: Vector2 = size * 0.5
	var radius: float = 96.0

	draw_circle(center, radius + 24.0, Color(0.094, 0.133, 0.141, 0.88))
	draw_arc(center, radius + 24.0, 0.0, TAU, 64, Color(0.788, 0.604, 0.271, 0.95), 3.0, true)
	draw_arc(center, radius - 22.0, 0.0, TAU, 64, Color(0.788, 0.604, 0.271, 0.55), 2.0, true)

	draw_arc(center, radius, 0.0, TAU, 64, Color(0.05, 0.08, 0.09, 0.95), 22.0, true)

	var a_start: float = deg_to_rad(green_center_deg - green_half_arc_deg)
	var a_end: float = deg_to_rad(green_center_deg + green_half_arc_deg)
	var zone_col: Color = Color(0.32, 0.82, 0.45, 0.95) if _flash_timer <= 0.0 else _flash_color
	draw_arc(center, radius, a_start, a_end, 32, zone_col, 22.0, true)

	var prog_end: float = -PI * 0.5 + TAU * clampf(reel_progress, 0.0, 1.0)
	draw_arc(center, radius - 32.0, -PI * 0.5, prog_end, 48, Color(0.357, 0.604, 0.663, 0.95), 9.0, true)

	var n_rad: float = deg_to_rad(needle_angle_deg)
	var n_dir: Vector2 = Vector2(cos(n_rad), sin(n_rad))
	var needle_col: Color = Color(1.0, 0.58, 0.18) if _telegraph_timer > 0.0 else Color(0.98, 0.92, 0.72)
	draw_line(center + n_dir * (radius - 26.0), center + n_dir * (radius + 20.0), needle_col, 4.5, true)
	draw_circle(center + n_dir * radius, 6.5 if _telegraph_timer > 0.0 else 6.0, needle_col)

	var font: Font = ThemeDB.fallback_font
	var pct_txt: String = "¡GIRO!" if _telegraph_timer > 0.0 else ("%d%%" % roundi(reel_progress * 100.0))
	var txt_col: Color = Color(1.0, 0.65, 0.25) if _telegraph_timer > 0.0 else Color(0.92, 0.88, 0.78)
	draw_string(font, center + Vector2(-32.0, 4.0), pct_txt, HORIZONTAL_ALIGNMENT_CENTER, 64.0, 17, txt_col)
	draw_string(font, center + Vector2(-70.0, 26.0), "[E / Espacio] Clavar", HORIZONTAL_ALIGNMENT_CENTER, 140.0, 13, Color(0.788, 0.604, 0.271))
