extends Node


const EngineSoundSettings = preload(
	"res://DriftGame/scripts/engine_sound_settings.gd"
)


@onready var car: CharacterBody3D = get_parent()


var idle_player: AudioStreamPlayer
var engine_player: AudioStreamPlayer

var engine_config: Dictionary
var samples: Array

var active_gear: int = -1
var sample_rpm: float = 2000.0


const IDLE_FADE_START: float = 1000.0
const IDLE_FADE_END: float = 1200.0


func setup() -> void:
	var engine_number: int = car.car_config["engine_sound"]

	engine_config = EngineSoundSettings.get_engine(engine_number)
	samples = engine_config["samples"]

	idle_player = AudioStreamPlayer.new()
	engine_player = AudioStreamPlayer.new()

	add_child(idle_player)
	add_child(engine_player)

	idle_player.stream = engine_config["idle_sound"]

	idle_player.play()

	update_gear_sound()


func _process(_delta: float) -> void:
	if idle_player == null or engine_player == null:
		return

	var current_rpm: float = car.display_rpm

	if car.current_gear != active_gear:
		update_gear_sound()

	update_pitch(current_rpm)
	update_idle_transition(current_rpm)


func update_gear_sound() -> void:
	active_gear = car.current_gear

	var sample_index: int = 1

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


func update_idle_transition(current_rpm: float) -> void:
	var blend: float = inverse_lerp(
		IDLE_FADE_START,
		IDLE_FADE_END,
		current_rpm
	)

	blend = clampf(blend, 0.0, 1.0)

	idle_player.volume_db = linear_to_db(
		maxf(1.0 - blend, 0.001)
	)

	engine_player.volume_db = linear_to_db(
		maxf(blend * 0.5, 0.001)
	)
