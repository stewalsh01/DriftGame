extends CharacterBody2D


enum DriveState {
	NORMAL,
	DRIFT,
	WHEELSPIN
}


@export_category("Engine")
@export var acceleration: float = 500.0
@export var reverse_acceleration: float = 300.0
@export var max_speed: float = 500.0
@export var max_reverse_speed: float = 220.0
@export var friction: float = 250.0


@export_category("Normal Steering")
@export var low_speed_steering: float = 2.4
@export var high_speed_steering: float = 1.15
@export var min_steering_speed: float = 15.0
@export var normal_grip: float = 8.0


@export_category("Drifting")
@export var drift_entry_speed: float = 180.0
@export var drift_entry_steering: float = 0.25

@export var drift_grip: float = 1.5
@export var drift_tightening_grip: float = 2.5
@export var drift_steering: float = 1.3
@export var drift_throttle_rotation: float = 0.45

@export var drift_exit_angle: float = 8.0
@export var drift_exit_speed: float = 80.0

@export var handbrake_drift_slowdown: float = 220.0
@export var handbrake_drift_grip: float = 0.7


@export_category("Wheelspin")
@export var wheelspin_entry_rpm: float = 5000.0
@export var wheelspin_exit_rpm: float = 3500.0

@export var wheelspin_grip: float = 2.0
@export var wheelspin_steering: float = 1.1

@export var chain_drift_angle: float = 12.0
@export var wheelspin_min_throttle: float = 0.4


@export_category("Launch")
@export var launch_hold_max_speed: float = 30.0
@export var launch_min_rpm: float = 4500.0
@export var launch_target_rpm: float = 7000.0

@export var launch_acceleration_multiplier: float = 1.35
@export var launch_wheelspin_time: float = 1.0


@export_category("Engine RPM")
@export var idle_rpm: float = 900.0
@export var max_rpm: float = 8000.0
@export var rpm_response: float = 6.0

@export var throttle_rpm_boost: float = 1200.0
@export var drift_rpm_boost: float = 800.0
@export var wheelspin_rpm_boost: float = 1400.0


var drive_state: int = DriveState.NORMAL
var drift_direction: float = 0.0

var rpm: float = 900.0

var launch_charging: bool = false
var wheelspin_from_launch: bool = false
var wheelspin_timer: float = 0.0


func _physics_process(delta: float) -> void:
	var forward: Vector2 = Vector2.UP.rotated(rotation)

	var throttle: float = Input.get_axis(
		"brake",
		"accelerate"
	)

	var steering_input: float = Input.get_axis(
		"steer_left",
		"steer_right"
	)

	var handbrake: bool = Input.is_action_pressed("handbrake")
	var handbrake_released: bool = Input.is_action_just_released("handbrake")

	var speed: float = velocity.length()
	var forward_speed: float = velocity.dot(forward)

	# --------------------------------
	# LAUNCH CHARGING
	# --------------------------------

	launch_charging = (
		drive_state == DriveState.NORMAL
		and handbrake
		and speed < launch_hold_max_speed
		and throttle > 0.0
	)

	# --------------------------------
	# ENGINE
	# --------------------------------

	if launch_charging:
		velocity = velocity.move_toward(
			Vector2.ZERO,
			friction * 2.0 * delta
		)

	elif throttle > 0.0:
		var acceleration_amount: float = acceleration

		if (
			drive_state == DriveState.WHEELSPIN
			and wheelspin_from_launch
		):
			acceleration_amount *= launch_acceleration_multiplier

		velocity += (
			forward
			* acceleration_amount
			* throttle
			* delta
		)

	elif throttle < 0.0:
		velocity += (
			forward
			* reverse_acceleration
			* throttle
			* delta
		)

	else:
		velocity = velocity.move_toward(
			Vector2.ZERO,
			friction * delta
		)

	# --------------------------------
	# SPEED LIMIT
	# --------------------------------

	if velocity.length() > max_speed:
		velocity = (
			velocity.normalized()
			* max_speed
		)

	speed = velocity.length()

	forward = Vector2.UP.rotated(rotation)
	forward_speed = velocity.dot(forward)

	# --------------------------------
	# REVERSE SPEED LIMIT
	# --------------------------------

	if forward_speed < -max_reverse_speed:
		velocity = (
			-forward
			* max_reverse_speed
		)

	# --------------------------------
	# LAUNCH FROM STATIONARY
	# --------------------------------

	if (
		drive_state == DriveState.NORMAL
		and handbrake_released
		and throttle > wheelspin_min_throttle
		and rpm >= launch_min_rpm
		and speed < launch_hold_max_speed
	):
		enter_launch_wheelspin()

	# --------------------------------
	# ENTER DRIFT FROM NORMAL
	# --------------------------------

	if drive_state == DriveState.NORMAL:
		if (
			handbrake
			and speed > drift_entry_speed
			and abs(steering_input) > drift_entry_steering
		):
			enter_drift(steering_input)

	# --------------------------------
	# CURRENT DRIVING STATE
	# --------------------------------

	if drive_state == DriveState.NORMAL:
		handle_normal_driving(
			delta,
			steering_input,
			forward_speed
		)

	elif drive_state == DriveState.DRIFT:
		handle_drift(
			delta,
			throttle,
			steering_input
		)

	elif drive_state == DriveState.WHEELSPIN:
		handle_wheelspin(
			delta,
			throttle,
			steering_input
		)

	# --------------------------------
	# RPM
	# --------------------------------

	update_rpm(
		delta,
		throttle,
		handbrake
	)

	move_and_slide()


