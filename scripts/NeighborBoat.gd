class_name NeighborBoat
extends Area3D

@export var fisher_name: String = "Chacho (Canoero del Espinel)"
@export var fisher_role: String = "Pescador Vecino de la Cooperativa"
@export var dialogue_text: String = "\"Buen día, hermano. En el Pozo Profundo del centro andan acardumados los Surubíes grandes, pero sin la Caña de tacuara te van a cortar la tanza. Y ojo esta noche: la barcaza 'El Sábalo Negro' patrulla la laguna oeste.\""
@export var portrait_icon: String = "res://Used_Assets/ui/boat-fishing.png"
@export var patrol_points: PackedVector3Array = []
@export var cruise_speed: float = 2.6

@onready var visual_root: Node3D = $VisualRoot
@onready var lbl_name_3d: Label3D = $LblName3D

var player_inside: bool = false
var _wp_idx: int = 0
var _bob_t: float = 0.0
var _base_pos: Vector3

func _ready() -> void:
	add_to_group("neighbor_boat")
	_base_pos = global_position
	if lbl_name_3d:
		lbl_name_3d.text = fisher_name
	if patrol_points.is_empty():
		patrol_points = PackedVector3Array([
			_base_pos,
			_base_pos + Vector3(14.0, 0.0, -10.0),
			_base_pos + Vector3(-10.0, 0.0, -16.0)
		])
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.phase_changed.connect(_on_phase_changed)
	_refresh_phase_state(GameState.current_phase)

func is_available() -> bool:
	return visible and GameState.current_phase != GameState.TimePhase.NIGHT

func _process(delta: float) -> void:
	if not visible or GameState.is_game_over or GameState.is_time_paused:
		return
	_bob_t += delta
	if visual_root:
		visual_root.position.y = sin(_bob_t * 2.4) * 0.05
		visual_root.rotation.z = cos(_bob_t * 1.9) * 0.035

	if player_inside:
		return

	if patrol_points.size() < 2:
		return
	var target: Vector3 = patrol_points[_wp_idx]
	target.y = global_position.y
	var to_t: Vector3 = target - global_position
	var dist: float = to_t.length()
	if dist < 1.2:
		_wp_idx = (_wp_idx + 1) % patrol_points.size()
		return
	var dir: Vector3 = to_t / dist
	global_position += dir * cruise_speed * delta
	var target_yaw: float = atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, delta * 2.5)

func _on_phase_changed(new_phase: GameState.TimePhase, _day: int) -> void:
	_refresh_phase_state(new_phase)

func _refresh_phase_state(phase: GameState.TimePhase) -> void:
	visible = (phase != GameState.TimePhase.NIGHT)
	if not visible:
		player_inside = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player_boat"):
		player_inside = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player_boat"):
		player_inside = false
