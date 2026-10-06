@tool
extends MeshInstance3D

@export var hill_length: float = 30.0
@export var hill_width: float = 12.0
@export var hill_height: float = 3.0
@export_range(4, 100, 1) var segments: int = 30


func _ready() -> void:
	build_hill()


func build_hill() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_length: float = hill_length * 0.5
	var half_width: float = hill_width * 0.5

	for i in range(segments):
		var t1: float = float(i) / float(segments)
		var t2: float = float(i + 1) / float(segments)

		var z1: float = lerpf(-half_length, half_length, t1)
		var z2: float = lerpf(-half_length, half_length, t2)

		var y1: float = sin(t1 * PI) * hill_height
		var y2: float = sin(t2 * PI) * hill_height

		var left_1 := Vector3(-half_width, y1, z1)
		var right_1 := Vector3(half_width, y1, z1)
		var left_2 := Vector3(-half_width, y2, z2)
		var right_2 := Vector3(half_width, y2, z2)

		surface.add_vertex(left_1)
		surface.add_vertex(right_1)
		surface.add_vertex(left_2)

		surface.add_vertex(right_1)
		surface.add_vertex(right_2)
		surface.add_vertex(left_2)

	surface.generate_normals()

	var generated_mesh: ArrayMesh = surface.commit()

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.35, 0.1)
	generated_mesh.surface_set_material(0, material)

	mesh = generated_mesh
