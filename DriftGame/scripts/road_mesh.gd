@tool
extends MeshInstance3D

@export var point_widths: PackedFloat32Array = PackedFloat32Array():
	set(value):
		point_widths = value
		update_road()

@export var road_width: float = 8.0:
	set(value):
		road_width = value
		update_road()

@export var sample_distance: float = 1.0:
	set(value):
		sample_distance = maxf(value, 0.2)
		update_road()


func _ready() -> void:
	var road_path: Path3D = get_node_or_null("../RoadPath") as Path3D

	if road_path != null and road_path.curve != null:
		road_path.curve.changed.connect(update_road)

	update_road()


func update_road() -> void:
	print("UPDATE ROAD CALLED")
	if not is_inside_tree():
		return

	var road_path: Path3D = get_node_or_null("../RoadPath") as Path3D
	print("Road path found: ", road_path != null)
	if road_path == null or road_path.curve == null:
		return

	var curve: Curve3D = road_path.curve
	print("ROAD POINT COUNT: ", curve.point_count)
	if curve.point_count < 2:
		return

	var length: float = curve.get_baked_length()
	var segment_count: int = maxi(3, ceili(length / sample_distance))
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for i in range(segment_count + 1):
		var distance: float = length * float(i) / float(segment_count)
		var next_distance: float = fmod(distance + 0.1, length)

		var centre: Vector3 = curve.sample_baked(distance)
		var next_centre: Vector3 = curve.sample_baked(next_distance)

		var direction: Vector3 = next_centre - centre
		direction.y = 0.0
		direction = direction.normalized()

		var side := Vector3(-direction.z, 0.0, direction.x)
		var current_width: float = get_width_at_distance(curve, distance)
		var left: Vector3 = centre - side * current_width * 0.5
		var right: Vector3 = centre + side * current_width * 0.5

		# Keep the asphalt slightly above the grass.
		left.y = 0.03
		right.y = 0.03

		vertices.append(left)
		vertices.append(right)

		uvs.append(Vector2(0.0, distance / 150.0))
		uvs.append(Vector2(current_width / 150.0, distance / 150.0))

		if i < segment_count:
			var base: int = i * 2
			indices.append_array([
				base, base + 2, base + 1,
				base + 1, base + 2, base + 3
			])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var generated_mesh := ArrayMesh.new()
	generated_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = generated_mesh

func get_width_at_distance(curve: Curve3D, distance: float) -> float:
	if point_widths.size() != curve.point_count:
		return road_width

	var closest_point: int = 0
	var closest_distance: float = INF

	for i in range(curve.point_count):
		var point_distance: float = curve.get_closest_offset(
			curve.get_point_position(i)
		)
		var difference: float = absf(distance - point_distance)

		if difference < closest_distance:
			closest_distance = difference
			closest_point = i

	return point_widths[closest_point]
