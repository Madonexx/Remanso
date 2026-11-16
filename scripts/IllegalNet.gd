class_name IllegalNet
extends Area3D

@export var net_location: String = "Paso de la Laguna"
@export var evidence_id: String = "tramayo_1"

@onready var sfx_cut: AudioStreamPlayer3D = $SfxNetCut

var is_cut: bool = false
var cut_progress: float = 0.0
var player_inside: bool = false

func _ready() -> void:
	add_to_group("illegal_net")
	add_to_group("photo_evidence_target")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.phase_changed.connect(_on_phase_changed)
	_refresh_visibility()

func is_active_net() -> bool:
	return not is_cut and GameState.current_phase == GameState.TimePhase.NIGHT

func is_evidence_available() -> bool:
	return is_active_net() and not GameState.photographed_targets.has(evidence_id)

func get_evidence_label() -> String:
	return "Tramayo Ilegal (%s)" % net_location

func get_required_cut_time() -> float:
	return 2.0 if bool(GameState.upgrades.get("bichero_machete", false)) else 6.0

func process_cutting(delta: float, holding_interact: bool) -> float:
	if not is_active_net() or not player_inside:
		cut_progress = 0.0
		return 0.0
	var req_time: float = get_required_cut_time()
	if holding_interact:
		if cut_progress == 0.0 and sfx_cut and not sfx_cut.playing:
			sfx_cut.play()
		cut_progress += delta
		if cut_progress >= req_time:
			_complete_cut()
			return 1.0
		return clampf(cut_progress / req_time, 0.0, 1.0)
	else:
		cut_progress = move_toward(cut_progress, 0.0, delta * 2.0)
		return clampf(cut_progress / req_time, 0.0, 1.0)

func _complete_cut() -> void:
	is_cut = true
	cut_progress = 0.0
	if sfx_cut:
		sfx_cut.play()
	_refresh_visibility()
	GameState.modify_river_health(12.0, "¡Cortaste el tramayo clandestino en %s! (+12%% Salud del Río)" % net_location)

func _refresh_visibility() -> void:
	visible = is_active_net()

func _on_phase_changed(new_phase: GameState.TimePhase, _day: int) -> void:
	if new_phase == GameState.TimePhase.NIGHT:
		is_cut = false
		cut_progress = 0.0
	_refresh_visibility()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player_boat"):
		player_inside = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player_boat"):
		player_inside = false
		cut_progress = 0.0
