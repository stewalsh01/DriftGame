extends Node3D

# ================================================================
# SKID MARKS SYSTEM
# ================================================================
# Creates dynamic skid marks on surfaces as the car drifts
# Features:
# - Adaptive darkness based on skid intensity
# - Surface-based materials (asphalt vs grass)
# - Performance-conscious (max marks limit)
# - Proper surface alignment

# ================================================================
# CONSTANTS
# ================================================================

const MARK_WIDTH: float = 0.16
const MARK_HEIGHT: float = 0.008
const MIN_MARK_DISTANCE: float = 0.01

const RAYCAST_UP_OFFSET: float = 0.1
const RAYCAST_DOWN_OFFSET: float = 0.25
const MARK_SURFACE_OFFSET: float = 0.035

const ASPHALT_BASE_COLOR: Color = Color(0.02, 0.02, 0.02)
const ASPHALT_MIN_OPACITY: float = 0.18
const ASPHALT_MAX_OPACITY: float = 1.0

const GRASS_MARK_COLOR: Color = Color(0.30, 0.16, 0.06, 1.0)

const DEFAULT_ROAD_WIDTH: float = 8.0
const ROAD_EDGE_THRESHOLD: float = 0.5

# ================================================================
# EXPORTS
# ================================================================

@export_category("Skid Marks")
@export var mark_width: float = MARK_WIDTH
@export var mark_height: float = MARK_HEIGHT

@export_range(2, 16, 1)
var darkness_steps: int = 8

@export_category("Performance")
@export_range(1, 20000, 1)
var max_marks: int = 5000

@export_category("References")
@export var car_path: NodePath

# ================================================================
# NODES
# ================================================================

@onready var car: CollisionObject3D = get_node(car_path) as CollisionObject3D if has_node(car_path) else null

# ================================================================
# STATE
# ================================================================

var mark_materials: Array[StandardMaterial3D] = []
var marks: Array[MeshInstance3D] = []
var grass_mark_material: StandardMaterial3D

var grass_area: Area3D = null
var road_path: Path3D = null
var road_mesh: MeshInstance3D = null
var road_width: float = DEFAULT_ROAD_WIDTH

# ================================================================
# INITIALIZATION
# ================================================================

func _ready() -> void:
	create_mark_materials()

# ================================================================
# SURFACE DETECTION
# ================================================================

func is_on_grass(world_position: Vector3) -> bool:
	if road_path != null:
		return is_outside_road_bounds(world_position)

	if grass_area != null:
		return is_inside_grass_area(world_position)

	return false

func is_outside_road_bounds(world_position: Vector3) -> bool:
	var curve = road_path.curve
	if curve == null:
		return false

	var local_position = road_path.to_local(world_position)
	var closest_offset = curve.get_closest_offset(local_position)
	var closest_point = curve.sample_baked(closest_offset)

	var distance_from_road = Vector2(
		local_position.x - closest_point.x,
		local_position.z - closest_point.z
	).length()

	var current_width = road_width
	if road_mesh != null:
		current_width = road_mesh.get_width_at_distance(curve, closest_offset)

	return distance_from_road > current_width * ROAD_EDGE_THRESHOLD

func is_inside_grass_area(world_position: Vector3) -> bool:
	var shape = grass_area.get_node("CollisionShape3D") if grass_area.has_node("CollisionShape3D") else null
	if shape == null:
		return false

	var cylinder = shape.shape as CylinderShape3D
	if cylinder == null:
		return false

	var local_position = grass_area.to_local(world_position)
	var distance_from_center = Vector2(local_position.x, local_position.z).length()

	return distance_from_center <= cylinder.radius

# ================================================================
# MATERIAL CREATION
# ================================================================

func create_mark_materials() -> void:
	mark_materials.clear()

	# Create asphalt materials with varying opacity
	for i in range(darkness_steps):
		var material = create_asphalt_material(i)
		mark_materials.append(material)

	# Create grass material
	grass_mark_material = create_grass_material()

