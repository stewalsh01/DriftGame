extends RefCounted


# ================================================================
# CAR 1
# ================================================================

const CAR_1 := {
	"model_node": "SportsCar2",
	"steer_axis": "y",

	"front_left_steer": "SportsCar_FrontLeftWheel",
	"front_right_steer": "SportsCar_FrontRightWheel",

	"front_left_spin": [
		"SportsCar_FrontLeftWheel"
	],

	"front_right_spin": [
		"SportsCar_FrontRightWheel"
	],

	"rear_left_spin": [
		"SportsCar_BackWheels"
	],

	"rear_right_spin": [
		"SportsCar_BackWheels"
	],
	
	"brake_lights": [
		"BrakeLightLeft",
		"BrakeLightRight"
	],

	"headlights": [
		"HeadlightLeft",
		"HeadlightRight"
	]
}


# ================================================================
# CAR 2
# ================================================================

const CAR_2 := {
	"model_node": "Car2",
	"steer_axis": "z",

	"front_left_steer": "FL",
	"front_right_steer": "FR",

	"front_left_spin": [
		"FL_Wheel_Rims_0",
		"FL_Wheel_Plastic_0"
	],

	"front_right_spin": [
		"FR_Wheel_Rims_0",
		"FR_Wheel_Plastic_0"
	],

	"rear_left_spin": [
		"BL"
	],

	"rear_right_spin": [
		"BR"
	],

	"brake_lights": [
		"BrakeLightLeft",
		"BrakeLightRight"
	],

	"headlights": [
		"HeadlightLeft",
		"HeadlightRight"
	]
}


# ================================================================
# CAR 3 - SUBARU BRZ
# ================================================================


const CAR_3 := {
	"model_node": "Subaru_BRZ_Optimised",
	"steer_axis": "z",

	"front_left_steer": "FL_Steer",
	"front_right_steer": "FR_Steer",

	"front_left_spin": ["FL_Pivot"],
	"front_right_spin": ["FR_Pivot"],
	"rear_left_spin": ["BL_Pivot"],
	"rear_right_spin": ["BR_Pivot"],

	"brake_lights": [
		"BrakeLightLeft",
		"BrakeLightRight"
	],
	"headlights": []
}


# ================================================================
# GET VISUAL SETTINGS
# ================================================================

static func get_car(car_number: int) -> Dictionary:
	match car_number:
		2:
			return CAR_2.duplicate(true)
		3:
			return CAR_3.duplicate(true)
		_:
			return CAR_1.duplicate(true)
