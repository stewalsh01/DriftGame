extends Node

const CarVisualSettings = preload(
    "res://DriftGame/scripts/car/car_visual_settings.gd"
)

# ================================================================
# WHEELS
# ================================================================

@export_category("Visual Wheels")

@export var wheel_steer_angle: float = 25.0
@export var wheel_steer_speed: float = 10.0
@export var wheel_radius: float = 0.30

var visual_config: Dictionary
var car_model: Node3D

var front_left_steer: Node3D
var front_right_steer: Node3D

var front_left_spin: Array[Node3D] = []
var front_right_spin: Array[Node3D] = []
var rear_left_spin: Array[Node3D] = []
var rear_right_spin: Array[Node3D] = []

@onready var car: CharacterBody3D = get_parent()

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

	var steer_weight: float = clampf(
		wheel_steer_speed * delta,
		0.0,
		1.0
	)

	if visual_config["steer_axis"] == "z":
		front_left_steer.rotation.z = lerp_angle(
			front_left_steer.rotation.z,
			target_angle,
			steer_weight
		)

		front_right_steer.rotation.z = lerp_angle(
			front_right_steer.rotation.z,
			target_angle,
			steer_weight
		)

	else:
		front_left_steer.rotation.y = lerp_angle(
			front_left_steer.rotation.y,
			target_angle,
			steer_weight
		)

		front_right_steer.rotation.y = lerp_angle(
			front_right_steer.rotation.y,
			target_angle,
			steer_weight
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

	for wheel: Node3D in front_left_spin:
		wheel.rotation.x = wheel_spin

	for wheel: Node3D in front_right_spin:
		wheel.rotation.x = wheel_spin

	for wheel: Node3D in rear_left_spin:
		wheel.rotation.x = wheel_spin

	for wheel: Node3D in rear_right_spin:
		wheel.rotation.x = wheel_spin


# ================================================================
# LIGHTS
# ================================================================

var brake_lights: Array[Node3D] = []


# ================================================================
# READY
# ================================================================

func _ready() -> void:
	visual_config = CarVisualSettings.get_car(
		car.selected_car
	)

	car_model = get_parent().find_child(
		visual_config["model_node"],
		true,
		false
	) as Node3D

	front_left_steer = find_visual_node(
		visual_config["front_left_steer"]
	)

	front_right_steer = find_visual_node(
		visual_config["front_right_steer"]
	)

	front_left_spin = find_visual_nodes(
		visual_config["front_left_spin"]
	)

	front_right_spin = find_visual_nodes(
		visual_config["front_right_spin"]
	)

	rear_left_spin = find_visual_nodes(
		visual_config["rear_left_spin"]
	)

	rear_right_spin = find_visual_nodes(
		visual_config["rear_right_spin"]
	)

	brake_lights = find_visual_nodes(
		visual_config["brake_lights"]
	)

	set_brake_lights(false)
	
func find_visual_node(node_name: String) -> Node3D:
	return car_model.find_child(
		node_name,
		true,
		false
	) as Node3D


func find_visual_nodes(node_names: Array) -> Array[Node3D]:
	var nodes: Array[Node3D] = []

	for node_name: String in node_names:
		var visual_node: Node3D = find_visual_node(
			node_name
		)

		if visual_node != null:
			nodes.append(visual_node)

	return nodes


# ================================================================
# BRAKE LIGHTS
# ================================================================

func set_brake_lights(enabled: bool) -> void:
	for brake_light: Node3D in brake_lights:
		brake_light.visible = enabled
	
	
