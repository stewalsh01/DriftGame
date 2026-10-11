
@tool
extends MeshInstance3D

@export var point_widths: PackedFloat32Array = PackedFloat32Array():
	set(value):
		point_widths = value
		update_road()

@export var road_width: float = 12.0:
	set(value):
		road_width = maxf(value, 1.0)
		update_road()

@export var sample_distance: float = 1.0:
	set(value):
		sample_distance = maxf(value, 0.2)
		update_road()

@export var road_height_offset: float = 0.15:
	set(value):
		road_height_offset = value
		update_road()

@export_range(1, 40, 1) var smoothing_samples: int = 12:
	set(value):
		smoothing_samples = maxi(value, 1)
		update_road()


func _ready() -> void:
	var road_path: Path3D = get_node_or_null("../RoadPath") as Path3D

	if road_path != null and road_path.curve != null:
		road_path.curve.changed.connect(update_road)

	update_road()


func update_road() -> void:
	if not is_inside_tree():
		return

	var road_path: Path3D = get_node_or_null("../RoadPath") as Path3D
	if road_path == null or road_path.curve == null:
		return

	var curve: Curve3D = road_path.curve

	if curve.point_count < 2:
		mesh = null
		return

	var length: float = curve.get_baked_length()
	if length <= 0.0:
		return

	var segment_count: int = maxi(3, ceili(length / sample_distance))
	var is_closed: bool = curve.closed

	var centres: Array[Vector3] = []
	var heights: Array[float] = []

	# Sample the terrain beneath the centre of the road.
	for i in range(segment_count + 1):
		var distance: float = length * float(i) / float(segment_count)
		var centre: Vector3 = curve.sample_baked(distance)

		var world_centre: Vector3 = road_path.to_global(centre)
		var terrain_height: float = get_terrain_height(world_centre)

		centres.append(to_local(world_centre))
		heights.append(world_centre.y)

	# Smooth elevation along the road.
	var smoothed_heights: Array[float] = []

	for i in range(heights.size()):
		var total: float = 0.0
		var count: int = 0

		for offset in range(-smoothing_samples, smoothing_samples + 1):
			var index: int = i + offset

			if is_closed:
				index = posmod(index, segment_count)
			else:
				index = clampi(index, 0, segment_count)

			total += heights[index]
			count += 1

		smoothed_heights.append(total / float(count))

	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for i in range(segment_count + 1):
		var distance: float = length * float(i) / float(segment_count)

		var previous_index: int = maxi(i - 1, 0)
		var next_index: int = mini(i + 1, segment_count)

		if is_closed:
			previous_index = posmod(i - 1, segment_count)
			next_index = posmod(i + 1, segment_count)

		var direction: Vector3 = centres[next_index] - centres[previous_index]
		direction.y = 0.0

		if direction.length_squared() < 0.000001:
			direction = Vector3.FORWARD
		else:
			direction = direction.normalized()

		var side: Vector3 = Vector3(-direction.z, 0.0, direction.x)
		var current_width: float = get_width_at_distance(curve, distance)

		var centre: Vector3 = centres[i]
		var world_height: float = smoothed_heights[i] + road_height_offset

		var left: Vector3 = centre - side * current_width * 0.5
		var right: Vector3 = centre + side * current_width * 0.5

		left.y = to_local(Vector3(0.0, world_height, 0.0)).y
		right.y = left.y

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
	generated_mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		arrays
	)

	mesh = generated_mesh


func get_terrain_height(world_position: Vector3) -> float:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

	var ray_start: Vector3 = world_position + Vector3.UP * 500.0
	var ray_end: Vector3 = world_position + Vector3.DOWN * 500.0

	var query := PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end
	)

	query.collision_mask = 1

	var result: Dictionary = space_state.intersect_ray(query)

	if result.is_empty():
		return world_position.y

	return result["position"].y


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
