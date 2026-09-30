extends Camera2D


enum CameraMode {
	WORLD_FIXED,
	CAR_LOCKED
}


@export_category("Drift Camera")
@export var normal_steering_angle: float = 15.0
@export var drift_camera_strength: float = 0.85
@export var max_drift_camera_angle: float = 70.0
@export var drift_camera_speed: float = 5.0

@export_category("Zoom")
@export var stationary_zoom: float = 1.10
@export var high_speed_zoom: float = 0.92
@export var zoom_speed: float = 3.0

@export_category("Follow")
@export var max_speed_reference: float = 500.0


var camera_mode: int = CameraMode.WORLD_FIXED
var camera_offset: float = 0.0


func _ready() -> void:
	ignore_rotation = false

	zoom = Vector2(
		stationary_zoom,
		stationary_zoom
	)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("camera_toggle"):
		toggle_camera_mode()

	var car: CharacterBody2D = get_parent()

	update_zoom(
		delta,
		car.velocity.length()
	)

	if camera_mode == CameraMode.WORLD_FIXED:
		handle_world_fixed()

	elif camera_mode == CameraMode.CAR_LOCKED:
		handle_car_locked(
			delta,
			car
		)


func handle_world_fixed() -> void:
	global_rotation = 0.0
	camera_offset = 0.0


func handle_car_locked(
	delta: float,
	car: CharacterBody2D
) -> void:
	var steering_input: float = Input.get_axis(
		"steer_left",
		"steer_right"
	)

	# Small camera angle during normal steering.
	var normal_steering_offset: float = deg_to_rad(
		normal_steering_angle
	) * -steering_input

	var target_offset: float = normal_steering_offset

	# During a slide, use the actual difference between
	# where the car points and where it is travelling.
	if car.velocity.length() > 20.0:
		var car_forward: Vector2 = Vector2.UP.rotated(
			car.global_rotation
		)

		var movement_direction: Vector2 = (
			car.velocity.normalized()
		)

		var drift_angle: float = car_forward.angle_to(
			movement_direction
		)

		var drift_offset: float = (
			drift_angle
			* drift_camera_strength
		)

		var max_angle: float = deg_to_rad(
			max_drift_camera_angle
		)

		drift_offset = clampf(
			drift_offset,
			-max_angle,
			max_angle
		)

		# Drift takes over once it becomes stronger
		# than the normal steering camera angle.
		if abs(drift_offset) > abs(normal_steering_offset):
			target_offset = drift_offset

	camera_offset = lerp_angle(
		camera_offset,
		target_offset,
		clampf(
			drift_camera_speed * delta,
			0.0,
			1.0
		)
	)

	global_rotation = (
		car.global_rotation
		+ camera_offset
	)


func update_zoom(
	delta: float,
	speed: float
) -> void:
	var speed_ratio: float = clampf(
		speed / max_speed_reference,
		0.0,
		1.0
	)

	var target_zoom_value: float = lerpf(
		stationary_zoom,
		high_speed_zoom,
		speed_ratio
	)

	var target_zoom: Vector2 = Vector2(
		target_zoom_value,
		target_zoom_value
	)

	zoom = zoom.lerp(
		target_zoom,
		clampf(
			zoom_speed * delta,
			0.0,
			1.0
		)
	)


func toggle_camera_mode() -> void:
	if camera_mode == CameraMode.WORLD_FIXED:
		camera_mode = CameraMode.CAR_LOCKED
		camera_offset = 0.0

		print("Camera: CAR LOCKED")

	else:
		camera_mode = CameraMode.WORLD_FIXED
		camera_offset = 0.0

		print("Camera: WORLD FIXED")
