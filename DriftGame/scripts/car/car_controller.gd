extends CharacterBody3D
const CarSettings = preload("res://DriftGame/scripts/car/car_settings.gd")
var gravity: float = 20.0

@export var selected_car: int = 1
var car_config: Dictionary
@onready var car_1_model: Node3D = $SportsCar2
@onready var car_2_model: Node3D = $Car2

@export_category("Ground Physics")

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
@onready var car_audio: Node = $CarAudio

@onready var front_left: Marker3D = $FrontLeftTyre
@onready var front_right: Marker3D = $FrontRightTyre
@onready var rear_left: Marker3D = $RearLeftTyre
@onready var rear_right: Marker3D = $RearRightTyre

# ================================================================
# CAR CONFIG
# ================================================================

var acceleration: float
var reverse_acceleration: float

var gear_1_acceleration: float
var gear_2_acceleration: float
var gear_3_acceleration: float
var gear_4_acceleration: float
var gear_5_acceleration: float

var max_speed: float

var gear_1_max_speed: float
var gear_2_max_speed: float
var gear_3_max_speed: float
var gear_4_max_speed: float
var gear_5_max_speed: float

var max_reverse_speed: float

var friction: float
var coast_deceleration: float

var brake_force: float
var high_speed_brake_force: float

var handbrake_force: float
var high_speed_handbrake_force: float

# ================================================================
# NORMAL STEERING
# ================================================================

var low_speed_steering: float
var high_speed_steering: float
var min_steering_speed: float
var normal_grip: float

# ================================================================
# DRIFTING
# ================================================================

var drift_entry_speed: float
var drift_entry_steering: float

var drift_grip: float
var drift_tightening_grip: float

var drift_steering: float
var drift_throttle_rotation: float

var drift_exit_angle: float
var drift_exit_speed: float

var handbrake_drift_grip: float

# ================================================================
# WHEELSPIN
# ================================================================

var wheelspin_entry_rpm: float
var wheelspin_exit_rpm: float

var wheelspin_grip: float
var wheelspin_steering: float

var chain_drift_angle: float
var wheelspin_min_throttle: float

var wheelspin_max_time: float

# ================================================================
# LAUNCH
# ================================================================

var launch_hold_max_speed: float

var launch_min_rpm: float
var launch_target_rpm: float

var launch_acceleration_multiplier: float
var launch_wheelspin_time: float


# ================================================================
# ENGINE RPM
# ================================================================

var idle_rpm: float
var max_rpm: float
var rpm_response: float

var throttle_rpm_boost: float
var drift_rpm_boost: float
var wheelspin_rpm_boost: float

# ================================================================
# STATE
# ================================================================

var drive_state: int = DriveState.NORMAL
var drift_direction: float = 0.0

var rpm: float
var display_rpm: float
var current_gear: int = 0
var speed_kmh: float = 0.0
var neutral_timer: float = 0.0

var launch_charging: bool = false
var launch_shift_timer: float = 0.0
var launch_rpm_drop_timer: float = 0.0
var brake_revving: bool = false

var wheelspin_from_launch: bool = false
var wheelspin_timer: float = 0.0


