extends CharacterBody3D
const CarSettings = preload("res://DriftGame/scripts/car/car_settings.gd")

# ================================================================
# PHYSICS CONSTANTS
# ================================================================

const GRAVITY: float = 16.0
const FLOOR_SNAP_LENGTH: float = 0.1
const FLOOR_MAX_ANGLE_DEG: float = 60.0

const STEERING_PIVOT_OFFSET: Vector3 = Vector3(0.0, 0.0, -0.5)

const TYRE_RAYCAST_UP: float = 0.1
const TYRE_RAYCAST_DOWN: float = 0.15

const NEUTRAL_SPEED_THRESHOLD: float = 0.2
const NEUTRAL_TIMER_DURATION: float = 2.0

const EDGE_TIPPING_SPEED_DEG: float = 30.0
const GROUND_ALIGNMENT_SPEED: float = 6.0
const GROUND_ALIGNMENT_SPEED_FAST: float = 8.0   # Faster alignment at high speed (reduced from 12)
const GROUND_ALIGNMENT_SPEED_SLOW: float = 4.0   # Slower for smooth hills (increased from 3)

# Airborne & Landing
const AIR_PITCH_CONTROL: float = 0.4      # How much control in air (reduced)
const AIR_ROLL_CONTROL: float = 0.3       # Roll control in air (reduced)
const LANDING_DAMPENING: float = 0.7      # Softens landings (less aggressive)
const SUSPENSION_RESPONSE: float = 12.0   # How fast suspension reacts (faster)
const MAX_LANDING_ROTATION: float = 0.25  # Max rotation adjust on landing (increased)

const DONUT_ROTATION_ACCEL: float = 3.0
const DONUT_ROTATION_MAX: float = 2.8
const DONUT_ROTATION_DECAY: float = 1.5
const DONUT_STEERING_THRESHOLD: float = 0.5

@export var selected_car: int = 2
@export_enum("Original", "Drift", "Race")
var selected_tuning_preset: int = 0
var car_config: Dictionary
@onready var car_1_model: Node3D = $SportsCar2
@onready var car_2_model: Node3D = $Car2

# ================================================================
# DRIFT PHYSICS MODE
# ================================================================

enum DriftPhysicsMode {
	CLASSIC,
	MODERN
}

@export var drift_physics_mode: DriftPhysicsMode = DriftPhysicsMode.MODERN

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

var donut_angular_velocity: float = 0.0
var donut_active: bool = false

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

# Drift exit grace period
var drift_exit_grace_timer: float = 0.0
const DRIFT_EXIT_GRACE_PERIOD: float = 0.15

# Airborne tracking (simplified)
var was_airborne: bool = false
var airborne_time: float = 0.0
var last_ground_normal: Vector3 = Vector3.UP

# ================================================================
# SIGNALS
# ================================================================
# (Signals removed - were causing issues)

# ================================================================
# DISPLAY RPM CONFIGURATION
# ================================================================

const DISPLAY_RPM_SHIFT_POINT: float = 6300.0
const DISPLAY_RPM_AFTER_SHIFT: float = 5000.0
const DISPLAY_RPM_RESPONSE: float = 10000.0

var gear_rpm_map: Array[Dictionary] = []

func setup_gear_rpm_map() -> void:
	gear_rpm_map = [
		{"min_speed": 0.0, "max_speed": gear_1_max_speed, "min_rpm": idle_rpm, "max_rpm": DISPLAY_RPM_SHIFT_POINT},
		{"min_speed": gear_1_max_speed, "max_speed": gear_2_max_speed, "min_rpm": DISPLAY_RPM_AFTER_SHIFT, "max_rpm": DISPLAY_RPM_SHIFT_POINT},
		{"min_speed": gear_2_max_speed, "max_speed": gear_3_max_speed, "min_rpm": DISPLAY_RPM_AFTER_SHIFT, "max_rpm": DISPLAY_RPM_SHIFT_POINT},
		{"min_speed": gear_3_max_speed, "max_speed": gear_4_max_speed, "min_rpm": DISPLAY_RPM_AFTER_SHIFT, "max_rpm": DISPLAY_RPM_SHIFT_POINT},
		{"min_speed": gear_4_max_speed, "max_speed": gear_5_max_speed, "min_rpm": DISPLAY_RPM_AFTER_SHIFT, "max_rpm": DISPLAY_RPM_SHIFT_POINT}
	]

