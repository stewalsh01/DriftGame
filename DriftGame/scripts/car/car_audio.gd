
extends Node

const EngineSoundSettings = preload(
	"res://DriftGame/scripts/car/engine_sound_settings.gd"
)

const TYRE_SKID_SOUND = preload(
	"res://DriftGame/assets/audio/effects/tyre_skid_1.wav"
)
const TYRE_WHEELSPIN_SOUND = preload(
	"res://DriftGame/assets/audio/effects/tyre_skid_2.wav"
)
const TYRE_GRASS_SOUND = preload(
	"res://DriftGame/assets/audio/effects/tyre_skid_3.wav"
)

const IDLE_FADE_START: float = 1000.0
const IDLE_FADE_END: float = 1200.0

@onready var car: CharacterBody3D = get_parent()
@onready var skid_marks: Node = get_node_or_null("../../SkidMarks")
@onready var camera_controller: Camera3D = get_node(
	"../../CameraPivot/Camera3D"
) as Camera3D


@export_category("Tyre Audio")
@export var skid_volume: float = 0.10
@export var wheelspin_volume: float = 1.0
@export var grass_volume: float = 0.30
@export var skid_fade_speed: float = 5.0


@export_category("Drift Pitch")
@export var drift_min_pitch: float = 0.50
@export var drift_max_pitch: float = 1.60
@export var drift_pitch_max_speed: float = 30.0
@export var drift_pitch_response: float = 6.0


@export_category("Wheelspin Pitch")
@export var wheelspin_min_pitch: float = 0.85
@export var wheelspin_max_pitch: float = 1.15
@export var wheelspin_pitch_max_rpm: float = 7000.0
@export var wheelspin_pitch_response: float = 4.0


@export_category("Camera Volume")
# C1 - World Fixed / default
@export var world_fixed_volume: float = 0.8

# C2 - Car Locked
@export var car_locked_volume: float = 1.0

# C3 - Chase
@export var chase_volume: float = 1.8

# C4 - World Overview
@export var world_overview_volume: float = 0.35


var idle_player: AudioStreamPlayer
var engine_player: AudioStreamPlayer

var skid_player: AudioStreamPlayer
var wheelspin_player: AudioStreamPlayer
var grass_player: AudioStreamPlayer

var engine_config: Dictionary
var samples: Array

var active_gear: int = -1
var sample_rpm: float = 2000.0


func setup() -> void:
	var engine_number: int = car.car_config["engine_sound"]

	engine_config = EngineSoundSettings.get_engine(engine_number)
	samples = engine_config["samples"]

	setup_engine_audio()
	setup_tyre_audio()


func setup_engine_audio() -> void:
	idle_player = AudioStreamPlayer.new()
	engine_player = AudioStreamPlayer.new()

	add_child(idle_player)
	add_child(engine_player)

	idle_player.stream = engine_config["idle_sound"]
	idle_player.play()

	update_gear_sound()


func setup_tyre_audio() -> void:
	skid_player = create_tyre_audio_player(TYRE_SKID_SOUND)
	wheelspin_player = create_tyre_audio_player(TYRE_WHEELSPIN_SOUND)
	grass_player = create_tyre_audio_player(TYRE_GRASS_SOUND)


