extends Camera3D


# ================================================================
# CAMERA PRESETS
# ================================================================
#
# Each entry is one complete camera mode.
#
# To REMOVE a camera from the C cycle:
#     Comment out its line in CAMERA_PRESETS.
#
# To ADD another camera:
#     Add another dictionary to CAMERA_PRESETS.
#
# locked_to_car:
#     false = world stays upright
#     true  = camera rotates with the car
#
# speed_zoom:
#     true  = size changes with vehicle speed
#     false = uses the fixed "size"
#
# ================================================================


var CAMERA_PRESETS: Array[Dictionary] = [

	# C1 - World-fixed camera
	{
		"name": "WORLD_FIXED",
		"locked_to_car": false,
		"position": Vector3(0.0, 12.0, 6.0),
		"angle": -65.0,
		"size": 26.0,
		"speed_zoom": true,
		"high_speed_size": 30.0
	},

	# C2 - Car-locked camera
	{
		"name": "CAR_LOCKED",
		"locked_to_car": true,
		"position": Vector3(0.0, 12.0, 6.0),
		"angle": -65.0,
		"size": 26.0,
		"speed_zoom": true,
		"high_speed_size": 30.0
	},

	# C4 - Full world overview
	{
		"name": "WORLD_OVERVIEW",
		"locked_to_car": false,
		"follow_car": false,
		"position": Vector3(0.0, 50.0, 0.0),
		"angle": -90.0,
		"size": 115.0,
		"speed_zoom": false,
		"high_speed_size": 115.0
	}

]


# ================================================================
# GENERAL SETTINGS
# ================================================================

@export_category("Camera Movement")

@export var follow_speed: float = 8.0
@export var rotation_speed: float = 5.0
@export var transform_speed: float = 5.0
@export var zoom_speed: float = 3.0


@export_category("Speed Zoom")

@export var max_speed_reference: float = 14.0


# ================================================================
# STATE
# ================================================================

var camera_index: int = 0
var camera_mode: int = 0

var car: CharacterBody3D
var camera_pivot: Node3D
var chase_camera_pivot: Node3D
var chase_camera: Camera3D
var location_2_overview_size: float = 170.0


# ================================================================
# READY
# ================================================================

func _ready() -> void:
	car = get_node("../../Car")
	camera_pivot = get_parent()

	chase_camera_pivot = get_node(
		"../../ChaseCameraPivot"
	)

	chase_camera = chase_camera_pivot.get_child(0) as Camera3D

	apply_camera_immediately()
	make_current()


# ================================================================
# PROCESS
# ================================================================

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("camera_toggle"):
		next_camera()

	update_follow(delta)
	update_camera(delta)


# ================================================================
# FOLLOW CAR
# ================================================================

func update_follow(delta: float) -> void:
	if camera_mode == 2:
		return

	var preset: Dictionary = CAMERA_PRESETS[camera_index]

	# A camera can opt out of following the car completely.
	if preset.has("follow_car") and not preset["follow_car"]:
		camera_pivot.global_position = camera_pivot.global_position.lerp(
			Vector3.ZERO,
			clampf(
				follow_speed * delta,
				0.0,
				1.0
			)
		)
		return

	var target_position: Vector3 = car.global_position

	camera_pivot.global_position = camera_pivot.global_position.lerp(
		target_position,
		clampf(
			follow_speed * delta,
			0.0,
			1.0
		)
	)

# ================================================================
# UPDATE CURRENT CAMERA
# ================================================================

func update_camera(delta: float) -> void:
	if camera_mode == 2:
		return

	var preset: Dictionary = CAMERA_PRESETS[camera_index]

	update_camera_rotation(
		delta,
		preset
	)

	update_camera_position(
		delta,
		preset
	)

	update_camera_zoom(
		delta,
		preset
	)


# ================================================================
# CAMERA ROTATION
# ================================================================

func update_camera_rotation(
	delta: float,
	preset: Dictionary
) -> void:

	var target_pivot_rotation: float = 0.0

	if preset["locked_to_car"]:
		target_pivot_rotation = car.global_rotation.y + PI

	camera_pivot.rotation.y = lerp_angle(
		camera_pivot.rotation.y,
		target_pivot_rotation,
		clampf(
			rotation_speed * delta,
			0.0,
			1.0
		)
	)

	var target_angle: float = deg_to_rad(
		preset["angle"]
	)

	rotation.x = lerp_angle(
		rotation.x,
		target_angle,
		clampf(
			transform_speed * delta,
			0.0,
			1.0
		)
	)


# ================================================================
# CAMERA POSITION
# ================================================================

func update_camera_position(
	delta: float,
	preset: Dictionary
) -> void:

	var target_position: Vector3 = preset["position"]

	position = position.lerp(
		target_position,
		clampf(
			transform_speed * delta,
			0.0,
			1.0
		)
	)


# ================================================================
# CAMERA ZOOM
# ================================================================

func update_camera_zoom(
	delta: float,
	preset: Dictionary
) -> void:

	var target_size: float = preset["size"]
	if preset["name"] == "WORLD_OVERVIEW":
		var location: Node3D = get_node_or_null("../../Location") as Node3D

		if location != null and location.scene_file_path.ends_with("location_02_environment.tscn"):
			target_size = location_2_overview_size

	if preset["speed_zoom"]:
		var speed: float = car.velocity.length()

		var speed_ratio: float = clampf(
			speed / max_speed_reference,
			0.0,
			1.0
		)

		target_size = lerpf(
			preset["size"],
			preset["high_speed_size"],
			speed_ratio
		)

	size = lerpf(
		size,
		target_size,
		clampf(
			zoom_speed * delta,
			0.0,
			1.0
		)
	)


# ================================================================
# CHANGE CAMERA
# ================================================================

func next_camera() -> void:
	camera_mode += 1

	if camera_mode > 3:
		camera_mode = 0

	# C3 - Perspective chase camera
	if camera_mode == 2:
		chase_camera_pivot.start_transition(self)
		return

	# Existing camera
	make_current()

	if camera_mode < 2:
		camera_index = camera_mode
	else:
		camera_index = 2


# ================================================================
# INITIAL CAMERA
# ================================================================

func apply_camera_immediately() -> void:
	var preset: Dictionary = CAMERA_PRESETS[camera_index]

	position = preset["position"]
	rotation.x = deg_to_rad(
		preset["angle"]
	)

	size = preset["size"]

	if preset["locked_to_car"]:
		camera_pivot.rotation.y = (
			car.global_rotation.y + PI
		)
	else:
		camera_pivot.rotation.y = 0.0
