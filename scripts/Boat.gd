class_name PlayerBoat
extends CharacterBody3D

@export var motor_max_speed: float = 14.0
@export var motor_accel: float = 9.0
@export var row_base_speed: float = 6.2
@export var row_upgraded_speed: float = 9.0
@export var row_accel: float = 4.2
@export var water_drag: float = 2.4
@export var motor_turn_speed: float = 1.85
@export var row_turn_speed: float = 1.35

@onready var visual_root: Node3D = $VisualRoot
@onready var outboard_motor: Node3D = $VisualRoot/OutboardMotor
@onready var armor_plates: Node3D = $VisualRoot/ArmorPlates
@onready var bow_lantern: SpotLight3D = $VisualRoot/BowLantern
@onready var bow_omni: OmniLight3D = $VisualRoot/BowOmni
@onready var noise_ring: MeshInstance3D = $NoiseRing

@onready var camera_rig: Node3D = $CameraRig
@onready var spring_arm: SpringArm3D = $CameraRig/SpringArm3D
@onready var camera_3d: Camera3D = $CameraRig/SpringArm3D/Camera3D

@onready var sfx_start: AudioStreamPlayer3D = $Audio/SfxMotorStart
@onready var sfx_loop: AudioStreamPlayer3D = $Audio/SfxMotorLoop
@onready var sfx_stop: AudioStreamPlayer3D = $Audio/SfxMotorStop
@onready var sfx_rev: AudioStreamPlayer3D = $Audio/SfxMotorRev
@onready var sfx_row: AudioStreamPlayer3D = $Audio/SfxRowSplash

var current_speed: float = 0.0
var camera_yaw: float = 0.0
var camera_pitch: float = -26.0
var viewfinder_pitch: float = -4.0
var is_orbit_dragging: bool = false
var is_viewfinder_active: bool = false

var _bob_time: float = 0.0
var _row_stroke_timer: float = 0.0
var _wake_roll_impulse: float = 0.0
var _spawn_transform: Transform3D

func _ready() -> void:
	add_to_group("player_boat")
	_spawn_transform = global_transform
	camera_rig.top_level = true
	camera_rig.global_position = global_position + Vector3(0.0, 1.35, 0.0)
	camera_yaw = rotation.y
	_apply_mode_visuals()
	_update_lantern_for_phase(GameState.current_phase)
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.stats_changed.connect(_apply_mode_visuals)
	GameState.night_confiscated.connect(_on_night_confiscated)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and not is_viewfinder_active:
			is_orbit_dragging = mb.pressed
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if is_viewfinder_active:
			camera_yaw -= mm.relative.x * 0.0032
			viewfinder_pitch = clampf(viewfinder_pitch - mm.relative.y * 0.14, -32.0, 24.0)
		elif is_orbit_dragging:
			camera_yaw -= mm.relative.x * 0.006
			camera_pitch = clampf(camera_pitch - mm.relative.y * 0.18, -52.0, -12.0)

	if event.is_action_pressed("toggle_motor") and not GameState.is_time_paused:
		toggle_motor_mode()

func _physics_process(delta: float) -> void:
	if GameState.is_game_over or GameState.is_time_paused:
		velocity = Vector3.ZERO
		_update_camera_rig(delta)
		return

	_bob_time += delta
	var throttle: float = Input.get_axis("move_backward", "move_forward")
	var steer: float = Input.get_axis("turn_right", "turn_left")

	if Input.is_key_pressed(KEY_UP) and throttle == 0.0:
		throttle = 1.0
	elif Input.is_key_pressed(KEY_DOWN) and throttle == 0.0:
		throttle = -1.0
	if Input.is_key_pressed(KEY_LEFT) and steer == 0.0:
		steer = 1.0
	elif Input.is_key_pressed(KEY_RIGHT) and steer == 0.0:
		steer = -1.0

	var max_spd: float = motor_max_speed if GameState.is_motor_mode else (
		row_upgraded_speed if bool(GameState.upgrades.get("remos_anchos", false)) else row_base_speed
	)
	var accel_val: float = motor_accel if GameState.is_motor_mode else row_accel
	var turn_spd: float = motor_turn_speed if GameState.is_motor_mode else row_turn_speed

	if absf(throttle) > 0.05:
		var target_spd: float = throttle * max_spd * (0.55 if throttle < 0.0 else 1.0)
		current_speed = move_toward(current_speed, target_spd, accel_val * delta)
	else:
		current_speed = move_toward(current_speed, 0.0, water_drag * delta)

	var turn_factor: float = clampf(absf(current_speed) / 2.5, 0.35, 1.0)
	if current_speed < -0.2:
		turn_factor *= -1.0
	rotation.y += steer * turn_spd * turn_factor * delta

	var forward_dir: Vector3 = -global_transform.basis.z
	velocity.x = forward_dir.x * current_speed
	velocity.z = forward_dir.z * current_speed
	velocity.y = (0.0 - global_position.y) * 6.0

	var collided: bool = move_and_slide()
	if collided and absf(current_speed) > 6.5:
		GameState.apply_hull_damage(absf(current_speed) * 0.65)
		current_speed *= 0.35

	_update_noise_and_audio(delta, absf(throttle))
	_update_visual_bob(delta, throttle, steer)
	_update_camera_rig(delta)

func toggle_motor_mode() -> void:
	GameState.is_motor_mode = not GameState.is_motor_mode
	_apply_mode_visuals()
	if GameState.is_motor_mode:
		sfx_start.play()
		sfx_loop.play()
	else:
		sfx_loop.stop()
		sfx_stop.play()
	GameState.emit_signal("motor_mode_changed", GameState.is_motor_mode, GameState.noise_radius)