func calculate_display_rpm_for_gear(gear: int, speed: float, delta: float) -> float:
	if gear < 1 or gear > 5:
		return display_rpm

	var range_data = gear_rpm_map[gear - 1]
	var speed_range = maxf((range_data["max_speed"] - 0.05) - range_data["min_speed"], 0.01)
	var speed_ratio = clampf(
		(speed - range_data["min_speed"]) / speed_range,
		0.0,
		1.0
	)

	var target_rpm = lerpf(range_data["min_rpm"], range_data["max_rpm"], speed_ratio)
	return move_toward(display_rpm, target_rpm, DISPLAY_RPM_RESPONSE * delta)

# ================================================================
# GEAR HELPERS
# ================================================================

func get_gear_acceleration(gear: int) -> float:
	match gear:
		1:
			return gear_1_acceleration
		2:
			return gear_2_acceleration
		3:
			return gear_3_acceleration
		4:
			return gear_4_acceleration
		5:
			return gear_5_acceleration
		_:
			return acceleration

func get_gear_max_speed(gear: int) -> float:
	match gear:
		1:
			return gear_1_max_speed
		2:
			return gear_2_max_speed
		3:
			return gear_3_max_speed
		4:
			return gear_4_max_speed
		5:
			return gear_5_max_speed
		_:
			return max_speed

func _ready() -> void:
	floor_snap_length = FLOOR_SNAP_LENGTH
	floor_max_angle = deg_to_rad(FLOOR_MAX_ANGLE_DEG)
	car_config = CarSettings.get_car(selected_car, selected_tuning_preset)
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

	# Setup gear-based display RPM mapping
	setup_gear_rpm_map()

# ================================================================
# PHYSICS PROCESS
# ================================================================

func _physics_process(delta: float) -> void:
	var input_state = gather_input()
	var velocity_state = calculate_velocity_state(input_state)

	var horizontal_velocity = velocity_state.horizontal_velocity
	horizontal_velocity = update_throttle_and_brake(delta, input_state, velocity_state, horizontal_velocity)
	horizontal_velocity = update_drive_state(delta, input_state, velocity_state, horizontal_velocity)

	update_rpm_and_display(delta, input_state, velocity_state)
	update_gearbox(delta, input_state, velocity_state)

	apply_physics_and_movement(delta, input_state, horizontal_velocity)
	update_visuals_and_effects(delta, input_state)

# ================================================================
# INPUT GATHERING
# ================================================================

func gather_input() -> Dictionary:
	return {
		"accelerate": Input.get_action_strength("accelerate"),
		"reverse": Input.get_action_strength("brake"),
		"steering": Input.get_axis("steer_left", "steer_right"),
		"handbrake": Input.is_action_pressed("handbrake"),
		"handbrake_released": Input.is_action_just_released("handbrake"),
		"normal_brake": Input.is_action_pressed("normal_brake")
	}

# ================================================================
# VELOCITY STATE CALCULATION
# ================================================================

func calculate_velocity_state(input: Dictionary) -> Dictionary:
	var forward = get_ground_forward()
	var h_vel = get_horizontal_velocity()
	var forward_speed = h_vel.dot(forward)

	return {
		"forward": forward,
		"horizontal_velocity": h_vel,
		"speed": h_vel.length(),
		"forward_speed": forward_speed,
		"down_braking": input.reverse > 0.0 and forward_speed > 0.5,
		"reversing": input.reverse > 0.0 and forward_speed <= 0.5
	}

