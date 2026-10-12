@tool
extends MeshInstance3D

@export_tool_button("Generate Road") var generate_button = update_road

@export_range(2.0, 30.0, 0.5) var road_width: float = 12.0:
	set(value):
		road_width = value
		update_road()

@export_range(0.25, 5.0, 0.25) var sample_distance: float = 1.0:
	set(value):
		sample_distance = value
		update_road()

@export var road_height_offset: float = 0.05:
	set(value):
		road_height_offset = value
		update_road()

@export_group("Road Banking")

@export_range(-45.0, 45.0, 0.5, "degrees")
var banking_angle: float = 0.0:
	set(value):
		banking_angle = value
		update_road()

@export_group("Terrain Blending")

@export_range(1.0, 20.0, 0.5) var shoulder_width: float = 5.0

@export_range(0.0, 1.0, 0.05) var shoulder_smoothing: float = 1.0

@export_tool_button("Generate Terrain Shoulders")
var generate_shoulders_button = generate_terrain_shoulders

func _ready() -> void:
	var road_path: Path3D = get_node_or_null("../RoadPath") as Path3D

	if road_path != null and road_path.curve != null:
		if not road_path.curve.changed.is_connected(update_road):
			road_path.curve.changed.connect(update_road)

	update_road()


func update_road() -> void:
	if not is_inside_tree():
		return

	var road_path: Path3D = get_node_or_null("../RoadPath") as Path3D
	var road_body: StaticBody3D = get_node_or_null(
		"../RoadCollision"
	) as StaticBody3D
	var collision_shape: CollisionShape3D = get_node_or_null(
		"../RoadCollision/CollisionShape3D"
	) as CollisionShape3D

	if road_path == null or road_path.curve == null:
		return

	var curve: Curve3D = road_path.curve

	if curve.point_count < 2:
		return

	var length: float = curve.get_baked_length()

	if length <= 0.0:
		return

	var segment_count: int = maxi(
		3,
		ceili(length / sample_distance)
	)

	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for i in range(segment_count + 1):
		var distance: float = length * float(i) / float(segment_count)

		var edges: Array[Vector3] = get_road_edges(
			road_path,
			distance
		)

		if edges.size() != 2:
			return

		var world_left: Vector3 = edges[0]
		var world_right: Vector3 = edges[1]

		vertices.append(to_local(world_left))
		vertices.append(to_local(world_right))

		uvs.append(Vector2(0.0, distance / 20.0))
		uvs.append(Vector2(road_width / 20.0, distance / 20.0))

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

	# Use the same triangles for the road's collision.
	if collision_shape != null and road_body != null:
		var collision_vertices := PackedVector3Array()

		for index in indices:
			collision_vertices.append(vertices[index])

		var road_shape := ConcavePolygonShape3D.new()
		road_shape.set_faces(collision_vertices)

		# The collision body is a sibling of RoadMesh.
		# Convert vertices into the collision body's local space.
		if road_body.transform != transform:
			var transformed_vertices := PackedVector3Array()

			for vertex in collision_vertices:
				var world_vertex: Vector3 = to_global(vertex)
				transformed_vertices.append(road_body.to_local(world_vertex))

			road_shape.set_faces(transformed_vertices)

		collision_shape.shape = road_shape

func get_road_edges(
	road_path: Path3D,
	distance: float
) -> Array[Vector3]:
	var curve: Curve3D = road_path.curve
	var length: float = curve.get_baked_length()

	if length <= 0.0:
		return []

	var previous_distance: float = distance - sample_distance
	var next_distance: float = distance + sample_distance

	if curve.closed:
		previous_distance = fposmod(previous_distance, length)
		next_distance = fposmod(next_distance, length)
	else:
		previous_distance = clampf(previous_distance, 0.0, length)
		next_distance = clampf(next_distance, 0.0, length)

	var previous: Vector3 = curve.sample_baked(previous_distance)
	var next: Vector3 = curve.sample_baked(next_distance)

	var direction: Vector3 = next - previous
	direction.y = 0.0

	if direction.length_squared() < 0.000001:
		direction = Vector3.FORWARD
	else:
		direction = direction.normalized()

	var side := Vector3(
		-direction.z,
		0.0,
		direction.x
	)

	var centre: Vector3 = road_path.to_global(
		curve.sample_baked(distance)
	)
	centre.y += road_height_offset

	var bank: float = clampf(
		get_bank_at_distance(curve, distance),
		deg_to_rad(-45.0),
		deg_to_rad(45.0)
	)

	var bank_height: float = tan(bank) * road_width * 0.5

	var left: Vector3 = centre - side * road_width * 0.5
	var right: Vector3 = centre + side * road_width * 0.5

	left.y -= bank_height
	right.y += bank_height

	return [left, right]

