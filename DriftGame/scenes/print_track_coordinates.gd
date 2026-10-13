
@tool
extends Path3D

func _ready() -> void:
	if not Engine.is_editor_hint():
		return

	if curve == null:
		return

	print("\n--- ORIGINAL TRACK COORDINATES ---")
	print("Closed: ", curve.closed)

	for i in range(curve.point_count):
		print(
			i,
			" | Position: ", curve.get_point_position(i),
			" | In: ", curve.get_point_in(i),
			" | Out: ", curve.get_point_out(i)
		)
