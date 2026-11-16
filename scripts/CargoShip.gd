class_name CargoShip
extends Node3D

const WAKE_WAVE_SCENE: PackedScene = preload("res://scenes/WakeWave.tscn")

@export var channel_x: float = 34.0
@export var start_z: float = 125.0
@export var end_z: float = -125.0
@export var cruise_speed: float = 14.5
@export var spawn_interval: float = 55.0

@onready var sfx_horn: AudioStreamPlayer3D = $SfxWakeRumble

var is_cruising: bool = false
var _cooldown_timer: float = 20.0
var _wake_emitted_this_pass: bool = false

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	if GameState.is_game_over or GameState.is_time_paused:
		return

	if not is_cruising:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			_start_pass()
		return

	global_position.z = move_toward(global_position.z, end_z, cruise_speed * delta)
	if not _wake_emitted_this_pass and global_position.z <= 24.0:
		_wake_emitted_this_pass = true
		if sfx_horn:
			sfx_horn.play()
		_spawn_physical_wake_wave()
		GameState.emit_signal("wake_wave_triggered", Vector3(-1.0, 0.0, 0.0), 1.0)
		GameState.emit_signal(
			"notification_requested",
			"🌊 ¡MAREJADA AVANZANDO DESDE EL CANAL ESTE! Enfrentá la ola de proa o metete a los juncos.",
			Color(0.98, 0.65, 0.22)
		)

	if absf(global_position.z - end_z) < 0.5:
		is_cruising = false
		visible = false
		_cooldown_timer = spawn_interval

func _spawn_physical_wake_wave() -> void:
	var wave: Node3D = WAKE_WAVE_SCENE.instantiate() as Node3D
	if wave and get_parent():
		get_parent().add_child(wave)
		wave.global_position = Vector3(channel_x - 4.0, 0.0, 0.0)

func _start_pass() -> void:
	is_cruising = true
	_wake_emitted_this_pass = false
	global_position = Vector3(channel_x, 0.0, start_z)
	visible = true
	if sfx_horn:
		sfx_horn.play()
	GameState.emit_signal(
		"notification_requested",
		"🚢 ¡Buque ultramarino entrando por el canal profundo! Se acerca marejada desde el Este.",
		Color(1.0, 0.78, 0.35)
	)