func get_bank_at_distance(curve: Curve3D, distance: float) -> float:
	var point_count: int = curve.point_count

	if point_count < 2:
		return deg_to_rad(banking_angle)

	var length: float = curve.get_baked_length()

	if length <= 0.0:
		return deg_to_rad(banking_angle)

	# Calculate the distance along the curve for each control point.
	var point_distances := PackedFloat32Array()

	for i in range(point_count):
		var control_position: Vector3 = curve.get_point_position(i)
		var closest_distance: float = 0.0
		var closest_difference: float = INF

		var sample_count: int = maxi(100, ceili(length / 0.5))

		for j in range(sample_count + 1):
			var sample_distance_along: float = length * float(j) / float(sample_count)
			var sample_position: Vector3 = curve.sample_baked(sample_distance_along)
			var difference: float = control_position.distance_squared_to(sample_position)

			if difference < closest_difference:
				closest_difference = difference
				closest_distance = sample_distance_along

		point_distances.append(closest_distance)

	# Find the segment containing our road sample.
	var sample_at: float = clampf(distance, 0.0, length)

	for i in range(point_count):
		var next_index: int = i + 1
		var start_distance: float = point_distances[i]
		var end_distance: float

		if next_index >= point_count:
			if not curve.closed:
				break

			next_index = 0
			end_distance = length
		else:
			end_distance = point_distances[next_index]

		if sample_at >= start_distance and sample_at <= end_distance:
			var segment_length: float = end_distance - start_distance

			if segment_length <= 0.0001:
				return deg_to_rad(banking_angle) + curve.get_point_tilt(i)

			var blend: float = (sample_at - start_distance) / segment_length

			# Smooth the transition between control points.
			blend = blend * blend * (3.0 - 2.0 * blend)

			return deg_to_rad(banking_angle) + lerp_angle(
				curve.get_point_tilt(i),
				curve.get_point_tilt(next_index),
				blend
			)

	return deg_to_rad(banking_angle)

func get_width_at_distance(_curve: Curve3D, _distance: float) -> float:
	return road_width


