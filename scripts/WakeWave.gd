class_name WakeWave
extends Area3D

@export var wave_direction: Vector3 = Vector3(-1.0, 0.0, 0.0)
@export var wave_speed: float = 14.0
@export var max_travel_distance: float = 98.0

var _traveled: float = 0.0
var _already_hit_player: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if GameState.is_game_over or GameState.is_time_paused:
		return
	var step: float = wave_speed * delta
	global_position += wave_direction.normalized() * step
	_traveled += step
	if _traveled >= max_travel_distance:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if _already_hit_player:
		return
	if body.is_in_group("player_boat") and body.has_method("on_physical_wake_contact"):
		_already_hit_player = true
		body.call("on_physical_wake_contact", wave_direction.normalized(), 1.0)
