extends CharacterBody3D


# ================================================================
# DRIVE STATES
# ================================================================

enum DriveState {
	NORMAL,
	DRIFT,
	WHEELSPIN
}


# ================================================================
# COMPONENTS
# ================================================================

@onready var car_visuals: Node = $CarVisuals
@onready var car_effects: Node = $CarEffects


# ================================================================
# ENGINE
# ================================================================

@export_category("Engine")

@export var acceleration: float = 12.0
@export var reverse_acceleration: float = 7.0

@export var max_speed: float = 14.0
@export var max_reverse_speed: float = 6.0

@export var friction: float = 7.0
@export var brake_force: float = 25.0


# ================================================================
# NORMAL STEERING
# ================================================================

@export_category("Normal Steering")

@export var low_speed_steering: float = 2.4
@export var high_speed_steering: float = 1.15

@export var min_steering_speed: float = 0.5
@export var normal_grip: float = 8.0


# ================================================================
# DRIFTING
# ================================================================

@export_category("Drifting")

@export var drift_entry_speed: float = 5.0
@export var drift_entry_steering: float = 0.25

@export var drift_grip: float = 1.5
@export var drift_tightening_grip: float = 2.5

@export var drift_steering: float = 1.3
@export var drift_throttle_rotation: float = 0.45

@export var drift_exit_angle: float = 8.0
@export var drift_exit_speed: float = 2.2

@export var handbrake_drift_slowdown: float = 6.0
@export var handbrake_drift_grip: float = 0.7


# ================================================================
# WHEELSPIN
# ================================================================

@export_category("Wheelspin")

@export var wheelspin_entry_rpm: float = 5000.0
@export var wheelspin_exit_rpm: float = 3500.0

@export var wheelspin_grip: float = 2.0
@export var wheelspin_steering: float = 1.1

@export var chain_drift_angle: float = 12.0
@export var wheelspin_min_throttle: float = 0.4


# ================================================================
# LAUNCH
# ================================================================

@export_category("Launch")

@export var launch_hold_max_speed: float = 0.8

@export var launch_min_rpm: float = 4500.0
@export var launch_target_rpm: float = 7000.0

@export var launch_acceleration_multiplier: float = 1.35
@export var launch_wheelspin_time: float = 1.0


# ================================================================
# ENGINE RPM
# ================================================================

@export_category("Engine RPM")

@export var idle_rpm: float = 900.0
@export var max_rpm: float = 8000.0
@export var rpm_response: float = 6.0

@export var throttle_rpm_boost: float = 1200.0
@export var drift_rpm_boost: float = 800.0
@export var wheelspin_rpm_boost: float = 1400.0


# ================================================================
# STATE
# ================================================================

var drive_state: int = DriveState.NORMAL
var drift_direction: float = 0.0

var rpm: float = 900.0
var display_rpm: float = 900.0
var current_gear: int = 0
var neutral_timer: float = 0.0

var launch_charging: bool = false

var wheelspin_from_launch: bool = false
var wheelspin_timer: float = 0.0

var debug_timer: float = 0.0


# ================================================================
# PHYSICS PROCESS
# ================================================================