func _apply_mode_visuals() -> void:
	if outboard_motor:
		outboard_motor.visible = GameState.is_motor_mode
	if noise_ring:
		noise_ring.visible = GameState.is_motor_mode
	if armor_plates:
		armor_plates.visible = bool(GameState.upgrades.get("casco_reforzado", false))

func _update_noise_and_audio(delta: float, abs_throttle: float) -> void:
	if GameState.is_motor_mode:
		var target_noise: float = 11.0 + abs_throttle * 18.0
		GameState.noise_radius = lerpf(GameState.noise_radius, target_noise, delta * 5.0)
		sfx_loop.pitch_scale = lerpf(0.88, 1.38, absf(current_speed) / motor_max_speed)
		if noise_ring:
			var pulse: float = 1.0 + sin(_bob_time * 5.0) * 0.08
			var ring_scale: float = (GameState.noise_radius / 10.0) * pulse
			noise_ring.scale = Vector3(ring_scale, 1.0, ring_scale)
	else:
		GameState.noise_radius = move_toward(GameState.noise_radius, 0.0, delta * 14.0)
		if abs_throttle > 0.1:
			_row_stroke_timer += delta * (1.35 if bool(GameState.upgrades.get("remos_anchos", false)) else 1.0)
			if _row_stroke_timer >= 0.95:
				_row_stroke_timer = 0.0
				sfx_row.pitch_scale = randf_range(0.92, 1.08)
				sfx_row.play()
		else:
			_row_stroke_timer = 0.6

func _update_visual_bob(delta: float, _throttle: float, steer: float) -> void:
	_wake_roll_impulse = move_toward(_wake_roll_impulse, 0.0, delta * 1.8)
	var pitch_bob: float = sin(_bob_time * 2.4) * 0.035 + clampf(current_speed / motor_max_speed, -0.3, 0.5) * 0.08
	var roll_bob: float = cos(_bob_time * 1.9) * 0.03 - steer * 0.09 + sin(_bob_time * 7.5) * _wake_roll_impulse
	visual_root.rotation.x = lerpf(visual_root.rotation.x, pitch_bob, delta * 6.0)
	visual_root.rotation.z = lerpf(visual_root.rotation.z, roll_bob, delta * 6.0)
	visual_root.position.y = sin(_bob_time * 2.8) * 0.05

func _update_camera_rig(delta: float) -> void:
	if is_viewfinder_active:
		camera_rig.global_position = camera_rig.global_position.lerp(global_position + Vector3(0.0, 2.0, 0.0), delta * 12.0)
		spring_arm.spring_length = lerpf(spring_arm.spring_length, 0.6, delta * 10.0)
		camera_3d.fov = lerpf(camera_3d.fov, 32.0 if bool(GameState.upgrades.get("teleobjetivo", false)) else 48.0, delta * 8.0)
		camera_rig.rotation.y = lerp_angle(camera_rig.rotation.y, camera_yaw, delta * 18.0)
		spring_arm.rotation.x = deg_to_rad(lerpf(rad_to_deg(spring_arm.rotation.x), viewfinder_pitch, delta * 18.0))
	else:
		camera_rig.global_position = camera_rig.global_position.lerp(global_position + Vector3(0.0, 1.35, 0.0), delta * 7.5)
		spring_arm.spring_length = lerpf(spring_arm.spring_length, 13.5, delta * 6.0)
		camera_3d.fov = lerpf(camera_3d.fov, 62.0, delta * 6.0)
		camera_rig.rotation.y = lerp_angle(camera_rig.rotation.y, camera_yaw, delta * 8.0)
		spring_arm.rotation.x = deg_to_rad(camera_pitch)

func _on_phase_changed(new_phase: GameState.TimePhase, _day: int) -> void:
	_update_lantern_for_phase(new_phase)

func _update_lantern_for_phase(phase: GameState.TimePhase) -> void:
	var night_or_sunset: bool = (phase == GameState.TimePhase.NIGHT or phase == GameState.TimePhase.SUNSET)
	if bow_lantern:
		bow_lantern.visible = night_or_sunset
		bow_lantern.light_energy = 5.5 if phase == GameState.TimePhase.NIGHT else 2.2
	if bow_omni:
		bow_omni.visible = night_or_sunset

func on_physical_wake_contact(wave_dir: Vector3, intensity: float) -> void:
	if GameState.is_hidden_in_reeds or GameState.is_at_pier:
		GameState.emit_signal("notification_requested", "🌿 Los juncales frenaron el golpe de la marejada.", Color(0.45, 0.9, 0.6))
		return
	var forward_flat: Vector3 = (-global_transform.basis.z * Vector3(1.0, 0.0, 1.0)).normalized()
	var wave_flat: Vector3 = (wave_dir * Vector3(1.0, 0.0, 1.0)).normalized()
	var alignment: float = absf(forward_flat.dot(wave_flat))
	var base_dmg: float = 24.0 * intensity
	if alignment >= 0.70:
		_wake_roll_impulse = 0.16 * intensity
		var reduced_dmg: float = base_dmg * 0.25
		GameState.apply_hull_damage(reduced_dmg)
		GameState.emit_signal("notification_requested", "⚓ ¡Cortaste la marejada de proa! Daño reducido un 75%.", Color(0.45, 0.95, 0.65))
	else:
		_wake_roll_impulse = 0.52 * intensity
		GameState.apply_hull_damage(base_dmg)
		GameState.emit_signal("notification_requested", "🌊 ¡La marejada te agarró de costado! (-%d%% casco)" % roundi(base_dmg), Color(1.0, 0.45, 0.3))

func _on_night_confiscated() -> void:
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	current_speed = 0.0
	if GameState.is_motor_mode:
		toggle_motor_mode()
