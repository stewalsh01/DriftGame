extends RefCounted


# ================================================================
# SHARED SETTINGS
# ================================================================

const SHARED := {
	# Movement
	"friction": 7.0,
	"coast_deceleration": 2.0,

	# Steering
	"low_speed_steering": 2.2,
	"high_speed_steering": 1.15,
	"min_steering_speed": 0.5,
	"normal_grip": 8.0,

	# Drifting
	"drift_entry_speed": 5.0,
	"drift_entry_steering": 0.25,
	"drift_grip": 1.5,
	"drift_tightening_grip": 2.5,
	"drift_steering": 1.3,
	"drift_throttle_rotation": 0.45,
	"drift_exit_angle": 8.0,
	"drift_exit_speed": 2.2,
	"handbrake_drift_grip": 0.7,

	# Wheelspin
	"wheelspin_entry_rpm": 5000.0,
	"wheelspin_exit_rpm": 3500.0,
	"wheelspin_grip": 2.0,
	"wheelspin_steering": 1.1,
	"chain_drift_angle": 12.0,
	"wheelspin_min_throttle": 0.4,
	"wheelspin_max_time": 1.5,

	# Launch
	"launch_hold_max_speed": 0.8,
	"launch_min_rpm": 4500.0,
	"launch_target_rpm": 8000.0,
	"launch_acceleration_multiplier": 1.35,
	"launch_wheelspin_time": 3.5,

	# RPM
	"idle_rpm": 900.0,
	"max_rpm": 8000.0,
	"rpm_response": 6.0,
	"throttle_rpm_boost": 1200.0,
	"drift_rpm_boost": 800.0,
	"wheelspin_rpm_boost": 1400.0
}


# ================================================================
# CAR 1
# ================================================================

const CAR_1 := {
	"name": "Car 1",
	"engine_sound": 1,
	
	"brake_force": 16.0,
	"high_speed_brake_force": 10.0,
	
	"handbrake_force": 7.0,
	"high_speed_handbrake_force": 4.0,

	"acceleration": 5.0,
	"reverse_acceleration": 7.0,

	# Keep 5 values for gears 1-5.
	"gear_acceleration": [
		7.0,
		5.0,
		3.5,
		2.5,
		1.5
	],

	"gear_max_speed": [
		5.0,
		10.5,
		14.5,
		18.5,
		22.5
	],

	"max_speed": 14.0,
	"max_reverse_speed": 6.0
}


# ================================================================
# CAR 2
# ================================================================

const CAR_2 := {
	"name": "Car 2 - Test",
	"engine_sound": 1,
	
	"brake_force": 16.0,
	"high_speed_brake_force": 10.0,
	
	"handbrake_force": 7.0,
	"high_speed_handbrake_force": 4.0,

	"acceleration": 5.0,
	"reverse_acceleration": 7.0,

	# Keep 5 values for gears 1-5.
	"gear_acceleration": [
		12.0,
		10.0,
		8.0,
		6.0,
		5.0
	],

	"gear_max_speed": [
		7.0,
		14.0,
		20.0,
		26.0,
		32.0
	],

	"max_speed": 14.0,
	"max_reverse_speed": 6.0
}


# ================================================================
# GET CAR SETTINGS
# ================================================================

static func get_car(car_number: int) -> Dictionary:
	var car: Dictionary

	match car_number:
		2:
			car = CAR_2.duplicate(true)

		_:
			car = CAR_1.duplicate(true)

	car.merge(SHARED)

	return car