func _physics_process(delta: float) -> void:
	var forward: Vector3 = get_forward()

	var accelerate_input: float = Input.get_action_strength(
		"accelerate"
	)

	var reverse_input: float = Input.get_action_strength(
		"brake"
	)

	var steering_input: float = Input.get_axis(
		"steer_left",
		"steer_right"
	)

	var handbrake: bool = Input.is_action_pressed(
		"handbrake"
	)

	var handbrake_released: bool = Input.is_action_just_released(
		"handbrake"
	)

	var normal_brake: bool = Input.is_action_pressed(
		"normal_brake"
	)

	var horizontal_velocity: Vector3 = get_horizontal_velocity()

	var speed: float = horizontal_velocity.length()

	var forward_speed: float = horizontal_velocity.dot(
		forward
	)

	# ------------------------------------------------
	# THROTTLE / BRAKE / REVERSE
	# ------------------------------------------------

	var down_braking: bool = (
		reverse_input > 0.0
		and forward_speed > 0.5
	)

	var reversing: bool = (
		reverse_input > 0.0
		and forward_speed <= 0.5
	)

	var throttle: float = accelerate_input

	if reversing:
		throttle = -reverse_input


	# ------------------------------------------------
	# STATIONARY HANDBRAKE / LAUNCH CHARGING
	# ------------------------------------------------

	launch_charging = (
		drive_state == DriveState.NORMAL
		and handbrake
		and speed < launch_hold_max_speed
		and throttle > 0.0
	)

	if launch_charging:
		horizontal_velocity = horizontal_velocity.move_toward(
			Vector3.ZERO,
			friction * 2.0 * delta
		)

	elif throttle > 0.0:
		var acceleration_amount: float = acceleration

		if (
			drive_state == DriveState.WHEELSPIN
			and wheelspin_from_launch
		):
			acceleration_amount *= (
				launch_acceleration_multiplier
			)

		horizontal_velocity += (
			forward
			* acceleration_amount
			* throttle
			* delta
		)

	elif throttle < 0.0:
		horizontal_velocity += (
			forward
			* reverse_acceleration
			* throttle
			* delta
		)

	else:
		horizontal_velocity = horizontal_velocity.move_toward(
			Vector3.ZERO,
			friction * delta
		)


	# ------------------------------------------------
	# SPEED LIMIT
	# ------------------------------------------------

	if horizontal_velocity.length() > max_speed:
		horizontal_velocity = (
			horizontal_velocity.normalized()
			* max_speed
		)

	speed = horizontal_velocity.length()

	forward = get_forward()

	forward_speed = horizontal_velocity.dot(
		forward
	)

	if forward_speed < -max_reverse_speed:
		horizontal_velocity = (
			-forward
			* max_reverse_speed
		)


	# ------------------------------------------------
	# NORMAL BRAKE
	# ------------------------------------------------

	if normal_brake or down_braking:
		horizontal_velocity = horizontal_velocity.move_toward(
			Vector3.ZERO,
			brake_force * delta
		)


	# ------------------------------------------------
	# BRAKE LIGHTS
	# ------------------------------------------------

	var brake_lights_on: bool = (
		normal_brake
		or down_braking
		or handbrake
	)

	car_visuals.set_brake_lights(
		brake_lights_on
	)


	# ------------------------------------------------
	# HANDBRAKE LAUNCH
	# ------------------------------------------------

	if (
		drive_state == DriveState.NORMAL
		and handbrake_released
		and throttle > wheelspin_min_throttle
		and rpm >= launch_min_rpm
		and speed < launch_hold_max_speed
	):
		enter_launch_wheelspin()


	# ------------------------------------------------
	# ENTER DRIFT
	# ------------------------------------------------

	if drive_state == DriveState.NORMAL:
		if (
			handbrake
			and speed > drift_entry_speed
			and abs(steering_input) > drift_entry_steering
		):
			enter_drift(
				steering_input
			)


	# ------------------------------------------------
	# CURRENT DRIVING STATE
	# ------------------------------------------------

	if drive_state == DriveState.NORMAL:
		horizontal_velocity = handle_normal_driving(
			delta,
			steering_input,
			forward_speed,
			horizontal_velocity
		)

	elif drive_state == DriveState.DRIFT:
		horizontal_velocity = handle_drift(
			delta,
			throttle,
			steering_input,
			handbrake,
			horizontal_velocity
		)

	elif drive_state == DriveState.WHEELSPIN:
		horizontal_velocity = handle_wheelspin(
			delta,
			throttle,
			steering_input,
			horizontal_velocity
		)


	# ------------------------------------------------
	# RPM
	# ------------------------------------------------

	update_rpm(
		delta,
		throttle,
		handbrake
	)
	
	if throttle > 0.0 and drive_state == DriveState.NORMAL:
		var rpm_climb_rate: float = 10000.0

		if current_gear == 2:
			rpm_climb_rate = 3500.0
		elif current_gear == 3:
			rpm_climb_rate = 2500.0
		elif current_gear == 4:
			rpm_climb_rate = 1800.0
		elif current_gear == 5:
			rpm_climb_rate = 1200.0

		display_rpm = move_toward(display_rpm, max_rpm, rpm_climb_rate * delta)
	else:
		if drive_state == DriveState.NORMAL and throttle <= 0.0:
			display_rpm = move_toward(display_rpm, idle_rpm, 1800.0 * delta)
		else:
			display_rpm = move_toward(display_rpm, rpm, 3000.0 * delta)
	
	if drive_state == DriveState.NORMAL:
		if throttle < 0.0:
			current_gear = -1
			neutral_timer = 0.0

		elif throttle > 0.0:
			if current_gear < 1:
				current_gear = 1

			# Upshift one gear when accelerating at redline.
			if current_gear < 5 and display_rpm >= 6500.0 and speed > 0.5:
				current_gear += 1
				display_rpm = 3500.0

			neutral_timer = 0.0

		elif speed < 0.2:
			neutral_timer += delta

			if neutral_timer >= 2.0:
				current_gear = 0

		else:
			neutral_timer = 0.0

			# Downshift one gear when coasting below 5,000 RPM.
			if current_gear > 1 and display_rpm <= 5000.0:
				current_gear -= 1
				display_rpm = 6000.0


	# ------------------------------------------------
	# APPLY VELOCITY
	# ------------------------------------------------

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	velocity.y = 0.0

	move_and_slide()


	# ------------------------------------------------
	# VISUALS
	# ------------------------------------------------

	var visual_forward_speed: float = (
		get_horizontal_velocity().dot(
			get_forward()
		)
	)

	car_visuals.update_wheels(
		delta,
		steering_input,
		visual_forward_speed
	)


	# ------------------------------------------------
	# EFFECTS
	# ------------------------------------------------

	var is_skidding: bool = (
		drive_state == DriveState.DRIFT
		or drive_state == DriveState.WHEELSPIN
	)

	var skid_intensity: float = (
		get_skid_intensity()
	)

	car_effects.update_effects(
		is_skidding,
		skid_intensity
	)


	# ------------------------------------------------
	# DEBUG
	# ------------------------------------------------

	debug_timer += delta

	if debug_timer >= 0.25:
		debug_timer = 0.0


