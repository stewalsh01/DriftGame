extends RefCounted


# ================================================================
# ENGINE SOUND SETTINGS
# ================================================================

const ENGINE_1 := {
	"name": "Engine 1",

	"idle_sound": preload(
		"res://DriftGame/assets/audio/engine/engine_1/E1-0ideal.wav"
	),

	"samples": [
		{
			"rpm": 1000.0,
			"sound": preload(
				"res://DriftGame/assets/audio/engine/engine_1/E1-1000.wav"
			)
		},
		{
			"rpm": 2000.0,
			"sound": preload(
				"res://DriftGame/assets/audio/engine/engine_1/E1-2000.wav"
			)
		},
		{
			"rpm": 3000.0,
			"sound": preload(
				"res://DriftGame/assets/audio/engine/engine_1/E1-3000.wav"
			)
		},
		{
			"rpm": 4000.0,
			"sound": preload(
				"res://DriftGame/assets/audio/engine/engine_1/E1-4000.wav"
			)
		},
		{
			"rpm": 5000.0,
			"sound": preload(
				"res://DriftGame/assets/audio/engine/engine_1/E1-5000.wav"
			)
		},
		{
			"rpm": 6000.0,
			"sound": preload(
				"res://DriftGame/assets/audio/engine/engine_1/E1-6000.wav"
			)
		},
		{
			"rpm": 7000.0,
			"sound": preload(
				"res://DriftGame/assets/audio/engine/engine_1/E1-7000.wav"
			)
		},
		{
			"rpm": 8000.0,
			"sound": preload(
				"res://DriftGame/assets/audio/engine/engine_1/E1-8000.wav"
			)
		}
	],

	"redline_sound": preload(
		"res://DriftGame/assets/audio/engine/engine_1/E1-9000redline.wav"
	),

	"redline_start_rpm": 7850.0
}


# ================================================================
# GET ENGINE SOUND
# ================================================================

static func get_engine(engine_number: int) -> Dictionary:
	match engine_number:
		_:
			return ENGINE_1
