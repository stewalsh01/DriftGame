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
# MATERIALS
# ================================================================

var mark_materials: Array[StandardMaterial3D] = []
var marks: Array[MeshInstance3D] = []
var grass_mark_material: StandardMaterial3D
@onready var grass_area: Area3D = $"../GrassRoundaboutArea"

# ================================================================
# READY
# ================================================================

func _ready() -> void:
	create_mark_materials()
	
# ================================================================
# SURFACE DETECTION
# ================================================================

func is_on_grass(position: Vector3) -> bool:
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
			0.12,
			0.95,
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
# CREATE MARK
# ================================================================

func create_mark(
	from_position: Vector3,
	to_position: Vector3,
	skid_intensity: float
) -> void:
	var distance: float = from_position.distance_to(
		to_position
	)

	if distance < 0.01:
		return

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

	mark.mesh = mesh

	add_child(mark)
	
	marks.append(mark)

	remove_old_marks()


	# ------------------------------------------------
	# POSITION
	# ------------------------------------------------

	var midpoint: Vector3 = (
		from_position + to_position
	) * 0.5

	mark.global_position = Vector3(
		midpoint.x,
		0.035,
		midpoint.z
	)


	# ------------------------------------------------
	# ROTATION
	# ------------------------------------------------

	var direction: Vector3 = (
		to_position - from_position
	)

	var angle: float = atan2(
		direction.x,
		direction.z
	)

	mark.rotation.y = angle
	
# ================================================================
# CLEANUP
# ================================================================

func remove_old_marks() -> void:
	while marks.size() > max_marks:
		var oldest_mark: MeshInstance3D = (
			marks.pop_front()
		)

		oldest_mark.queue_free()
