class_name PassiveNetSpot
extends Area3D

@export var spot_name: String = "Boca del Arroyo"
@export var catch_duration: float = 45.0

@onready var deployed_visuals: Node3D = $DeployedVisuals
@onready var marker_buoy: Node3D = $MarkerBuoy

var is_deployed: bool = false
var elapsed_time: float = 0.0
var is_ready_to_harvest: bool = false
var player_inside: bool = false

func _ready() -> void:
	add_to_group("passive_net_spot")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.phase_changed.connect(_on_phase_changed)
	_update_visuals()

func _process(delta: float) -> void:
	if is_deployed and not is_ready_to_harvest and not GameState.is_time_paused:
		elapsed_time += delta
		if elapsed_time >= catch_duration:
			is_ready_to_harvest = true
			GameState.emit_signal("notification_requested", "¡La malla reglamentaria en %s tiene captura lista!" % spot_name, Color(0.45, 0.95, 0.65))

func get_prompt_text() -> String:
	if GameState.current_phase == GameState.TimePhase.NIGHT:
		return ""
	if not is_deployed:
		var max_nets: int = GameState.get_max_passive_nets()
		if GameState.active_passive_nets >= max_nets:
			return "Mallas en uso (%d/%d)" % [GameState.active_passive_nets, max_nets]
		return "[E] Tirar Malla Reglamentaria (%s)" % spot_name
	if is_ready_to_harvest:
		return "[E] Levantar Malla Reglamentaria (¡Con captura!)"
	var left: int = ceili(maxf(1.0, catch_duration - elapsed_time))
	return "[E] Levantar Malla (Calando... %ds)" % left

func interact_net() -> Array[Dictionary]:
	var caught_list: Array[Dictionary] = []
	if GameState.current_phase == GameState.TimePhase.NIGHT:
		return caught_list
	if not is_deployed:
		if GameState.active_passive_nets >= GameState.get_max_passive_nets():
			GameState.emit_signal("notification_requested", "Ya calaste el máximo de mallas reglamentarias permitidas.", Color(0.95, 0.7, 0.3))
			return caught_list
		is_deployed = true
		elapsed_time = 0.0
		is_ready_to_harvest = false
		GameState.active_passive_nets += 1
		_update_visuals()
		GameState.emit_signal("notification_requested", "Malla reglamentaria calada en %s (45 s)." % spot_name, Color(0.55, 0.88, 0.95))
		return caught_list

	# Retrieving net
	is_deployed = false
	GameState.active_passive_nets = maxi(0, GameState.active_passive_nets - 1)
	if is_ready_to_harvest:
		var legal_pool: Array[String] = ["sabalo", "boga", "pati"]
		var count: int = randi_range(1, 3)
		for i: int in range(count):
			var sp: String = legal_pool[randi() % legal_pool.size()]
			var spec: Dictionary = GameState.SPECIES_CATALOG[sp]
			var min_cm: int = int(spec["min_cm"])
			var max_cm: int = int((spec["range_cm"] as Vector2i).y)
			var cm: int = randi_range(min_cm + 2, max_cm)
			caught_list.append({"species_id": sp, "length_cm": cm})
	elapsed_time = 0.0
	is_ready_to_harvest = false
	_update_visuals()
	return caught_list

func _update_visuals() -> void:
	if deployed_visuals:
		deployed_visuals.visible = is_deployed
	if marker_buoy:
		marker_buoy.visible = (GameState.current_phase != GameState.TimePhase.NIGHT)

func _on_phase_changed(_new_phase: GameState.TimePhase, _day: int) -> void:
	_update_visuals()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player_boat"):
		player_inside = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player_boat"):
		player_inside = false