func create_asphalt_material(step: int) -> StandardMaterial3D:
	var ratio = float(step) / float(darkness_steps - 1)
	var opacity = lerpf(ASPHALT_MIN_OPACITY, ASPHALT_MAX_OPACITY, ratio)

	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(
		ASPHALT_BASE_COLOR.r,
		ASPHALT_BASE_COLOR.g,
		ASPHALT_BASE_COLOR.b,
		opacity
	)
	material.roughness = 1.0

	return material

func create_grass_material() -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = GRASS_MARK_COLOR
	material.roughness = 1.0
	return material

# ================================================================
# GROUND DETECTION
# ================================================================

func get_ground_point(world_position: Vector3) -> Dictionary:
	if car == null:
		return {}

	var space_state = get_world_3d().direct_space_state

	var query = PhysicsRayQueryParameters3D.create(
		world_position + Vector3.UP * RAYCAST_UP_OFFSET,
		world_position + Vector3.DOWN * RAYCAST_DOWN_OFFSET
	)

	query.exclude = [car.get_rid()]

	return space_state.intersect_ray(query)

# ================================================================
# MARK CREATION
# ================================================================

func create_mark(from_position: Vector3, to_position: Vector3, skid_intensity: float) -> void:
	# Find ground points
	var from_hit = get_ground_point(from_position)
	var to_hit = get_ground_point(to_position)

	if from_hit.is_empty() or to_hit.is_empty():
		return

	# Use ground-aligned positions
	from_position = from_hit.position
	to_position = to_hit.position

	# Check minimum distance
	var distance = from_position.distance_to(to_position)
	if distance < MIN_MARK_DISTANCE:
		return

	# Create mark mesh
	var mark = create_mark_mesh(distance, skid_intensity, from_position, to_position)

	add_child(mark)

	position_mark(mark, from_position, to_position, from_hit.normal, to_hit.normal)

	marks.append(mark)
	remove_old_marks()

func create_mark_mesh(distance: float, skid_intensity: float, from_pos: Vector3, to_pos: Vector3) -> MeshInstance3D:
	var mark = MeshInstance3D.new()
	var mesh = BoxMesh.new()

	mesh.size = Vector3(mark_width, mark_height, distance)

	# Choose material based on surface
	var midpoint = (from_pos + to_pos) * 0.5
	mesh.material = get_mark_material(midpoint, skid_intensity)

	mark.mesh = mesh
	return mark

func get_mark_material(world_position: Vector3, skid_intensity: float) -> StandardMaterial3D:
	if is_on_grass(world_position):
		return grass_mark_material

	# Calculate darkness from skid intensity
	var clamped_intensity = clampf(skid_intensity, 0.0, 1.0)
	var darkness_ratio = pow(clamped_intensity, 2.0)
	var material_index = int(round(darkness_ratio * float(mark_materials.size() - 1)))

	return mark_materials[material_index]

func position_mark(mark: MeshInstance3D, from_pos: Vector3, to_pos: Vector3, from_normal: Vector3, to_normal: Vector3) -> void:
	# Calculate position
	var midpoint = (from_pos + to_pos) * 0.5
	var surface_normal = (from_normal + to_normal).normalized()

	# Calculate orientation
	var direction = (to_pos - from_pos).normalized()
	var mark_basis = calculate_mark_basis(direction, surface_normal)

	mark.global_transform = Transform3D(
		mark_basis,
		midpoint + surface_normal * MARK_SURFACE_OFFSET
	)

func calculate_mark_basis(direction: Vector3, surface_normal: Vector3) -> Basis:
	# Build a stable orientation aligned to surface
	var right = surface_normal.cross(direction).normalized()
	var forward = right.cross(surface_normal).normalized()

	return Basis(right, surface_normal, forward).orthonormalized()

# ================================================================
# CLEANUP
# ================================================================

func remove_old_marks() -> void:
	while marks.size() > max_marks:
		var oldest_mark = marks.pop_front()
		if oldest_mark:
			oldest_mark.queue_free()
