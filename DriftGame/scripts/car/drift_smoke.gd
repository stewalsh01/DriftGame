
extends Node3D

# ================================================================
# DRIFT SMOKE
# ================================================================

@export_category("Smoke Settings")
@export_range(1, 200, 1) var max_particles: int = 60
@export_range(0.1, 5.0, 0.1) var smoke_lifetime: float = 1.5

@export var smoke_color: Color = Color(0.8, 0.8, 0.8, 0.25)
@export var grass_smoke_color: Color = Color(0.55, 0.42, 0.28, 0.25)

@export_category("Smoke Intensity")
@export_range(0.0, 1.0, 0.05)
var smoke_threshold: float = 0.60

@export_range(0.0, 1.0, 0.05)
var min_smoke_opacity: float = 0.08

@export_range(0.0, 1.0, 0.05)
var max_smoke_opacity: float = 0.55

@export_category("Surface Detection")
@export var skid_marks_path: NodePath


# ================================================================
# REFERENCES
# ================================================================

@onready var rear_left: Marker3D = $"../RearLeftTyre"
@onready var rear_right: Marker3D = $"../RearRightTyre"

@onready var skid_marks: Node3D = get_node_or_null(skid_marks_path) as Node3D


# ================================================================
# STATE
# ================================================================

var rear_left_emitter: GPUParticles3D
var rear_right_emitter: GPUParticles3D


# ================================================================
# INITIALIZATION
# ================================================================

func _ready() -> void:
	rear_left_emitter = create_smoke_emitter()
	rear_right_emitter = create_smoke_emitter()

	rear_left.add_child(rear_left_emitter)
	rear_right.add_child(rear_right_emitter)


# ================================================================
# PARTICLE CREATION
# ================================================================

func create_smoke_emitter() -> GPUParticles3D:
	var particles = GPUParticles3D.new()

	particles.emitting = false
	particles.amount = max_particles
	particles.lifetime = smoke_lifetime
	particles.local_coords = false

	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3.UP
	process_material.spread = 35.0
	process_material.initial_velocity_min = 0.5
	process_material.initial_velocity_max = 1.5
	process_material.gravity = Vector3(0, 0.4, 0)
	process_material.color = smoke_color

	particles.process_material = process_material

	# ============================================================
	# SMOKE TEXTURE
	# ============================================================

	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.8, 0.8)

	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)

	for y in range(64):
		for x in range(64):
			var uv = Vector2(x, y) / 63.0
			var distance = uv.distance_to(Vector2(0.5, 0.5)) * 2.0
			var alpha = pow(clampf(1.0 - distance, 0.0, 1.0), 2.0)

			image.set_pixel(
				x,
				y,
				Color(1.0, 1.0, 1.0, alpha)
			)

	var texture = ImageTexture.create_from_image(image)

	# ============================================================
	# SMOKE MATERIAL
	# ============================================================

	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.albedo_texture = texture
	material.vertex_color_use_as_albedo = true
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	mesh.material = material
	particles.draw_pass_1 = mesh

	return particles


# ================================================================
# SURFACE DETECTION
# ================================================================

func get_smoke_color(world_position: Vector3) -> Color:
	if skid_marks != null and skid_marks.has_method("is_on_grass"):
		if skid_marks.is_on_grass(world_position):
			return grass_smoke_color

	return smoke_color


# ================================================================
# SMOKE CONTROL
# ================================================================

func update_smoke(is_skidding: bool, skid_intensity: float) -> void:
	var should_emit: bool = (
		is_skidding
		and skid_intensity >= smoke_threshold
	)

	var opacity: float = 0.0

	if should_emit:
		var intensity_ratio: float = inverse_lerp(
			smoke_threshold,
			1.0,
			clampf(skid_intensity, smoke_threshold, 1.0)
		)

		opacity = lerpf(
			min_smoke_opacity,
			max_smoke_opacity,
			intensity_ratio
		)

	var emitters: Array[GPUParticles3D] = [
		rear_left_emitter,
		rear_right_emitter
	]

	var tyres: Array[Marker3D] = [
		rear_left,
		rear_right
	]

	for i in range(emitters.size()):
		var emitter = emitters[i]

		if emitter == null:
			continue

		emitter.emitting = should_emit

		if should_emit:
			var surface_color: Color = get_smoke_color(
				tyres[i].global_position
			)

			var process_material = emitter.process_material as ParticleProcessMaterial

			if process_material == null:
				continue

			process_material.color = Color(
				surface_color.r,
				surface_color.g,
				surface_color.b,
				opacity
			)