# ================================================================
# THROTTLE & BRAKE UPDATE
# ================================================================

func update_throttle_and_brake(delta: float, input: Dictionary, velocity_state: Dictionary, horizontal_velocity: Vector3) -> Vector3:
	var forward = velocity_state.forward
	var speed = velocity_state.speed
	var forward_speed = velocity_state.forward_speed
	var down_braking = velocity_state.down_braking
	var reversing = velocity_state.reversing

	var throttle: float = input.accelerate
	if reversing:
		throttle = -input.reverse

	# ------------------------------------------------
	# STATIONARY HANDBRAKE / LAUNCH CHARGING
	# ------------------------------------------------

	launch_charging = (
		drive_state == DriveState.NORMAL
		and input.handbrake
		and speed < launch_hold_max_speed
		and throttle > 0.0
	)

	brake_revving = (
		drive_state == DriveState.NORMAL
		and input.normal_brake
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
			acceleration_amount = get_gear_acceleration(current_gear)

		if drive_state == DriveState.WHEELSPIN and wheelspin_from_launch:
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

	var gear_speed_limit: float = get_gear_max_speed(current_gear)

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
	forward_speed = horizontal_velocity.dot(forward)

	if forward_speed < -max_reverse_speed:
		horizontal_velocity = -forward * max_reverse_speed

	# ------------------------------------------------
	# NORMAL BRAKE
	# ------------------------------------------------

	if input.normal_brake or down_braking:
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
		input.normal_brake
		or down_braking
		or input.handbrake
	)

	car_visuals.set_brake_lights(brake_lights_on)

	return horizontal_velocity

# ================================================================
# DRIVE STATE UPDATE
# ================================================================

func update_drive_state(delta: float, input: Dictionary, velocity_state: Dictionary, horizontal_velocity: Vector3) -> Vector3:
	var speed = velocity_state.speed
	var forward_speed = velocity_state.forward_speed

	var throttle: float = input.accelerate
	if velocity_state.reversing:
		throttle = -input.reverse

	# Exit forward drifting when the car starts reversing.
	# Shared by Classic and Modern drift physics.
	if drive_state == DriveState.DRIFT:
		var current_forward_speed: float = horizontal_velocity.dot(
			get_ground_forward()
		)

		if current_forward_speed < -0.2:
			enter_normal()

	# ------------------------------------------------
	# HANDBRAKE LAUNCH
	# ------------------------------------------------

	if (
		drive_state == DriveState.NORMAL
		and input.handbrake_released
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
			input.handbrake
			and speed > drift_entry_speed
			and abs(input.steering) > drift_entry_steering
		):
			enter_drift(input.steering)

	# ------------------------------------------------
	# CURRENT DRIVING STATE
	# ------------------------------------------------

	if drive_state == DriveState.NORMAL:
		horizontal_velocity = handle_normal_driving(
			delta,
			input.steering,
			forward_speed,
			horizontal_velocity
		)

	elif drive_state == DriveState.DRIFT:
		horizontal_velocity = handle_drift(
			delta,
			throttle,
			input.steering,
			input.handbrake,
			horizontal_velocity
		)

	elif drive_state == DriveState.WHEELSPIN:
		horizontal_velocity = handle_wheelspin(
			delta,
			throttle,
			input.steering,
			horizontal_velocity
		)

	return horizontal_velocity

# ================================================================
# RPM & DISPLAY UPDATE
# ================================================================