func create_tyre_audio_player(stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	add_child(player)

	player.stream = stream
	player.volume_db = -80.0
	player.pitch_scale = 1.0
	player.play()

	return player


func _process(delta: float) -> void:
	if idle_player == null or engine_player == null:
		return

	var camera_volume: float = get_camera_volume()

	update_engine_audio(camera_volume)
	update_tyre_audio(delta, camera_volume)


# --------------------------------------------------
# ENGINE AUDIO
# --------------------------------------------------

func update_engine_audio(camera_volume: float) -> void:
	var current_rpm: float = car.display_rpm

	if car.current_gear != active_gear:
		update_gear_sound()

	update_pitch(current_rpm)
	update_idle_transition(current_rpm, camera_volume)


func update_gear_sound() -> void:
	active_gear = car.current_gear

	var sample_index: int = 3

	match active_gear:
		1:
			sample_index = 3 # E1-4000
		2:
			sample_index = 4 # E1-5000
		3:
			sample_index = 5 # E1-6000
		4:
			sample_index = 6 # E1-7000
		5:
			sample_index = 7 # E1-8000
		_:
			sample_index = 3 # E1-4000

	sample_rpm = samples[sample_index]["rpm"]

	engine_player.stop()
	engine_player.stream = samples[sample_index]["sound"]
	engine_player.play()


func update_pitch(current_rpm: float) -> void:
	engine_player.pitch_scale = current_rpm / sample_rpm


func update_idle_transition(
	current_rpm: float,
	camera_volume: float
) -> void:
	var blend: float = inverse_lerp(
		IDLE_FADE_START,
		IDLE_FADE_END,
		current_rpm
	)

	blend = clampf(blend, 0.0, 1.0)

	idle_player.volume_db = linear_to_db(
		maxf((1.0 - blend) * camera_volume, 0.001)
	)

	engine_player.volume_db = linear_to_db(
		maxf(blend * 0.5 * camera_volume, 0.001)
	)


# --------------------------------------------------
# TYRE AUDIO
# --------------------------------------------------

func update_tyre_audio(
	delta: float,
	camera_volume: float
) -> void:
	if skid_player == null or wheelspin_player == null or grass_player == null:
		return

	var on_grass: bool = false

	if skid_marks != null:
		on_grass = skid_marks.is_on_grass(car.global_position)

	var drifting: bool = car.drive_state == car.DriveState.DRIFT
	var wheelspinning: bool = car.drive_state == car.DriveState.WHEELSPIN

	var skid_target: float = 0.0
	var wheelspin_target: float = 0.0
	var grass_target: float = 0.0

	if on_grass:
		if drifting or wheelspinning:
			grass_target = grass_volume
	elif drifting:
		skid_target = skid_volume
	elif wheelspinning:
		wheelspin_target = wheelspin_volume

	update_drift_pitch(delta)
	update_wheelspin_pitch(delta)

	update_tyre_player(
		skid_player,
		skid_target * camera_volume,
		delta
	)

	update_tyre_player(
		wheelspin_player,
		wheelspin_target * camera_volume,
		delta
	)

	update_tyre_player(
		grass_player,
		grass_target * camera_volume,
		delta
	)


func update_drift_pitch(delta: float) -> void:
	var max_speed: float = maxf(drift_pitch_max_speed, 0.01)

	var speed_ratio: float = clampf(
		car.velocity.length() / max_speed,
		0.0,
		1.0
	)

	var target_pitch: float = lerpf(
		drift_min_pitch,
		drift_max_pitch,
		speed_ratio
	)

	skid_player.pitch_scale = move_toward(
		skid_player.pitch_scale,
		target_pitch,
		drift_pitch_response * delta
	)


func update_wheelspin_pitch(delta: float) -> void:
	var max_rpm: float = maxf(wheelspin_pitch_max_rpm, 1.0)

	var rpm_ratio: float = clampf(
		car.display_rpm / max_rpm,
		0.0,
		1.0
	)

	var target_pitch: float = lerpf(
		wheelspin_min_pitch,
		wheelspin_max_pitch,
		rpm_ratio
	)

	wheelspin_player.pitch_scale = move_toward(
		wheelspin_player.pitch_scale,
		target_pitch,
		wheelspin_pitch_response * delta
	)


func update_tyre_player(
	player: AudioStreamPlayer,
	target_volume: float,
	delta: float
) -> void:
	if target_volume > 0.0 and not player.playing:
		player.play()

	var current_volume: float = db_to_linear(player.volume_db)

	var new_volume: float = move_toward(
		current_volume,
		target_volume,
		skid_fade_speed * delta
	)

	player.volume_db = linear_to_db(
		maxf(new_volume, 0.0001)
	)


# --------------------------------------------------
# CAMERA VOLUME
# --------------------------------------------------

func get_camera_volume() -> float:
	match camera_controller.camera_mode:
		0:
			return world_fixed_volume
		1:
			return car_locked_volume
		2:
			return chase_volume
		3:
			return world_overview_volume
		_:
			return 1.0
