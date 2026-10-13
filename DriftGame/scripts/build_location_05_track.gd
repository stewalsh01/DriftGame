
@tool
extends Path3D

const TRACK_SCALE := 1.4

const TRACK_POINTS := [
	[15.29585, 54.29836, -14.85883, -7.866444, 14.85883, 7.866444],
	[43.48393, 18.46236, -26.65848, 3.277686, 26.65848, -3.277686],
	[57.68721, 39.87655, -17.69949, -1.529587, 17.69949, 1.529587],
	[60.96489, -28.95482, -0.218506, 3.496197, 0.218506, -3.496197],
	[51.13185, -58.01694, 14.64032, 5.244293, -14.64032, -5.244293],
	[22.06973, -51.89857, 3.714706, -5.244297, -3.714706, 5.244297],
	[7.429413, -8.633157, 13.76628, -7.429418, -13.76628, 7.429418],
	[-22.50676, -4.699937, 13.76627, 1.092561, -13.76627, -1.092561],
	[-62.27598, 17.36979, 8.303452, -12.45519, -8.303452, 12.45519],
	[-62.93151, 59.97964, -13.11074, -13.54775, 13.11074, 13.54775],
	[-28.8436, 58.66856, -14.6403, 5.681309, 14.6403, -5.681309],
	[-6.992401, 37.9099, -6.555359, 1.311081, 6.555359, -1.311081],
	[12.67371, 15.40319, -14.64032, -1.529586, 14.64032, 1.529586]
]

func _ready() -> void:
	if not Engine.is_editor_hint():
		return

	# Only run when editing Location 5.
	var scene_root := get_tree().edited_scene_root
	if scene_root == null or scene_root.name != "Location05":
		return

	build_track()


func build_track() -> void:
	var new_curve := Curve3D.new()

	for point in TRACK_POINTS:
		var position := Vector3(point[0], 0.0, point[1]) * TRACK_SCALE
		var in_handle := Vector3(point[2], 0.0, point[3]) * TRACK_SCALE
		var out_handle := Vector3(point[4], 0.0, point[5]) * TRACK_SCALE

		new_curve.add_point(position, in_handle, out_handle)

	new_curve.closed = true
	curve = new_curve

	print("Location 5 track rebuilt with ", curve.point_count, " points.")