func handle_normal_driving(
	delta: float,
	steering_input: float,
	forward_speed: float
) -> void:
	var speed: float = velocity.length()

	if speed > min_steering_speed:
		var speed_ratio: float = clampf(
			speed / max_speed,
			0.0,
			1.0
		)

		var steering: float = lerpf(
			low_speed_steering,
			high_speed_steering,
			speed_ratio
		)

		var movement_direction: float = 1.0

		if forward_speed < 0.0:
			movement_direction = -1.0

		rotation += (
			steering_input
			* steering
			* movement_direction
			* delta
		)

	apply_grip(
		normal_grip,
		delta
	)


func handle_drift(
	delta: float,
	throttle: float,
	steering_input: float
) -> void:
	var speed: float = velocity.length()
	var handbrake: bool = Input.is_action_pressed("handbrake")

	rotation += (
		drift_direction
		* drift_throttle_rotation
		* maxf(throttle, 0.0)
		* delta
	)

	rotation += (
		steering_input
		* drift_steering
		* delta
	)

	var current_drift_grip: float = drift_grip

	# Steering further into the drift tightens the circle.
	if (
		steering_input != 0.0
		and sign(steering_input) == drift_direction
	):
		current_drift_grip += (
			abs(steering_input)
			* drift_tightening_grip
		)

	# Handbrake deepens the drift and always scrubs speed.
	if handbrake:
		current_drift_grip = handbrake_drift_grip

		var handbrake_force: float = (
			handbrake_drift_slowdown
			+ acceleration * maxf(throttle, 0.0)
		)

		velocity = velocity.move_toward(
			Vector2.ZERO,
			handbrake_force * delta
		)

	apply_grip(
		current_drift_grip,
		delta
	)

	var drift_angle: float = get_drift_angle()

	if speed < drift_exit_speed:
		enter_normal()
		return

	if abs(drift_angle) < drift_exit_angle:
		if (
			throttle > wheelspin_min_throttle
			and rpm > wheelspin_entry_rpm
		):
			enter_wheelspin()
		else:
			enter_normal()


