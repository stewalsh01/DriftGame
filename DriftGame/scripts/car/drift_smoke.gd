
extends Node3D

# ================================================================
# DRIFT SMOKE
# ================================================================

@export_category("Smoke Settings")
@export_range(1, 200, 1) var max_particles: int = 120
@export_range(0.1, 5.0, 0.1) var smoke_lifetime: float = 3.5

@export var smoke_color: Color = Color(0.8, 0.8, 0.8, 1.0)
@export var grass_smoke_color: Color = Color(0.55, 0.42, 0.28, 1.0)

@export_category("Smoke Intensity")
@export_range(0.0, 1.0, 0.05) var smoke_threshold: float = 0.40

@export_range(0.0, 1.0, 0.05) var light_opacity: float = 0.12
@export_range(0.0, 1.0, 0.05) var medium_opacity: float = 0.30
@export_range(0.0, 1.0, 0.05) var heavy_opacity: float = 0.55

@export_range(0.0, 1.0, 0.05) var medium_threshold: float = 0.55
@export_range(0.0, 1.0, 0.05) var heavy_threshold: float = 0.75

@export_category("Speed-Based Smoke")

# Speed is measured in metres per second.
@export_range(5.0, 50.0, 1.0)
var full_smoke_speed: float = 22.0

@export_range(0.1, 1.0, 0.05)
var low_speed_emission: float = 0.65

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

var left_emitters: Array[GPUParticles3D] = []
var right_emitters: Array[GPUParticles3D] = []

const SURFACE_ASPHALT: int = 0
const SURFACE_GRASS: int = 1

const LEVEL_LIGHT: int = 0
const LEVEL_MEDIUM: int = 1
const LEVEL_HEAVY: int = 2

var left_level: int = -1
var right_level: int = -1

var left_level_timer: float = 0.0
var right_level_timer: float = 0.0

const LEVEL_CHANGE_DELAY: float = 0.12


# ================================================================
# INITIALIZATION
# ================================================================

func _ready() -> void:
	left_emitters = create_tyre_emitters(rear_left)
	right_emitters = create_tyre_emitters(rear_right)


func create_tyre_emitters(tyre: Marker3D) -> Array[GPUParticles3D]:
	var emitters: Array[GPUParticles3D] = []

	var opacities: Array[float] = [
		light_opacity,
		medium_opacity,
		heavy_opacity
	]

	var surface_colors: Array[Color] = [
		smoke_color,
		grass_smoke_color
	]

	var surface_names: Array[String] = [
		"Asphalt",
		"Grass"
	]

	var level_names: Array[String] = [
		"Light",
		"Medium",
		"Heavy"
	]

	for surface in range(2):
		for level in range(3):
			var color: Color = surface_colors[surface]
			color.a *= opacities[level]

			var emitter: GPUParticles3D = create_smoke_emitter(
				surface_names[surface] + level_names[level],
				color
			)

			tyre.add_child(emitter)
			emitters.append(emitter)

	return emitters


# ================================================================
# PARTICLE CREATION
# ================================================================

func create_smoke_emitter(
	emitter_name: String,
	emitter_color: Color
) -> GPUParticles3D:
	var particles = GPUParticles3D.new()

	particles.name = emitter_name
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
	process_material.color = emitter_color

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

func is_tyre_on_grass(tyre: Marker3D) -> bool:
	if skid_marks == null:
		return false

	if not skid_marks.has_method("is_on_grass"):
		return false

	return skid_marks.is_on_grass(tyre.global_position)


# ================================================================
# SMOKE LEVELS
# ================================================================

func get_target_level(skid_intensity: float) -> int:
	if skid_intensity < smoke_threshold:
		return -1

	if skid_intensity >= heavy_threshold:
		return LEVEL_HEAVY

	if skid_intensity >= medium_threshold:
		return LEVEL_MEDIUM

	return LEVEL_LIGHT


func update_level(
	current_level: int,
	target_level: int,
	timer: float,
	delta: float
) -> Dictionary:
	if target_level == current_level:
		return {
			"level": current_level,
			"timer": 0.0
		}

	if target_level == -1:
		return {
			"level": -1,
			"timer": 0.0
		}

	if current_level == -1:
		return {
			"level": target_level,
			"timer": 0.0
		}

	timer += delta

	if timer >= LEVEL_CHANGE_DELAY:
		return {
			"level": target_level,
			"timer": 0.0
		}

	return {
		"level": current_level,
		"timer": timer
	}


# ================================================================
# SMOKE CONTROL
# ================================================================

func get_speed_emission_ratio() -> float:
	var car: CharacterBody3D = get_parent() as CharacterBody3D

	if car == null:
		return 1.0

	var horizontal_speed: float = Vector2(
		car.velocity.x,
		car.velocity.z
	).length()

	var speed_ratio: float = clampf(
		horizontal_speed / full_smoke_speed,
		0.0,
		1.0
	)

	return lerpf(
		low_speed_emission,
		1.0,
		speed_ratio
	)


func update_smoke(is_skidding: bool, skid_intensity: float) -> void:
	var delta: float = get_physics_process_delta_time()

	var target_level: int = -1

	if is_skidding:
		target_level = get_target_level(skid_intensity)

	var left_result: Dictionary = update_level(
		left_level,
		target_level,
		left_level_timer,
		delta
	)

	left_level = left_result["level"]
	left_level_timer = left_result["timer"]

	var right_result: Dictionary = update_level(
		right_level,
		target_level,
		right_level_timer,
		delta
	)

	right_level = right_result["level"]
	right_level_timer = right_result["timer"]

	update_tyre_emitters(
		rear_left,
		left_emitters,
		left_level
	)

	update_tyre_emitters(
		rear_right,
		right_emitters,
		right_level
	)


func update_tyre_emitters(
	tyre: Marker3D,
	emitters: Array[GPUParticles3D],
	level: int
) -> void:
	var surface: int = SURFACE_ASPHALT

	if is_tyre_on_grass(tyre):
		surface = SURFACE_GRASS

	var emission_ratio: float = get_speed_emission_ratio()

	for i in range(emitters.size()):
		var emitter: GPUParticles3D = emitters[i]

		var emitter_surface: int = floori(float(i) / 3.0)
		var emitter_level: int = i % 3

		emitter.amount_ratio = emission_ratio

		emitter.emitting = (
			level >= 0
			and emitter_surface == surface
			and emitter_level == level
		)