# ================================================================
# NORMAL DRIVING
# ================================================================

func handle_normal_driving(
	delta: float,
	steering_input: float,
	forward_speed: float,
	horizontal_velocity: Vector3
) -> Vector3:
	var speed: float = horizontal_velocity.length()

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

		rotate_y(
			-steering_input
			* steering
			* movement_direction
			* delta
		)

	return apply_grip(
		horizontal_velocity,
		normal_grip,
		delta
	)


# ================================================================
# DRIFT
# ================================================================

func handle_drift(
	delta: float,
	throttle: float,
	steering_input: float,
	handbrake: bool,
	horizontal_velocity: Vector3
) -> Vector3:
	var speed: float = horizontal_velocity.length()

	# Throttle keeps rotating the car through the drift.
	rotate_y(
		-drift_direction
		* drift_throttle_rotation
		* maxf(throttle, 0.0)
		* delta
	)

	# Steering still affects the car during the drift.
	rotate_y(
		-steering_input
		* drift_steering
		* delta
	)

	var current_drift_grip: float = drift_grip

	# Steering into the drift tightens the radius.
	if (
		steering_input != 0.0
		and sign(steering_input) == drift_direction
	):
		current_drift_grip += (
			abs(steering_input)
			* drift_tightening_grip
		)

	# Handbrake reduces grip and removes speed.
	if handbrake:
		current_drift_grip = handbrake_drift_grip

		var handbrake_force: float = (
			handbrake_drift_slowdown
			+ acceleration * maxf(throttle, 0.0)
		)

		horizontal_velocity = horizontal_velocity.move_toward(
			Vector3.ZERO,
			handbrake_force * delta
		)

	horizontal_velocity = apply_grip(
		horizontal_velocity,
		current_drift_grip,
		delta
	)

	var drift_angle: float = get_drift_angle(
		horizontal_velocity
	)

	if speed < drift_exit_speed:
		enter_normal()
		return horizontal_velocity

	if abs(drift_angle) < drift_exit_angle:
		if (
			throttle > wheelspin_min_throttle
			and rpm > wheelspin_entry_rpm
		):
			enter_wheelspin()
		else:
			enter_normal()

	return horizontal_velocity


# ================================================================
# WHEELSPIN
# ================================================================

func handle_wheelspin(
	delta: float,
	throttle: float,
	steering_input: float,
	horizontal_velocity: Vector3
) -> Vector3:
	if wheelspin_timer > 0.0:
		wheelspin_timer -= delta

	rotate_y(
		-steering_input
		* wheelspin_steering
		* delta
	)

	horizontal_velocity = apply_grip(
		horizontal_velocity,
		wheelspin_grip,
		delta
	)

	var speed: float = horizontal_velocity.length()

	var drift_angle: float = get_drift_angle(
		horizontal_velocity
	)

	# Wheelspin can naturally transition into a drift.
	if (
		speed > drift_entry_speed
		and abs(drift_angle) > chain_drift_angle
	):
		enter_drift_from_angle(
			drift_angle
		)

		return horizontal_velocity

	# Launch wheelspin gets a guaranteed minimum duration.
	if wheelspin_from_launch:
		if wheelspin_timer > 0.0:
			return horizontal_velocity

		wheelspin_from_launch = false

	# Exit wheelspin once revs or throttle fall.
	if (
		rpm < wheelspin_exit_rpm
		or throttle < wheelspin_min_throttle
	):
		enter_normal()

	return horizontal_velocity


# ================================================================
# GRIP
# ================================================================

func apply_grip(
	horizontal_velocity: Vector3,
	grip: float,
	delta: float
) -> Vector3:
	if horizontal_velocity.length() <= 0.0:
		return horizontal_velocity

	var forward: Vector3 = get_forward()

	var movement_sign: float = 1.0

	if horizontal_velocity.dot(forward) < 0.0:
		movement_sign = -1.0

	var target_velocity: Vector3 = (
		forward
		* horizontal_velocity.length()
		* movement_sign
	)

	return horizontal_velocity.lerp(
		target_velocity,
		clampf(
			grip * delta,
			0.0,
			1.0
		)
	)


