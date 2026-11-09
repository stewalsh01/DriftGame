
extends Node3D

func apply_time_of_day(location: Node3D, is_day: bool) -> void:
	var sun: DirectionalLight3D = location.get_node_or_null("Sun")

	if sun:
		if is_day:
			sun.light_energy = 1.5
			sun.rotation_degrees = Vector3(-45.0, -35.0, 0.0)
			sun.shadow_enabled = true
		else:
			sun.light_energy = 0.0

	_set_track_lights(location, not is_day)


func _set_track_lights(node: Node, enabled: bool) -> void:
	for child in node.get_children():
		if child is Light3D and not child is DirectionalLight3D:
			child.visible = enabled

		_set_track_lights(child, enabled)


func apply_car_lights(is_day: bool) -> void:
	var car: Node3D = get_parent().get_node("Car")

	for light in car.find_children("*", "Light3D", true, false):
		if light.name.begins_with("Headlight") or light.name.begins_with("TailLight"):
			light.visible = not is_day