func update_rpm_and_display(delta: float, input: Dictionary, velocity_state: Dictionary) -> void:
	var throttle: float = input.accelerate
	if velocity_state.reversing:
		throttle = -input.reverse

	# ------------------------------------------------
	# RPM
	# ------------------------------------------------

	update_rpm(delta, throttle, input.handbrake)

	# ------------------------------------------------
	# DISPLAY RPM
	# ------------------------------------------------

	var horizontal_velocity = velocity_state.horizontal_velocity
	var down_braking = velocity_state.down_braking

	if (
		(input.handbrake or input.normal_brake)
		and throttle > 0.0
		and horizontal_velocity.length() < 0.5
	):
		# Show the existing launch RPM while revving at a standstill.
		display_rpm = move_toward(
			display_rpm,
			rpm,
			DISPLAY_RPM_RESPONSE * delta
		)

	elif drive_state == DriveState.NORMAL and current_gear >= 1 and current_gear <= 5:
		# Use gear-based RPM calculation for all forward gears
		display_rpm = calculate_display_rpm_for_gear(
			current_gear,
			horizontal_velocity.length(),
			delta
		)

	else:
		if drive_state == DriveState.NORMAL and throttle <= 0.0:
			var rpm_fall_rate: float = 1800.0

			if input.normal_brake or down_braking:
				rpm_fall_rate = 6000.0

			display_rpm = move_toward(
				display_rpm,
				idle_rpm,
				rpm_fall_rate * delta
			)

		else:
			var display_response: float = 3000.0

			if drive_state == DriveState.WHEELSPIN and wheelspin_from_launch:
				display_response = 12000.0

			display_rpm = move_toward(
				display_rpm,
				rpm,
				display_response * delta
			)

# ================================================================
# GEARBOX UPDATE
# ================================================================

func update_gearbox(delta: float, input: Dictionary, velocity_state: Dictionary) -> void:
	var speed = velocity_state.speed
	var throttle: float = input.accelerate
	if velocity_state.reversing:
		throttle = -input.reverse

	# ------------------------------------------------
	# GEARBOX
	# ------------------------------------------------

	if (
		drive_state == DriveState.WHEELSPIN
		and wheelspin_from_launch
		and not donut_active
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

			elif speed < NEUTRAL_SPEED_THRESHOLD:
				neutral_timer += delta

				if neutral_timer >= NEUTRAL_TIMER_DURATION:
					current_gear = 0
					display_rpm = idle_rpm
			else:
				neutral_timer = 0.0

# ================================================================
# PHYSICS & MOVEMENT APPLICATION
# ================================================================

func apply_physics_and_movement(delta: float, input: Dictionary, horizontal_velocity: Vector3) -> void:
	# ------------------------------------------------
	# APPLY VELOCITY
	# ------------------------------------------------

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	if is_on_floor():
		if not input.normal_brake:
			var slope_gravity: Vector3 = (
				Vector3.DOWN * GRAVITY
			).slide(get_floor_normal())

			var car_forward: Vector3 = get_ground_forward()

			var forward_slope_force: Vector3 = (
				car_forward
				* slope_gravity.dot(car_forward)
			)

			velocity += forward_slope_force * delta
		else:
			velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta

	move_and_slide()

	handle_airborne_physics(delta)

	align_to_ground(delta)

	apply_edge_tipping(delta)

	speed_kmh = get_horizontal_velocity().length() * 3.6

# ================================================================
# VISUALS & EFFECTS UPDATE
# ================================================================

func update_visuals_and_effects(delta: float, input: Dictionary) -> void:
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
		input.steering,
		visual_forward_speed
	)

	# ------------------------------------------------
	# EFFECTS
	# ------------------------------------------------

	var is_skidding: bool = (
		drive_state == DriveState.DRIFT
		or drive_state == DriveState.WHEELSPIN
	)

	var skid_intensity: float = get_skid_intensity()

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

		# Steering pivot slightly ahead of the car's centre.
		var steering_pivot := STEERING_PIVOT_OFFSET

		# Record the pivot's world position before rotation.
		var pivot_before: Vector3 = global_transform * steering_pivot

		# Keep the original steering behaviour.
		rotate_y(
			-steering_input
			* steering
			* movement_direction
			* delta
		)

		# Adjust position to rotate around the new pivot.
		var pivot_after: Vector3 = global_transform * steering_pivot

		global_position += pivot_before - pivot_after

	return apply_grip(
		horizontal_velocity,
		normal_grip,
		delta
	)

