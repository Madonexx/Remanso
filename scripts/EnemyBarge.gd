class_name EnemyBarge
extends Node3D

@export var barge_title: String = "Barcaza Clandestina"
@export var evidence_id: String = "barge_alpha"
@export var patrol_points: PackedVector3Array = []
@export var patrol_speed: float = 4.8
@export var spotlight_range: float = 24.0
@export var spotlight_half_angle_deg: float = 24.0
@export var hearing_bonus_range: float = 10.0

@onready var searchlight_pivot: Node3D = $SearchlightPivot
@onready var spot_light: SpotLight3D = $SearchlightPivot/SpotLight3D
@onready var cone_mesh: MeshInstance3D = $SearchlightPivot/ConeMesh

var current_wp_idx: int = 0
var exposure_time: float = 0.0
var _sweep_time: float = 0.0
var _base_pos: Vector3

func _ready() -> void:
	add_to_group("enemy_barge")
	add_to_group("photo_evidence_target")
	_base_pos = global_position
	if patrol_points.is_empty():
		patrol_points = PackedVector3Array([
			_base_pos,
			_base_pos + Vector3(22.0, 0.0, -14.0),
			_base_pos + Vector3(-16.0, 0.0, -24.0)
		])
	GameState.phase_changed.connect(_on_phase_changed)
	_update_phase_state(GameState.current_phase)

func is_evidence_available() -> bool:
	return visible and not GameState.photographed_targets.has(evidence_id)

func get_evidence_label() -> String:
	return barge_title

func _process(delta: float) -> void:
	if not visible or GameState.is_game_over or GameState.is_time_paused:
		return

	_sweep_time += delta
	_patrol_movement(delta)
	_check_player_detection(delta)

func _patrol_movement(delta: float) -> void:
	if patrol_points.size() < 2:
		return
	var target: Vector3 = patrol_points[current_wp_idx]
	target.y = global_position.y
	var to_target: Vector3 = target - global_position
	var dist: float = to_target.length()
	if dist < 1.5:
		current_wp_idx = (current_wp_idx + 1) % patrol_points.size()
		return
	var dir: Vector3 = to_target / dist
	global_position += dir * patrol_speed * delta
	var target_yaw: float = atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, delta * 3.0)

	if searchlight_pivot:
		searchlight_pivot.rotation.y = sin(_sweep_time * 1.35) * 0.65

func _check_player_detection(delta: float) -> void:
	var player: Node3D = get_tree().get_first_node_in_group("player_boat") as Node3D
	if player == null or GameState.is_at_pier:
		exposure_time = move_toward(exposure_time, 0.0, delta * 1.2)
		_update_light_color()
		return

	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()

	var detected: bool = false
	var player_stealthed: bool = GameState.is_hidden_in_reeds and not GameState.is_motor_mode

	if GameState.is_motor_mode and dist <= (GameState.noise_radius + hearing_bonus_range):
		detected = true
		if searchlight_pivot and dist > 0.1:
			var world_dir: Vector3 = to_player.normalized()
			var desired_global_yaw: float = atan2(-world_dir.x, -world_dir.z)
			searchlight_pivot.global_rotation.y = lerp_angle(searchlight_pivot.global_rotation.y, desired_global_yaw, delta * 5.0)

	if not player_stealthed and dist <= spotlight_range and searchlight_pivot:
		var light_forward: Vector3 = (-searchlight_pivot.global_transform.basis.z * Vector3(1.0, 0.0, 1.0)).normalized()
		var dir_to_p: Vector3 = to_player.normalized()
		var angle_deg: float = rad_to_deg(acos(clampf(light_forward.dot(dir_to_p), -1.0, 1.0)))
		if angle_deg <= spotlight_half_angle_deg:
			detected = true

	if detected:
		var was_zero: bool = (exposure_time <= 0.05)
		exposure_time += delta
		if was_zero:
			GameState.emit_signal("notification_requested", "¡Reflector de %s te está enfocando! Salí del haz o metete al juncal." % barge_title, Color(1.0, 0.55, 0.25))
		if exposure_time >= 3.0:
			exposure_time = 0.0
			GameState.confiscate_night_and_respawn()
			return
	else:
		exposure_time = move_toward(exposure_time, 0.0, delta * 1.2)

	_update_light_color()

func _update_light_color() -> void:
	var alert_ratio: float = clampf(exposure_time / 3.0, 0.0, 1.0)
	var col: Color = Color(1.0, 0.9, 0.55).lerp(Color(1.0, 0.18, 0.15), alert_ratio)
	if spot_light:
		spot_light.light_color = col
	if cone_mesh:
		var mat: StandardMaterial3D = cone_mesh.get_active_material(0) as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(col.r, col.g, col.b, lerpf(0.16, 0.36, alert_ratio))

func _on_phase_changed(new_phase: GameState.TimePhase, _day: int) -> void:
	_update_phase_state(new_phase)

func _update_phase_state(phase: GameState.TimePhase) -> void:
	var active: bool = (phase == GameState.TimePhase.NIGHT)
	visible = active
	exposure_time = 0.0
	if active:
		global_position = _base_pos
		current_wp_idx = 0
		_update_light_color()
