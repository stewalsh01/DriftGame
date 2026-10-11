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
		var point: Vector3 = curve.sample_baked(distance)

		var previous_distance: float = maxf(
			0.0,
			distance - sample_distance
		)

		var next_distance: float = minf(
			length,
			distance + sample_distance
		)

		var previous: Vector3 = curve.sample_baked(previous_distance)
		var next: Vector3 = curve.sample_baked(next_distance)

		if curve.closed:
			previous = curve.sample_baked(
				fposmod(distance - sample_distance, length)
			)

			next = curve.sample_baked(
				fposmod(distance + sample_distance, length)
			)

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

		var world_centre: Vector3 = road_path.to_global(point)
		world_centre.y += road_height_offset

		var world_left: Vector3 = world_centre - side * road_width * 0.5
		var world_right: Vector3 = world_centre + side * road_width * 0.5

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

	for i in range(segment_count + 1):
		var distance: float = length * float(i) / float(segment_count)
		var point: Vector3 = road_path.to_global(
			curve.sample_baked(distance)
		)
		point.y += road_height_offset
		road_points.append(point)

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
		var nearest_height: float = 0.0

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
				nearest_height = lerpf(start.y, finish.y, t)

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

		# Keep the terrain slightly below the asphalt.
		var target_height: float = nearest_height - 0.03

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