func _ready() -> void:
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(60.0)
	car_config = CarSettings.get_car(selected_car)
	car_1_model.visible = selected_car == 1
	car_2_model.visible = selected_car == 2

	acceleration = car_config["acceleration"]
	reverse_acceleration = car_config["reverse_acceleration"]

	gear_1_acceleration = car_config["gear_acceleration"][0]
	gear_2_acceleration = car_config["gear_acceleration"][1]
	gear_3_acceleration = car_config["gear_acceleration"][2]
	gear_4_acceleration = car_config["gear_acceleration"][3]
	gear_5_acceleration = car_config["gear_acceleration"][4]

	max_speed = car_config["max_speed"]

	gear_1_max_speed = car_config["gear_max_speed"][0]
	gear_2_max_speed = car_config["gear_max_speed"][1]
	gear_3_max_speed = car_config["gear_max_speed"][2]
	gear_4_max_speed = car_config["gear_max_speed"][3]
	gear_5_max_speed = car_config["gear_max_speed"][4]

	max_reverse_speed = car_config["max_reverse_speed"]

	friction = car_config["friction"]
	coast_deceleration = car_config["coast_deceleration"]

	brake_force = car_config["brake_force"]
	high_speed_brake_force = car_config["high_speed_brake_force"]

	low_speed_steering = car_config["low_speed_steering"]
	high_speed_steering = car_config["high_speed_steering"]
	min_steering_speed = car_config["min_steering_speed"]
	normal_grip = car_config["normal_grip"]

	drift_entry_speed = car_config["drift_entry_speed"]
	drift_entry_steering = car_config["drift_entry_steering"]

	drift_grip = car_config["drift_grip"]
	drift_tightening_grip = car_config["drift_tightening_grip"]

	drift_steering = car_config["drift_steering"]
	drift_throttle_rotation = car_config["drift_throttle_rotation"]

	drift_exit_angle = car_config["drift_exit_angle"]
	drift_exit_speed = car_config["drift_exit_speed"]

	handbrake_drift_grip = car_config["handbrake_drift_grip"]
	brake_force = car_config["brake_force"]
	high_speed_brake_force = car_config["high_speed_brake_force"]

	handbrake_force = car_config["handbrake_force"]
	high_speed_handbrake_force = car_config["high_speed_handbrake_force"]
	
	wheelspin_entry_rpm = car_config["wheelspin_entry_rpm"]
	wheelspin_exit_rpm = car_config["wheelspin_exit_rpm"]

	wheelspin_grip = car_config["wheelspin_grip"]
	wheelspin_steering = car_config["wheelspin_steering"]

	chain_drift_angle = car_config["chain_drift_angle"]
	wheelspin_min_throttle = car_config["wheelspin_min_throttle"]
	
	launch_hold_max_speed = car_config["launch_hold_max_speed"]

	launch_min_rpm = car_config["launch_min_rpm"]
	launch_target_rpm = car_config["launch_target_rpm"]

	launch_acceleration_multiplier = car_config["launch_acceleration_multiplier"]
	launch_wheelspin_time = car_config["launch_wheelspin_time"]
	wheelspin_max_time = car_config["wheelspin_max_time"]
	
	idle_rpm = car_config["idle_rpm"]
	max_rpm = car_config["max_rpm"]
	rpm_response = car_config["rpm_response"]

	throttle_rpm_boost = car_config["throttle_rpm_boost"]
	drift_rpm_boost = car_config["drift_rpm_boost"]
	wheelspin_rpm_boost = car_config["wheelspin_rpm_boost"]

	# Initialise RPM using this car's configured idle RPM.
	rpm = idle_rpm
	display_rpm = idle_rpm
	car_audio.setup()

# ================================================================
# PHYSICS PROCESS
# ================================================================