func handle_wheelspin(
	delta: float,
	throttle: float,
	steering_input: float
) -> void:
	var speed: float = velocity.length()

	wheelspin_timer += delta

	apply_grip(
		wheelspin_grip,
		delta
	)

	if speed > min_steering_speed:
		rotation += (
			steering_input
			* wheelspin_steering
			* delta
		)

	var drift_angle: float = get_drift_angle()

	# --------------------------------
	# CHAIN INTO ANOTHER DRIFT
	# --------------------------------

	if (
		abs(drift_angle) > chain_drift_angle
		and abs(steering_input) > drift_entry_steering
		and throttle > wheelspin_min_throttle
	):
		enter_drift(steering_input)
		return

	# --------------------------------
	# LAUNCH WHEELSPIN
	# --------------------------------

	if wheelspin_from_launch:
		if wheelspin_timer < launch_wheelspin_time:
			return

		if (
			rpm < wheelspin_exit_rpm
			or throttle < wheelspin_min_throttle
		):
			enter_normal()

		return

	# --------------------------------
	# NORMAL DRIFT-EXIT WHEELSPIN
	# --------------------------------

	if (
		rpm < wheelspin_exit_rpm
		or throttle < wheelspin_min_throttle
		or speed < drift_exit_speed
	):
		enter_normal()


func enter_drift(
	steering_input: float
) -> void:
	drive_state = DriveState.DRIFT

	drift_direction = sign(
		steering_input
	)

	wheelspin_from_launch = false
	wheelspin_timer = 0.0


func enter_wheelspin() -> void:
	drive_state = DriveState.WHEELSPIN

	drift_direction = 0.0
	wheelspin_from_launch = false
	wheelspin_timer = 0.0


func enter_launch_wheelspin() -> void:
	drive_state = DriveState.WHEELSPIN

	drift_direction = 0.0
	wheelspin_from_launch = true
	wheelspin_timer = 0.0


func enter_normal() -> void:
	drive_state = DriveState.NORMAL

	drift_direction = 0.0
	wheelspin_from_launch = false
	wheelspin_timer = 0.0


func apply_grip(
	grip_amount: float,
	delta: float
) -> void:
	if velocity.length() <= 0.0:
		return

	var forward: Vector2 = Vector2.UP.rotated(rotation)

	var movement_sign: float = 1.0

	if velocity.dot(forward) < 0.0:
		movement_sign = -1.0

	var target_velocity: Vector2 = (
		forward
		* velocity.length()
		* movement_sign
	)

	velocity = velocity.lerp(
		target_velocity,
		clampf(
			grip_amount * delta,
			0.0,
			1.0
		)
	)


func get_drift_angle() -> float:
	if velocity.length() < 1.0:
		return 0.0

	var forward: Vector2 = Vector2.UP.rotated(rotation)

	var movement_direction: Vector2 = (
		velocity.normalized()
	)

	return rad_to_deg(
		forward.angle_to(
			movement_direction
		)
	)


func update_rpm(
	delta: float,
	throttle: float,
	handbrake: bool
) -> void:
	var speed_ratio: float = clampf(
		velocity.length() / max_speed,
		0.0,
		1.0
	)

	var target_rpm: float = lerpf(
		idle_rpm,
		max_rpm,
		speed_ratio
	)

	if throttle > 0.0:
		target_rpm += (
			throttle
			* throttle_rpm_boost
		)

	if (
		handbrake
		and velocity.length() < launch_hold_max_speed
		and throttle > 0.0
	):
		var launch_rpm: float = lerpf(
			idle_rpm,
			launch_target_rpm,
			throttle
		)

		target_rpm = maxf(
			target_rpm,
			launch_rpm
		)

	if drive_state == DriveState.DRIFT:
		target_rpm += drift_rpm_boost

	elif drive_state == DriveState.WHEELSPIN:
		target_rpm += wheelspin_rpm_boost

	target_rpm = clampf(
		target_rpm,
		idle_rpm,
		max_rpm
	)

	rpm = lerpf(
		rpm,
		target_rpm,
		clampf(
			rpm_response * delta,
			0.0,
			1.0
		)
	)

	print(
		"RPM: ",
		int(rpm),
		" | State: ",
		get_state_name()
	)


func get_state_name() -> String:
	if drive_state == DriveState.NORMAL:
		if launch_charging:
			return "LAUNCH CHARGING"

		return "NORMAL"

	if drive_state == DriveState.DRIFT:
		return "DRIFT"

	if drive_state == DriveState.WHEELSPIN:
		if wheelspin_from_launch:
			return "LAUNCH WHEELSPIN"

		return "WHEELSPIN"

	return "UNKNOWN"
