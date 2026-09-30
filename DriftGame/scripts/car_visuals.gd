extends Node


# ================================================================
# WHEELS
# ================================================================

@export_category("Visual Wheels")

@export var wheel_steer_angle: float = 25.0
@export var wheel_steer_speed: float = 10.0
@export var wheel_radius: float = 0.30


@onready var front_left_wheel: Node3D = (
	$"../SportsCar2/SportsCar_FrontLeftWheel"
)

@onready var front_right_wheel: Node3D = (
	$"../SportsCar2/SportsCar_FrontRightWheel"
)

@onready var back_wheels: Node3D = (
	$"../SportsCar2/SportsCar_BackWheels"
)


var wheel_spin: float = 0.0


# ================================================================
# UPDATE WHEELS
# ================================================================

func update_wheels(
	delta: float,
	steering_input: float,
	forward_speed: float
) -> void:
	update_wheel_steering(
		delta,
		steering_input
	)

	update_wheel_rotation(
		delta,
		forward_speed
	)


# ================================================================
# WHEEL STEERING
# ================================================================

func update_wheel_steering(
	delta: float,
	steering_input: float
) -> void:
	var target_angle: float = deg_to_rad(
		-wheel_steer_angle * steering_input
	)

	front_left_wheel.rotation.y = lerp_angle(
		front_left_wheel.rotation.y,
		target_angle,
		clampf(
			wheel_steer_speed * delta,
			0.0,
			1.0
		)
	)

	front_right_wheel.rotation.y = lerp_angle(
		front_right_wheel.rotation.y,
		target_angle,
		clampf(
			wheel_steer_speed * delta,
			0.0,
			1.0
		)
	)


# ================================================================
# WHEEL ROTATION
# ================================================================

func update_wheel_rotation(
	delta: float,
	forward_speed: float
) -> void:
	wheel_spin += (
		forward_speed
		/ wheel_radius
		* delta
	)

	front_left_wheel.rotation.x = wheel_spin
	front_right_wheel.rotation.x = wheel_spin
	back_wheels.rotation.x = wheel_spin

# ================================================================
# LIGHTS
# ================================================================

@onready var brake_light_left: OmniLight3D = (
	$"../SportsCar2/BrakeLightLeft"
)

@onready var brake_light_right: OmniLight3D = (
	$"../SportsCar2/BrakeLightRight"
)

# ================================================================
# READY
# ================================================================

func _ready() -> void:
	set_brake_lights(false)
	
# ================================================================
# BRAKE LIGHTS
# ================================================================

func set_brake_lights(enabled: bool) -> void:
	brake_light_left.visible = enabled
	brake_light_right.visible = enabled
	
	