# ================================================================
# CLASSIC DRIFT PHYSICS
# ================================================================

func handle_drift_classic(
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

	# Player steering.
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

	var drift_angle: float = get_drift_angle(horizontal_velocity)

	if speed < drift_exit_speed:
		enter_normal()
		return horizontal_velocity

	if abs(drift_angle) < drift_exit_angle:
		if throttle > wheelspin_min_throttle and rpm > wheelspin_entry_rpm:
			enter_wheelspin()
		else:
			enter_normal()

	return horizontal_velocity


# ================================================================
# DRIFT
# ================================================================

func handle_drift_modern(
	delta: float,
	throttle: float,
	steering_input: float,
	handbrake: bool,
	horizontal_velocity: Vector3
) -> Vector3:
	var speed: float = horizontal_velocity.length()
	var drift_angle: float = get_drift_angle(horizontal_velocity)

	# ================================================
	# SPEED-BASED ARC MULTIPLIER
	# ================================================
	# Deeper arcs at higher speeds for more dramatic drifts
	var arc_multiplier: float = get_drift_rotation_multiplier(speed)

	# Throttle rotation with speed-based depth
	rotate_y(
		-drift_direction
		* drift_throttle_rotation
		* maxf(throttle, 0.0)
		* arc_multiplier  # NEW: Deeper at high speed
		* delta
	)

	# ================================================
	# SPEED-BASED STEERING
	# ================================================
	# Less responsive at high speeds (more committed)
	var current_drift_steering: float = get_drift_steering_for_speed(speed)

	rotate_y(
		-steering_input
		* current_drift_steering  # NEW: Speed-based
		* delta
	)

	# ================================================
	# GRIP CALCULATION
	# ================================================
	var current_drift_grip: float = drift_grip

	# NEW: Speed-based grip reduction (more slide at high speed)
	current_drift_grip = get_drift_grip_for_speed(speed, current_drift_grip)

	# NEW: Angle-based grip reduction (more slide at deep angles)
	current_drift_grip = get_drift_grip_for_angle(drift_angle, current_drift_grip)

	# ================================================
	# COUNTER-STEERING
	# ================================================
	var counter_steer: float = get_counter_steer_amount(steering_input, drift_angle)

	# Apply counter-steering grip bonus
	if counter_steer > 0.0:
		# Counter-steering increases grip (helps stabilize)
		current_drift_grip += counter_steer * 1.5

	# ================================================
	# STEERING INTO DRIFT
	# ================================================
	# Steering into the drift tightens the radius
	if (
		steering_input != 0.0
		and sign(steering_input) == drift_direction
	):
		current_drift_grip += (
			abs(steering_input)
			* drift_tightening_grip
		)

	# ================================================
	# HANDBRAKE
	# ================================================
	# Handbrake reduces grip and removes speed
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

	# ================================================
	# APPLY GRIP
	# ================================================
	horizontal_velocity = apply_grip(
		horizontal_velocity,
		current_drift_grip,
		delta
	)

	# ================================================
	# DRIFT EXIT CONDITIONS
	# ================================================
	# Exit if too slow
	if speed < drift_exit_speed:
		enter_normal()
		drift_exit_grace_timer = 0.0
		return horizontal_velocity

	# Check if drift angle is below threshold
	if abs(drift_angle) < drift_exit_angle:
		# NEW: Grace period before exiting (prevents instant exits)
		drift_exit_grace_timer += delta

		if drift_exit_grace_timer >= DRIFT_EXIT_GRACE_PERIOD:
			# NEW: Stricter wheelspin conditions
			# Only enter wheelspin in specific scenarios (low gear burnouts)
			if (
				throttle > 0.7              # High throttle (was 0.4)
				and rpm > 6500              # Higher RPM (was 5000)
				and speed < 8.0             # Low speed only
				and current_gear <= 2       # Low gears only
			):
				enter_wheelspin()
			else:
				enter_normal()  # Clean exit instead

			drift_exit_grace_timer = 0.0
	else:
		# Back in drift zone, reset grace timer
		drift_exit_grace_timer = 0.0

	return horizontal_velocity


# ================================================================
# DRIFT PHYSICS SELECTOR
# ================================================================

func handle_drift(
	delta: float,
	throttle: float,
	steering_input: float,
	handbrake: bool,
	horizontal_velocity: Vector3
) -> Vector3:

	match drift_physics_mode:
		DriftPhysicsMode.CLASSIC:
			return handle_drift_classic(
				delta,
				throttle,
				steering_input,
				handbrake,
				horizontal_velocity
			)

		DriftPhysicsMode.MODERN:
			return handle_drift_modern(
				delta,
				throttle,
				steering_input,
				handbrake,
				horizontal_velocity
			)

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

	# Initiate a donut during first-gear launch wheelspin.
	if (
		not donut_active
		and wheelspin_from_launch
		and current_gear == 1
		and absf(steering_input) > DONUT_STEERING_THRESHOLD
		and throttle > wheelspin_min_throttle
	):
		donut_active = true

	# Continue rotating while the donut is active.
	if donut_active:
		var target_rotation: float = (
			steering_input * DONUT_ROTATION_MAX
		)

		if absf(steering_input) > 0.01:
			donut_angular_velocity = move_toward(
				donut_angular_velocity,
				target_rotation,
				DONUT_ROTATION_ACCEL * delta
			)
		else:
			# Maintain rotation while accelerating during an active donut.
			if throttle < wheelspin_min_throttle:
				donut_angular_velocity = move_toward(
					donut_angular_velocity,
					0.0,
					DONUT_ROTATION_DECAY * delta
				)

		rotate_y(-donut_angular_velocity * delta)
	else:
		donut_angular_velocity = 0.0

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
		not donut_active
		and speed > drift_entry_speed
		and abs(drift_angle) > chain_drift_angle
	):
		enter_drift_from_angle(
			drift_angle
		)

		return horizontal_velocity

	if donut_active:
		if throttle < wheelspin_min_throttle or current_gear != 1:
			enter_normal()

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
# DRIFT DYNAMICS - SPEED-BASED
# ================================================================