func generate_terrain_shoulders() -> void:
	if not Engine.is_editor_hint():
		return

	var road_path := get_node_or_null("../RoadPath") as Path3D
	var terrain := get_node_or_null("../../Terrain3D") as Terrain3D

	if road_path == null or road_path.curve == null or terrain == null:
		push_error("RoadPath or Terrain3D not found.")
		return

	var curve: Curve3D = road_path.curve
	var length: float = curve.get_baked_length()

	if length <= 0.0:
		return

	var data: Terrain3DData = terrain.data
	var half_width: float = road_width * 0.5
	var total_width: float = half_width + shoulder_width
	var segment_count: int = maxi(3, ceili(length / sample_distance))

	# Sample the road centreline in world coordinates.
	var road_points: Array[Vector3] = []
	var road_left_edges: Array[Vector3] = []
	var road_right_edges: Array[Vector3] = []

	# Sample the exact same road edges used by the road mesh.
	for i in range(segment_count + 1):
		var distance: float = length * float(i) / float(segment_count)

		var edges: Array[Vector3] = get_road_edges(
			road_path,
			distance
		)

		if edges.size() != 2:
			return

		var left: Vector3 = edges[0]
		var right: Vector3 = edges[1]

		road_left_edges.append(left)
		road_right_edges.append(right)
		road_points.append((left + right) * 0.5)

	# Find terrain pixels inside the road and shoulder area.
	var affected_pixels: Dictionary = {}

	for i in range(segment_count):
		var start: Vector3 = road_points[i]
		var finish: Vector3 = road_points[i + 1]

		var min_x: int = floori(minf(start.x, finish.x) - total_width - 1.0)
		var max_x: int = ceili(maxf(start.x, finish.x) + total_width + 1.0)
		var min_z: int = floori(minf(start.z, finish.z) - total_width - 1.0)
		var max_z: int = ceili(maxf(start.z, finish.z) + total_width + 1.0)

		for x in range(min_x, max_x + 1):
			for z in range(min_z, max_z + 1):
				affected_pixels[Vector2i(x, z)] = true

	var changes: Dictionary = {}

	for pixel: Vector2i in affected_pixels:
		var position_2d := Vector2(float(pixel.x), float(pixel.y))
		var nearest_distance: float = INF
		var nearest_side: float = 0.0
		var nearest_left: Vector3 = Vector3.ZERO
		var nearest_right: Vector3 = Vector3.ZERO

		# Find the closest point on any road segment.
		for i in range(segment_count):
			var start: Vector3 = road_points[i]
			var finish: Vector3 = road_points[i + 1]

			var a := Vector2(start.x, start.z)
			var b := Vector2(finish.x, finish.z)
			var segment := b - a

			var t: float = 0.0

			if segment.length_squared() > 0.000001:
				t = clampf(
					(position_2d - a).dot(segment) / segment.length_squared(),
					0.0,
					1.0
				)

			var nearest := a.lerp(b, t)
			var distance_to_road: float = position_2d.distance_to(nearest)

			if distance_to_road < nearest_distance:
				nearest_distance = distance_to_road

				nearest_left = road_left_edges[i].lerp(road_left_edges[i + 1], t)
				nearest_right = road_right_edges[i].lerp(road_right_edges[i + 1], t)

				if segment.length_squared() > 0.000001:
					nearest_side = segment.cross(position_2d - nearest) / segment.length()
				else:
					nearest_side = 0.0

		if nearest_distance > total_width:
			continue

		var terrain_position := Vector3(
			float(pixel.x),
			0.0,
			float(pixel.y)
		)

		var original_height: float = data.get_height(terrain_position)

		if is_nan(original_height):
			continue

		# Match the road's banked surface at this lateral position.
		# Calculate the height directly from the road's actual edges.
		var lateral_progress: float = clampf(
			(nearest_side + half_width) / road_width,
			0.0,
			1.0
		)

		var road_surface_height: float = lerpf(
			nearest_left.y,
			nearest_right.y,
			lateral_progress
		)

		var edge_progress: float = clampf(
			nearest_distance / half_width,
			0.0,
			1.0
		)

		var bank_angle: float = atan2(
			nearest_right.y - nearest_left.y,
			road_width
		)

		var bank_strength: float = clampf(
			absf(bank_angle) / deg_to_rad(25.0),
			0.0,
			1.0
		)

		# No edge clearance on flat roads.
		# Increase to 2 cm on heavily banked sections.
		var edge_clearance: float = lerpf(
			0.0,
			0.04,
			bank_strength
		)

		var clearance: float = lerpf(
			0.10,
			edge_clearance,
			edge_progress
		)

		# Additional clearance beneath steep banking.
		clearance += 0.03 * bank_strength * (1.0 - edge_progress)

		var target_height: float = road_surface_height - clearance

		var weight: float = 1.0

		if nearest_distance > half_width:
			var blend: float = clampf(
				(nearest_distance - half_width) / shoulder_width,
				0.0,
				1.0
			)

			var smooth_blend: float = blend * blend * (3.0 - 2.0 * blend)
			blend = lerpf(blend, smooth_blend, shoulder_smoothing)
			weight = 1.0 - blend

		changes[pixel] = lerpf(original_height, target_height, weight)

	# Apply each terrain pixel exactly once.
	for pixel: Vector2i in changes:
		data.set_height(
			Vector3(float(pixel.x), 0.0, float(pixel.y)),
			changes[pixel]
		)

	data.update_maps()

	print("Terrain shoulders generated: ", changes.size(), " pixels")