# ================================================================
# DRIFT ANGLE
# ================================================================

func get_drift_angle(
	horizontal_velocity: Vector3
) -> float:
	if horizontal_velocity.length() < 0.01:
		return 0.0

	var forward: Vector3 = get_forward()

	var movement_direction: Vector3 = (
		horizontal_velocity.normalized()
	)

	var forward_2d: Vector2 = Vector2(
		forward.x,
		forward.z
	)

	var movement_2d: Vector2 = Vector2(
		movement_direction.x,
		movement_direction.z
	)

	return rad_to_deg(
		forward_2d.angle_to(
			movement_2d
		)
	)


# ================================================================
# RPM
# ================================================================

func update_rpm(
	delta: float,
	throttle: float,
	handbrake: bool
) -> void:
	var speed: float = get_horizontal_velocity().length()

	var speed_ratio: float = clampf(
		speed / max_speed,
		0.0,
		1.0
	)

	var target_rpm: float = lerpf(
		idle_rpm,
		max_rpm - 1500.0,
		speed_ratio
	)

	target_rpm += (
		maxf(throttle, 0.0)
		* throttle_rpm_boost
	)

	# Stationary handbrake lets the engine rev freely.
	if launch_charging and handbrake:
		target_rpm = maxf(
			target_rpm,
			launch_target_rpm
		)

	if drive_state == DriveState.DRIFT:
		target_rpm += (
			maxf(throttle, 0.0)
			* drift_rpm_boost
		)

	elif drive_state == DriveState.WHEELSPIN:
		target_rpm += (
			maxf(throttle, 0.0)
			* wheelspin_rpm_boost
		)

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


# ================================================================
# STATE CHANGES
# ================================================================

func enter_drift(
	steering_input: float
) -> void:
	drive_state = DriveState.DRIFT
	drift_direction = sign(steering_input)

	wheelspin_from_launch = false
	wheelspin_timer = 0.0


func enter_drift_from_angle(
	drift_angle: float
) -> void:
	drive_state = DriveState.DRIFT

	if drift_angle > 0.0:
		drift_direction = 1.0
	else:
		drift_direction = -1.0

	wheelspin_from_launch = false
	wheelspin_timer = 0.0


func enter_wheelspin() -> void:
	drive_state = DriveState.WHEELSPIN

	wheelspin_from_launch = false
	wheelspin_timer = 0.0


func enter_launch_wheelspin() -> void:
	drive_state = DriveState.WHEELSPIN

	wheelspin_from_launch = true
	wheelspin_timer = launch_wheelspin_time


func enter_normal() -> void:
	drive_state = DriveState.NORMAL
	drift_direction = 0.0

	wheelspin_from_launch = false
	wheelspin_timer = 0.0


# ================================================================
# HELPERS
# ================================================================

func get_forward() -> Vector3:
	var forward: Vector3 = global_transform.basis.z

	forward.y = 0.0

	return forward.normalized()


func get_horizontal_velocity() -> Vector3:
	return Vector3(
		velocity.x,
		0.0,
		velocity.z
	)
	
func get_skid_intensity() -> float:
	var rpm_ratio: float = clampf(
		inverse_lerp(
			idle_rpm,
			max_rpm,
			rpm
		),
		0.0,
		1.0
	)

	if drive_state == DriveState.DRIFT:
		var drift_angle: float = abs(
			get_drift_angle(
				get_horizontal_velocity()
			)
		)

		var drift_ratio: float = clampf(
			inverse_lerp(
				drift_exit_angle,
				45.0,
				drift_angle
			),
			0.0,
			1.0
		)

		return clampf(
			drift_ratio * 0.8
			+ rpm_ratio * 0.2,
			0.0,
			1.0
		)

	if drive_state == DriveState.WHEELSPIN:
		var speed: float = (
			get_horizontal_velocity().length()
		)

		var speed_ratio: float = clampf(
			inverse_lerp(
				0.0,
				max_speed,
				speed
			),
			0.0,
			1.0
		)

		var low_speed_intensity: float = (
			1.0 - speed_ratio
		)

		return clampf(
			low_speed_intensity * 0.8
			+ rpm_ratio * 0.2,
			0.0,
			1.0
		)

	return 0.0


func get_state_name() -> String:
	match drive_state:
		DriveState.NORMAL:
			return "NORMAL"

		DriveState.DRIFT:
			return "DRIFT"

		DriveState.WHEELSPIN:
			if wheelspin_from_launch:
				return "WHEELSPIN - LAUNCH"

			return "WHEELSPIN"

	return "UNKNOWN"
