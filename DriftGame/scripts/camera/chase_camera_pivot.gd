extends Node3D


@export var target: Node3D
@export var position_speed: float = 12.0
@export var rotation_speed: float = 2.5
@export var transition_speed: float = 5.0

@onready var chase_camera: Camera3D = get_child(0) as Camera3D

var chase_position: Vector3
var chase_rotation: Vector3
var transitioning: bool = false


func _ready() -> void:
	chase_position = chase_camera.position
	chase_rotation = chase_camera.rotation


func _physics_process(delta: float) -> void:
	if target == null:
		return

	global_position = global_position.lerp(
		target.global_position,
		clampf(
			position_speed * delta,
			0.0,
			1.0
		)
	)

	global_rotation.y = lerp_angle(
		global_rotation.y,
		target.global_rotation.y + PI,
		clampf(
			rotation_speed * delta,
			0.0,
			1.0
		)
	)

	if transitioning:
		update_transition(delta)


func start_transition(from_camera: Camera3D) -> void:
	chase_camera.global_transform = from_camera.global_transform

	chase_camera.make_current()
	transitioning = true


func update_transition(delta: float) -> void:
	var weight: float = clampf(
		transition_speed * delta,
		0.0,
		1.0
	)

	chase_camera.position = chase_camera.position.lerp(
		chase_position,
		weight
	)

	chase_camera.rotation.x = lerp_angle(
		chase_camera.rotation.x,
		chase_rotation.x,
		weight
	)

	chase_camera.rotation.y = lerp_angle(
		chase_camera.rotation.y,
		chase_rotation.y,
		weight
	)

	chase_camera.rotation.z = lerp_angle(
		chase_camera.rotation.z,
		chase_rotation.z,
		weight
	)

	if (
		chase_camera.position.distance_to(chase_position) < 0.01
		and chase_camera.rotation.distance_to(chase_rotation) < 0.01
	):
		chase_camera.position = chase_position
		chase_camera.rotation = chase_rotation
		transitioning = false