func get_drift_rotation_multiplier(speed: float) -> float:
	"""
	Increases drift rotation at higher speeds for deeper, more dramatic arcs.
	Low speed: 1.0x (controlled)
	High speed: 2.2x (dramatic)
	"""
	var speed_ratio: float = clampf(speed / max_speed, 0.0, 1.0)
	return 1.0 + (speed_ratio * 1.2)


func get_drift_grip_for_speed(speed: float, base_grip: float) -> float:
	"""
	Reduces grip at higher speeds for more dramatic powerslide.
	Low speed: 100% grip (more control)
	High speed: 60% grip (more slide/spectacle)
	"""
	var speed_ratio: float = clampf(speed / max_speed, 0.0, 1.0)
	var grip_multiplier: float = 1.0 - (speed_ratio * 0.4)
	return base_grip * grip_multiplier


func get_drift_grip_for_angle(drift_angle: float, base_grip: float) -> float:
	"""
	Reduces grip at deeper drift angles for more sideways slide.
	Straight (0°): 100% grip
	Deep angle (45°): 70% grip (sweet spot powerslide)
	"""
	var angle_ratio: float = clampf(abs(drift_angle) / 45.0, 0.0, 1.0)
	var grip_multiplier: float = 1.0 - (angle_ratio * 0.3)
	return base_grip * grip_multiplier


