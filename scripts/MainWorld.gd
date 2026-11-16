class_name MainWorld
extends Node3D

@onready var sun_light: DirectionalLight3D = $SunLight
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var water_mesh: MeshInstance3D = $ParanaWater
@onready var pier_light: OmniLight3D = $CooperativePier/PierLantern
@onready var pier_area: Area3D = $CooperativePier/DockingZone

var _target_sun_color: Color = Color(1.0, 0.95, 0.84)
var _target_sun_energy: float = 1.35
var _target_sun_pitch: float = -52.0
var _target_sky_top: Color = Color(0.32, 0.56, 0.82)
var _target_sky_horizon: Color = Color(0.68, 0.76, 0.82)
var _target_fog_color: Color = Color(0.58, 0.62, 0.58)
var _target_fog_density: float = 0.0035
var _target_shallow_water: Color = Color(0.46, 0.34, 0.21, 0.94)
var _target_deep_water: Color = Color(0.28, 0.19, 0.11, 0.98)
var _wake_shader_fade: float = 0.0

func _ready() -> void:
	if pier_area:
		pier_area.body_entered.connect(_on_pier_body_entered)
		pier_area.body_exited.connect(_on_pier_body_exited)
	for reed_zone: Node in get_tree().get_nodes_in_group("reed_zone"):
		if reed_zone is Area3D:
			var area: Area3D = reed_zone as Area3D
			area.body_entered.connect(_on_reed_body_entered)
			area.body_exited.connect(_on_reed_body_exited)

	GameState.phase_changed.connect(_on_phase_changed)
	GameState.wake_wave_triggered.connect(_on_wake_wave_triggered)
	_apply_phase_targets(GameState.current_phase, true)

func _process(delta: float) -> void:
	_interpolate_atmosphere(delta)
	if _wake_shader_fade > 0.0:
		_wake_shader_fade = move_toward(_wake_shader_fade, 0.0, delta * 0.25)
		var mat: ShaderMaterial = water_mesh.get_active_material(0) as ShaderMaterial
		if mat:
			mat.set_shader_parameter("wake_turbulence", _wake_shader_fade)

func _on_phase_changed(new_phase: GameState.TimePhase, _day: int) -> void:
	_apply_phase_targets(new_phase, false)

func _apply_phase_targets(phase: GameState.TimePhase, immediate: bool) -> void:
	match phase:
		GameState.TimePhase.DAY:
			_target_sun_color = Color(1.0, 0.95, 0.84)
			_target_sun_energy = 1.35
			_target_sun_pitch = -52.0
			_target_sky_top = Color(0.32, 0.56, 0.82)
			_target_sky_horizon = Color(0.68, 0.74, 0.76)
			_target_fog_color = Color(0.58, 0.56, 0.48)
			_target_fog_density = 0.0032
			_target_shallow_water = Color(0.46, 0.34, 0.21, 0.94)
			_target_deep_water = Color(0.28, 0.19, 0.11, 0.98)
			if pier_light:
				pier_light.light_energy = 0.5
		GameState.TimePhase.SUNSET:
			_target_sun_color = Color(1.0, 0.48, 0.18)
			_target_sun_energy = 1.05
			_target_sun_pitch = -15.0
			_target_sky_top = Color(0.26, 0.22, 0.44)
			_target_sky_horizon = Color(0.92, 0.44, 0.22)
			_target_fog_color = Color(0.66, 0.36, 0.24)
			_target_fog_density = 0.0065
			_target_shallow_water = Color(0.42, 0.25, 0.16, 0.95)
			_target_deep_water = Color(0.22, 0.12, 0.10, 0.98)
			if pier_light:
				pier_light.light_energy = 3.2
		GameState.TimePhase.NIGHT:
			_target_sun_color = Color(0.25, 0.38, 0.62)
			_target_sun_energy = 0.22
			_target_sun_pitch = -38.0
			_target_sky_top = Color(0.03, 0.06, 0.14)
			_target_sky_horizon = Color(0.07, 0.13, 0.24)
			_target_fog_color = Color(0.05, 0.10, 0.18)
			_target_fog_density = 0.0145
			_target_shallow_water = Color(0.12, 0.14, 0.18, 0.96)
			_target_deep_water = Color(0.05, 0.07, 0.11, 0.99)
			if pier_light:
				pier_light.light_energy = 4.2

	if immediate:
		_interpolate_atmosphere(100.0)

func _interpolate_atmosphere(delta: float) -> void:
	var spd: float = clampf(delta * 1.8, 0.0, 1.0)
	if sun_light:
		sun_light.light_color = sun_light.light_color.lerp(_target_sun_color, spd)
		sun_light.light_energy = lerpf(sun_light.light_energy, _target_sun_energy, spd)
		sun_light.rotation_degrees.x = lerpf(sun_light.rotation_degrees.x, _target_sun_pitch, spd)

	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		env.fog_light_color = env.fog_light_color.lerp(_target_fog_color, spd)
		env.fog_density = lerpf(env.fog_density, _target_fog_density, spd)
		env.ambient_light_color = env.ambient_light_color.lerp(_target_fog_color, spd)
		if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
			var sky_mat: ProceduralSkyMaterial = env.sky.sky_material as ProceduralSkyMaterial
			sky_mat.sky_top_color = sky_mat.sky_top_color.lerp(_target_sky_top, spd)
			sky_mat.sky_horizon_color = sky_mat.sky_horizon_color.lerp(_target_sky_horizon, spd)
			sky_mat.ground_horizon_color = sky_mat.ground_horizon_color.lerp(_target_sky_horizon, spd)
			sky_mat.ground_bottom_color = sky_mat.ground_bottom_color.lerp(_target_deep_water, spd)

	if water_mesh:
		var mat: ShaderMaterial = water_mesh.get_active_material(0) as ShaderMaterial
		if mat:
			var cur_sh: Color = mat.get_shader_parameter("shallow_color")
			var cur_dp: Color = mat.get_shader_parameter("deep_color")
			mat.set_shader_parameter("shallow_color", cur_sh.lerp(_target_shallow_water, spd))
			mat.set_shader_parameter("deep_color", cur_dp.lerp(_target_deep_water, spd))

func _on_wake_wave_triggered(_dir: Vector3, intensity: float) -> void:
	_wake_shader_fade = clampf(intensity * 1.2, 0.4, 1.8)

func _on_pier_body_entered(body: Node3D) -> void:
	if body.is_in_group("player_boat"):
		GameState.set_at_pier(true)

func _on_pier_body_exited(body: Node3D) -> void:
	if body.is_in_group("player_boat"):
		GameState.set_at_pier(false)

func _on_reed_body_entered(body: Node3D) -> void:
	if body.is_in_group("player_boat"):
		GameState.is_hidden_in_reeds = true

func _on_reed_body_exited(body: Node3D) -> void:
	if body.is_in_group("player_boat"):
		GameState.is_hidden_in_reeds = false