func _physics_process(delta: float) -> void:
	var forward: Vector3 = get_ground_forward()

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
	
	brake_revving = (
		drive_state == DriveState.NORMAL
		and normal_brake
		and speed < launch_hold_max_speed
		and throttle > 0.0
	)

	if launch_charging or brake_revving:
		horizontal_velocity = horizontal_velocity.move_toward(
			Vector3.ZERO,
			friction * delta
		)


	elif throttle > 0.0:
		var acceleration_amount: float = acceleration

		# Use separate acceleration values for normal forward driving.
		if drive_state == DriveState.NORMAL:
			match current_gear:
				1:
					acceleration_amount = gear_1_acceleration
				2:
					acceleration_amount = gear_2_acceleration
				3:
					acceleration_amount = gear_3_acceleration
				4:
					acceleration_amount = gear_4_acceleration
				5:
					acceleration_amount = gear_5_acceleration

		if (
			drive_state == DriveState.WHEELSPIN
			and wheelspin_from_launch
		):
			acceleration_amount *= launch_acceleration_multiplier

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
		# Coast when the accelerator is released.
		horizontal_velocity = horizontal_velocity.move_toward(
			Vector3.ZERO,
			coast_deceleration * delta
		)


	# ------------------------------------------------
	# SPEED LIMIT
	# ------------------------------------------------

	var gear_speed_limit: float = max_speed

	match current_gear:
		1:
			gear_speed_limit = gear_1_max_speed
		2:
			gear_speed_limit = gear_2_max_speed
		3:
			gear_speed_limit = gear_3_max_speed
		4:
			gear_speed_limit = gear_4_max_speed
		5:
			gear_speed_limit = gear_5_max_speed

	# Limit acceleration in the current gear without removing
	# momentum the car already had before a downshift.
	if throttle > 0.0 and not launch_charging:
		var previous_speed: float = get_horizontal_velocity().length()
		var allowed_speed: float = maxf(gear_speed_limit, previous_speed)

		if horizontal_velocity.length() > allowed_speed:
			horizontal_velocity = (
				horizontal_velocity.normalized()
				* allowed_speed
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
		var brake_speed_ratio: float = clampf(
			speed / max_speed,
			0.0,
			1.0
		)

		var current_brake_force: float = lerpf(
			brake_force,
			high_speed_brake_force,
			brake_speed_ratio
		)

		horizontal_velocity = horizontal_velocity.move_toward(
			Vector3.ZERO,
			current_brake_force * delta
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
	


	# ------------------------------------------------
	# DISPLAY RPM
	# ------------------------------------------------

	if (
		(handbrake or normal_brake)
		and throttle > 0.0
		and horizontal_velocity.length() < 0.5
	):
		# Show the existing launch RPM while revving at a standstill.
		display_rpm = move_toward(
			display_rpm,
			rpm,
			10000.0 * delta
		)

	elif drive_state == DriveState.NORMAL and current_gear == 1:
		# 1st gear: idle RPM at 0 speed, 6300 RPM at its speed limit.
		var speed_ratio: float = clampf(
			horizontal_velocity.length() / maxf(gear_1_max_speed - 0.05, 0.01),
			0.0,
			1.0
		)

		var target_display_rpm: float = lerpf(
			idle_rpm,
			6300.0,
			speed_ratio
		)

		display_rpm = move_toward(
			display_rpm,
			target_display_rpm,
			10000.0 * delta
		)

	elif drive_state == DriveState.NORMAL and current_gear == 2:
		# 2nd gear: 5000 RPM at 1st gear's speed limit,
		# rising to 6300 RPM at 2nd gear's speed limit.
		var second_gear_speed: float = horizontal_velocity.length()

		var speed_ratio: float = clampf(
			(second_gear_speed - gear_1_max_speed)
			/ maxf((gear_2_max_speed - 0.05) - gear_1_max_speed, 0.01),
			0.0,
			1.0
		)

		var target_display_rpm: float = lerpf(
			5000.0,
			6300.0,
			speed_ratio
		)

		display_rpm = move_toward(
			display_rpm,
			target_display_rpm,
			10000.0 * delta
		)
	
	elif drive_state == DriveState.NORMAL and current_gear == 3:
		# 3rd gear: 5000 RPM at 2nd gear's speed limit,
		# rising to 6300 RPM at 3rd gear's speed limit.
		var third_gear_speed: float = horizontal_velocity.length()

		var speed_ratio: float = clampf(
			(third_gear_speed - gear_2_max_speed)
			/ maxf((gear_3_max_speed - 0.05) - gear_2_max_speed, 0.01),
			0.0,
			1.0
		)

		var target_display_rpm: float = lerpf(
			5000.0,
			6300.0,
			speed_ratio
		)

		display_rpm = move_toward(
			display_rpm,
			target_display_rpm,
			10000.0 * delta
		)
		
	
	elif drive_state == DriveState.NORMAL and current_gear == 4:
		# 4th gear: 5000 RPM at 3rd gear's speed limit,
		# rising to 6300 RPM at 4th gear's speed limit.
		var fourth_gear_speed: float = horizontal_velocity.length()

		var speed_ratio: float = clampf(
			(fourth_gear_speed - gear_3_max_speed)
			/ maxf((gear_4_max_speed - 0.05) - gear_3_max_speed, 0.01),
			0.0,
			1.0
		)

		var target_display_rpm: float = lerpf(
			5000.0,
			6300.0,
			speed_ratio
		)

		display_rpm = move_toward(
			display_rpm,
			target_display_rpm,
			10000.0 * delta
		)
	
	
	elif drive_state == DriveState.NORMAL and current_gear == 5:
		# 5th gear: 5000 RPM at 4th gear's speed limit,
		# rising to 6300 RPM at 5th gear's speed limit.
		var fifth_gear_speed: float = horizontal_velocity.length()

		var speed_ratio: float = clampf(
			(fifth_gear_speed - gear_4_max_speed)
			/ maxf((gear_5_max_speed - 0.05) - gear_4_max_speed, 0.01),
			0.0,
			1.0
		)

		var target_display_rpm: float = lerpf(
			5000.0,
			6300.0,
			speed_ratio
		)

		display_rpm = move_toward(
			display_rpm,
			target_display_rpm,
			10000.0 * delta
		)


	else:
		if drive_state == DriveState.NORMAL and throttle <= 0.0:
			var rpm_fall_rate: float = 1800.0

			if normal_brake or down_braking:
				rpm_fall_rate = 6000.0

			display_rpm = move_toward(
				display_rpm,
				idle_rpm,
				rpm_fall_rate * delta
			)

		else:
			var display_response: float = 3000.0

			if (
				drive_state == DriveState.WHEELSPIN
				and wheelspin_from_launch
			):
				display_response = 12000.0

			display_rpm = move_toward(
				display_rpm,
				rpm,
				display_response * delta
			)



	# ------------------------------------------------
	# GEARBOX
	# ------------------------------------------------

	if (
		drive_state == DriveState.WHEELSPIN
		and wheelspin_from_launch
		and current_gear >= 1
		and current_gear < 5
	):
		if rpm >= 7850.0:
			launch_shift_timer += delta

			if launch_shift_timer >= 0.5:
				current_gear += 1
				rpm = 5000.0
				display_rpm = 5000.0
				launch_shift_timer = 0.0
		else:
			launch_shift_timer = 0.0

	if drive_state == DriveState.NORMAL:
		if throttle < 0.0:
			# Reverse.
			current_gear = -1
			neutral_timer = 0.0

		else:
			# Engage 1st when moving forward from neutral or reverse.
			if throttle > 0.0 and current_gear < 1:
				current_gear = 1

			# ------------------------------------------------
			# SPEED-BASED DOWNSHIFTING
			# ------------------------------------------------

			# Check every frame, including while braking or
			# reapplying the accelerator.
			if current_gear == 3 and speed <= gear_2_max_speed:
				current_gear = 2

			if current_gear == 2 and speed <= gear_1_max_speed:
				current_gear = 1

			if current_gear == 4 and speed <= gear_3_max_speed - 0.5:
				current_gear = 3

			if current_gear == 5 and speed <= gear_4_max_speed - 0.5:
				current_gear = 4

			# Do not force display_rpm to a fixed value here.
			# The DISPLAY RPM section will move the needle
			# towards the RPM appropriate for the new gear.

			# ------------------------------------------------
			# UPSHIFTING
			# ------------------------------------------------

			# Allow upshifts through all five gears.
			if throttle > 0.0:
				if current_gear >= 1 and current_gear < 5 and display_rpm >= 6300.0 and speed > 0.5:
					current_gear += 1
					display_rpm = 5000.0

			# ------------------------------------------------
			# NEUTRAL
			# ------------------------------------------------

			if throttle > 0.0:
				neutral_timer = 0.0

			elif speed < 0.2:
				neutral_timer += delta

				if neutral_timer >= 2.0:
					current_gear = 0
					display_rpm = idle_rpm
			else:
				neutral_timer = 0.0


	# ------------------------------------------------
	# APPLY VELOCITY
	# ------------------------------------------------

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	if is_on_floor():
		if not normal_brake:
			var slope_gravity: Vector3 = (
				Vector3.DOWN * gravity
			).slide(get_floor_normal())

			var car_forward: Vector3 = get_ground_forward()

			# Only allow slope gravity along the car's forward/back direction.
			var forward_slope_force: Vector3 = (
				car_forward
				* slope_gravity.dot(car_forward)
			)

			velocity += forward_slope_force * delta
		else:
			velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

	move_and_slide()

	align_to_ground(delta)
	
	apply_edge_tipping(delta)

	speed_kmh = get_horizontal_velocity().length() * 3.6


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

		var low_speed_factor: float = clampf(
			speed / 4.0,
			0.0,
			1.0
		)

		steering *= low_speed_factor

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

		var handbrake_speed_ratio: float = clampf(
			speed / max_speed,
			0.0,
			1.0
		)

		var current_handbrake_force: float = lerpf(
			handbrake_force,
			high_speed_handbrake_force,
			handbrake_speed_ratio
		)

		horizontal_velocity = horizontal_velocity.move_toward(
			Vector3.ZERO,
			current_handbrake_force * delta
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

		if (
			wheelspin_timer <= 0.0
			and not wheelspin_from_launch
		):
			enter_normal()
			return horizontal_velocity

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

	# Launch wheelspin requires continued throttle.
	if wheelspin_from_launch:
		if throttle < wheelspin_min_throttle:
			enter_normal()
			return horizontal_velocity

		if wheelspin_timer > 0.0:
			return horizontal_velocity

		wheelspin_from_launch = false
		enter_normal()
		return horizontal_velocity

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

	# Stationary handbrake or normal brake lets the engine rev freely.
	if launch_charging or brake_revving:
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
		if wheelspin_from_launch:
			if launch_rpm_drop_timer > 0.0:
				launch_rpm_drop_timer -= delta
			else:
				target_rpm = maxf(
					target_rpm,
					launch_target_rpm
				)
		else:
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
	wheelspin_timer = wheelspin_max_time


func enter_launch_wheelspin() -> void:
	drive_state = DriveState.WHEELSPIN

	wheelspin_from_launch = true
	wheelspin_timer = launch_wheelspin_time
	launch_rpm_drop_timer = 0.35


func enter_normal() -> void:
	drive_state = DriveState.NORMAL
	drift_direction = 0.0

	wheelspin_from_launch = false
	wheelspin_timer = 0.0


# ================================================================
# HELPERS
# ================================================================

func tyre_has_ground(tyre: Marker3D) -> bool:
	var space_state := get_world_3d().direct_space_state

	var query := PhysicsRayQueryParameters3D.create(
		tyre.global_position + Vector3.UP * 0.1,
		tyre.global_position + Vector3.DOWN * 0.15
	)

	query.exclude = [
		get_rid()
	]

	var result := space_state.intersect_ray(query)

	return not result.is_empty()

func apply_edge_tipping(delta: float) -> void:
	var fl := tyre_has_ground(front_left)
	var fr := tyre_has_ground(front_right)
	var rl := tyre_has_ground(rear_left)
	var rr := tyre_has_ground(rear_right)

	var front_supported := fl or fr
	var rear_supported := rl or rr
	var left_supported := fl or rl
	var right_supported := fr or rr

	var tip_speed := deg_to_rad(30.0) * delta

	# Front hanging off.
	if not front_supported and rear_supported:
		rotate_object_local(Vector3.RIGHT, tip_speed)

	# Rear hanging off.
	elif front_supported and not rear_supported:
		rotate_object_local(Vector3.RIGHT, -tip_speed)

	# Left side hanging off.
	elif not left_supported and right_supported:
		rotate_object_local(Vector3.FORWARD, tip_speed)

	# Right side hanging off.
	elif left_supported and not right_supported:
		rotate_object_local(Vector3.FORWARD, -tip_speed)

func align_to_ground(delta: float) -> void:
	if not is_on_floor():
		return

	var floor_normal: Vector3 = get_floor_normal()

	var forward: Vector3 = global_transform.basis.z
	forward = forward.slide(floor_normal).normalized()

	if forward.length_squared() < 0.001:
		return

	var right: Vector3 = floor_normal.cross(forward).normalized()
	forward = right.cross(floor_normal).normalized()

	var target_basis := Basis(
		right,
		floor_normal,
		forward
	)

	global_transform.basis = global_transform.basis.slerp(
		target_basis,
		clampf(6.0 * delta, 0.0, 1.0)
	).orthonormalized()

func get_forward() -> Vector3:
	var forward: Vector3 = global_transform.basis.z

	forward.y = 0.0

	return forward.normalized()

func get_ground_forward() -> Vector3:
	var forward := get_forward()

	if is_on_floor():
		forward = forward.slide(get_floor_normal())

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
