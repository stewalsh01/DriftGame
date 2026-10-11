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