func get_drift_steering_for_speed(speed: float) -> float:
	"""
	Reduces steering responsiveness at high speeds.
	Low speed: Full responsiveness (maneuverable hairpins)
	High speed: 70% responsiveness (committed sweepers)
	"""
	var speed_ratio: float = clampf(speed / max_speed, 0.0, 1.0)
	return lerpf(drift_steering, drift_steering * 0.7, speed_ratio)


func get_counter_steer_amount(steering_input: float, drift_angle: float) -> float:
	"""
	Detects when player is counter-steering (steering opposite to drift slide).
	Returns 0.0-1.0 based on counter-steer intensity.

	Counter-steering = steering opposite to drift angle
	Example: Car sliding right (+angle), player steering left (-)
	"""
	if abs(drift_angle) < 2.0:
		return 0.0  # No meaningful drift angle yet

	var angle_direction: float = sign(drift_angle)
	var steer_direction: float = sign(steering_input)

	# Counter-steering: opposite directions
	if angle_direction != steer_direction and abs(steering_input) > 0.1:
		return abs(steering_input)  # Return intensity 0.0-1.0

	return 0.0


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

	drift_exit_grace_timer = 0.0


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

	drift_exit_grace_timer = 0.0


func enter_wheelspin() -> void:
	drive_state = DriveState.WHEELSPIN

	wheelspin_from_launch = false
	wheelspin_timer = wheelspin_max_time

	drift_exit_grace_timer = 0.0


func enter_launch_wheelspin() -> void:
	drive_state = DriveState.WHEELSPIN

	wheelspin_from_launch = true
	wheelspin_timer = launch_wheelspin_time
	launch_rpm_drop_timer = 0.35

	donut_active = false
	donut_angular_velocity = 0.0

	drift_exit_grace_timer = 0.0


func enter_normal() -> void:
	drive_state = DriveState.NORMAL
	drift_direction = 0.0

	wheelspin_from_launch = false
	wheelspin_timer = 0.0

	donut_active = false
	donut_angular_velocity = 0.0

	drift_exit_grace_timer = 0.0


# ================================================================
# HELPERS
# ================================================================

func tyre_has_ground(tyre: Marker3D) -> bool:
	var space_state := get_world_3d().direct_space_state

	var query := PhysicsRayQueryParameters3D.create(
		tyre.global_position + Vector3.UP * TYRE_RAYCAST_UP,
		tyre.global_position + Vector3.DOWN * TYRE_RAYCAST_DOWN
	)

	query.exclude = [
		get_rid()
	]

	var result := space_state.intersect_ray(query)

	return not result.is_empty()

func handle_airborne_physics(delta: float) -> void:
	"""
	Handle physics while airborne - SIMPLIFIED to prevent glitches
	"""
	var current_airborne: bool = not is_on_floor()

	# Track airborne state
	if current_airborne:
		airborne_time += delta
	else:
		airborne_time = 0.0

	# Update airborne state
	was_airborne = current_airborne


func apply_edge_tipping(delta: float) -> void:
	var fl := tyre_has_ground(front_left)
	var fr := tyre_has_ground(front_right)
	var rl := tyre_has_ground(rear_left)
	var rr := tyre_has_ground(rear_right)

	var front_supported := fl or fr
	var rear_supported := rl or rr
	var left_supported := fl or rl
	var right_supported := fr or rr

	var tip_speed := deg_to_rad(EDGE_TIPPING_SPEED_DEG) * delta

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
	last_ground_normal = floor_normal

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

	# Speed-based alignment - faster at high speed, slower for smooth hills
	var speed: float = get_horizontal_velocity().length()
	var speed_ratio: float = clampf(speed / max_speed, 0.0, 1.0)

	var alignment_speed: float = lerpf(
		GROUND_ALIGNMENT_SPEED_SLOW,   # Slow on hills
		GROUND_ALIGNMENT_SPEED_FAST,   # Fast at speed
		speed_ratio
	)

	global_transform.basis = global_transform.basis.slerp(
		target_basis,
		clampf(alignment_speed * delta, 0.0, 1.0)
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
