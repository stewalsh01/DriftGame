@tool
extends Path3D

@export_tool_button("Smooth Curve") var smooth_button = smooth_curve


func smooth_curve() -> void:
	if curve == null or curve.point_count < 3:
		return

	var count: int = curve.point_count

	for i in range(count):
		var previous: Vector3 = curve.get_point_position(
			(i - 1 + count) % count
		)

		var current: Vector3 = curve.get_point_position(i)

		var next: Vector3 = curve.get_point_position(
			(i + 1) % count
		)

		var direction: Vector3 = (next - previous).normalized()

		var incoming_length: float = current.distance_to(previous)
		var outgoing_length: float = current.distance_to(next)

		curve.set_point_in(
			i,
			-direction * incoming_length * 0.25
		)

		curve.set_point_out(
			i,
			direction * outgoing_length * 0.25
		)
