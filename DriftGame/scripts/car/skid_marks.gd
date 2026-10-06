extends Node3D


# ================================================================
# SETTINGS
# ================================================================

@export_category("Skid Marks")

@export var mark_width: float = 0.16
@export var mark_height: float = 0.008

@export_range(2, 16, 1)
var darkness_steps: int = 8

@export_category("Performance")

@export var max_marks: int = 5000


# ================================================================
# REFERENCES
# ================================================================

@export var car_path: NodePath

@onready var car: CollisionObject3D = (
	get_node(car_path) as CollisionObject3D
)

# ================================================================
# MATERIALS
# ================================================================

var mark_materials: Array[StandardMaterial3D] = []
var marks: Array[MeshInstance3D] = []
var grass_mark_material: StandardMaterial3D
@export var grass_area_path: NodePath

var grass_area: Area3D
var road_path: Path3D
var road_width: float = 8.0
var road_mesh: MeshInstance3D

# ================================================================
# READY
# ================================================================

func _ready() -> void:
	create_mark_materials()
	
# ================================================================
# SURFACE DETECTION
# ================================================================

func is_on_grass(position: Vector3) -> bool:
	# Location 2: grass is everywhere outside the road.
	if road_path != null:
		var local_position: Vector3 = road_path.to_local(position)
		var curve: Curve3D = road_path.curve

		if curve == null:
			return false

		var closest_offset: float = curve.get_closest_offset(local_position)
		var closest_point: Vector3 = curve.sample_baked(closest_offset)

		var distance_from_road: float = Vector2(
			local_position.x - closest_point.x,
			local_position.z - closest_point.z
		).length()

		var current_width: float = road_width

		if road_mesh != null:
			current_width = road_mesh.get_width_at_distance(curve, closest_offset)

		return distance_from_road > current_width * 0.5

	# Location 1: keep the existing circular grass detection.
	if grass_area == null:
		return false

	var shape: CollisionShape3D = grass_area.get_node("CollisionShape3D")
	var cylinder: CylinderShape3D = shape.shape as CylinderShape3D

	if cylinder == null:
		return false

	var local_position: Vector3 = grass_area.to_local(position)

	var distance_from_center: float = Vector2(
		local_position.x,
		local_position.z
	).length()

	return distance_from_center <= cylinder.radius


# ================================================================
# CREATE MATERIALS
# ================================================================

func create_mark_materials() -> void:
	mark_materials.clear()

	for i in range(darkness_steps):
		var ratio: float = float(i) / float(
			darkness_steps - 1
		)

		var material: StandardMaterial3D = (
			StandardMaterial3D.new()
		)

		var opacity: float = lerpf(
			0.18,
			1.0,
			ratio
		)

		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

		material.albedo_color = Color(
			0.02,
			0.02,
			0.02,
			opacity
		)

		material.roughness = 1.0

		mark_materials.append(
			material
		)
		
	grass_mark_material = StandardMaterial3D.new()

	grass_mark_material.albedo_color = Color(
		0.30,
		0.16,
		0.06,
		1.0
	)

	grass_mark_material.roughness = 1.0

# ================================================================
# GROUND DETECTION
# ================================================================

func get_ground_point(position: Vector3) -> Dictionary:
	var space_state := get_world_3d().direct_space_state

	var query := PhysicsRayQueryParameters3D.create(
		position + Vector3.UP * 0.1,
		position + Vector3.DOWN * 0.25
	)

	query.exclude = [
		car.get_rid()
	]

	return space_state.intersect_ray(query)

# ================================================================
# CREATE MARK
# ================================================================

func create_mark(
	from_position: Vector3,
	to_position: Vector3,
	skid_intensity: float
) -> void:

	# ------------------------------------------------
	# FIND GROUND
	# ------------------------------------------------

	var from_hit := get_ground_point(
		from_position
	)

	var to_hit := get_ground_point(
		to_position
	)

	if from_hit.is_empty() or to_hit.is_empty():
		return

	from_position = from_hit.position
	to_position = to_hit.position


	# ------------------------------------------------
	# DISTANCE
	# ------------------------------------------------

	var distance: float = from_position.distance_to(
		to_position
	)

	if distance < 0.01:
		return


	# ------------------------------------------------
	# CREATE MESH
	# ------------------------------------------------

	var mark: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()

	mesh.size = Vector3(
		mark_width,
		mark_height,
		distance
	)

	# ------------------------------------------------
	# CHOOSE DARKNESS FROM RPM
	# ------------------------------------------------

	var clamped_ratio: float = clampf(
		skid_intensity,
		0.0,
		1.0
	)
	
	var darkness_ratio: float = pow(
		clamped_ratio,
		2.0
	)

	var material_index: int = int(
		round(
			darkness_ratio
			* float(mark_materials.size() - 1)
		)
	)

	if is_on_grass(
		(from_position + to_position) * 0.5
	):
		mesh.material = grass_mark_material
	else:
		mesh.material = mark_materials[
			material_index
		]

	var test_position := (
		from_position + to_position
	) * 0.5

	mark.mesh = mesh

	add_child(mark)
	
	marks.append(mark)

	remove_old_marks()

	# ------------------------------------------------
	# POSITION + ROTATION
	# ------------------------------------------------

	var midpoint: Vector3 = (
		from_position + to_position
	) * 0.5

	var surface_normal: Vector3 = (
		from_hit.normal + to_hit.normal
	).normalized()

	var direction: Vector3 = (
		to_position - from_position
	).normalized()

	# Build a stable orientation.
	var right: Vector3 = (
		surface_normal.cross(direction)
	).normalized()

	var forward: Vector3 = (
		right.cross(surface_normal)
	).normalized()

	var basis := Basis(
		right,
		surface_normal,
		forward
	).orthonormalized()

	mark.global_transform = Transform3D(
		basis,
		midpoint + surface_normal * 0.035
	)
	
# ================================================================
# CLEANUP
# ================================================================

func remove_old_marks() -> void:
	while marks.size() > max_marks:
		var oldest_mark: MeshInstance3D = (
			marks.pop_front()
		)

		oldest_mark.queue_free()
