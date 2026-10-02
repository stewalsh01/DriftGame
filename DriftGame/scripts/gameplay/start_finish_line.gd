extends Node3D

@export var crossing_direction: Vector3 = Vector3(0, 0, 1)

signal car_crossed

func _on_crossing_detector_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return

	var movement: Vector3 = body.get_horizontal_velocity()

	# Ignore crossings when the car is nearly stationary.
	if movement.length() < 0.5:
		return

	# Convert the configured direction from the line's
	# local coordinates into a world-space direction.
	var world_direction: Vector3 = (
		global_transform.basis * crossing_direction
	).normalized()

	# Only count movement through the line in the correct direction.
	if movement.dot(world_direction) <= 0.0:
		return

	car_crossed.emit()
