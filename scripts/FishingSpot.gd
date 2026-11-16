class_name FishingSpot
extends Area3D

enum HabitatType { BAJIO_COSTA, POZO_PROFUNDO, REMANSO_JUNCOS }

@export var spot_title: String = "Cardumen de la Laguna"
@export var habitat_type: HabitatType = HabitatType.BAJIO_COSTA
@export var species_pool: PackedStringArray = ["sabalo", "boga", "pati", "surubi", "dorado", "pacu"]
@export var max_daily_catches: int = 3
@export var respawn_cooldown: float = 35.0

@onready var fish_orbit: Node3D = $FishOrbit
@onready var bubbles: CPUParticles3D = $Bubbles
@onready var ripple_ring: MeshInstance3D = $RippleRing

var remaining_catches: int = 3
var player_inside: bool = false
var _orbit_angle: float = 0.0
var _base_ring_scale: float = 1.0
var _base_fish_scale: float = 1.0
var _orbit_speed: float = 1.65
var _respawn_timer: float = 0.0

func _ready() -> void:
	add_to_group("fishing_spot")
	remaining_catches = max_daily_catches
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.phase_changed.connect(_on_phase_changed)
	_apply_habitat_profile()
	_refresh_visibility()

func _apply_habitat_profile() -> void:
	var ring_col: Color = Color(0.68, 0.92, 0.88, 0.55)
	match habitat_type:
		HabitatType.BAJIO_COSTA:
			species_pool = PackedStringArray(["sabalo", "boga", "sabalo", "dorado"])
			_base_ring_scale = 1.0
			_orbit_speed = 1.55
			_base_fish_scale = 0.95
			ring_col = Color(0.68, 0.92, 0.88, 0.55)
		HabitatType.POZO_PROFUNDO:
			species_pool = PackedStringArray(["surubi", "pati", "surubi", "sabalo"])
			_base_ring_scale = 1.38
			_orbit_speed = 1.25
			_base_fish_scale = 1.45
			ring_col = Color(0.95, 0.72, 0.35, 0.62)
		HabitatType.REMANSO_JUNCOS:
			species_pool = PackedStringArray(["boga", "pacu", "dorado", "boga"])
			_base_ring_scale = 1.15
			_orbit_speed = 2.2
			_base_fish_scale = 1.12
			ring_col = Color(0.55, 0.95, 0.48, 0.58)

	if fish_orbit:
		fish_orbit.scale = Vector3(_base_fish_scale, _base_fish_scale, _base_fish_scale)
	if ripple_ring:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = ring_col
		ripple_ring.material_override = mat

func get_habitat_prompt() -> String:
	match habitat_type:
		HabitatType.BAJIO_COSTA:
			return "[E] Pescar — Bajío de Costa (Sábalo / Boga / Dorado juv.) [%d]" % remaining_catches
		HabitatType.POZO_PROFUNDO:
			return "[E] Pescar — Pozo Profundo (Surubí / Patí / Sábalo) [%d]" % remaining_catches
		HabitatType.REMANSO_JUNCOS:
			return "[E] Pescar — Remanso de Juncos (Boga / Pacú / Dorado) [%d]" % remaining_catches
	return "[E] Pescar — %s" % spot_title

func _process(delta: float) -> void:
	if GameState.current_phase == GameState.TimePhase.NIGHT:
		return

	if remaining_catches <= 0 and _respawn_timer > 0.0 and not GameState.is_time_paused:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			remaining_catches = max_daily_catches
			_refresh_visibility()
			_animate_reemerge()
		return

	if not is_available():
		return

	_orbit_angle += delta * _orbit_speed
	if fish_orbit:
		fish_orbit.rotation.y = _orbit_angle
	if ripple_ring:
		var s: float = _base_ring_scale * (1.0 + sin(_orbit_angle * 2.0) * 0.12)
		ripple_ring.scale = Vector3(s, 1.0, s)

func is_available() -> bool:
	return remaining_catches > 0 and GameState.current_phase != GameState.TimePhase.NIGHT

func pick_random_species() -> String:
	if species_pool.is_empty():
		return "sabalo"
	var idx: int = randi() % species_pool.size()
	return species_pool[idx]

func consume_catch() -> void:
	remaining_catches = maxi(0, remaining_catches - 1)
	if remaining_catches <= 0:
		_respawn_timer = respawn_cooldown
	_refresh_visibility()

func _refresh_visibility() -> void:
	var active: bool = is_available()
	if fish_orbit:
		fish_orbit.visible = active
	if ripple_ring:
		ripple_ring.visible = active
	if bubbles:
		bubbles.emitting = active

func _animate_reemerge() -> void:
	if fish_orbit:
		fish_orbit.scale = Vector3(0.05, 0.05, 0.05)
		var tw: Tween = create_tween()
		tw.tween_property(fish_orbit, "scale", Vector3(_base_fish_scale, _base_fish_scale, _base_fish_scale), 0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_phase_changed(new_phase: GameState.TimePhase, _day: int) -> void:
	if new_phase == GameState.TimePhase.DAY:
		remaining_catches = max_daily_catches
		_respawn_timer = 0.0
	_refresh_visibility()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player_boat"):
		player_inside = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player_boat"):
		player_inside = false
