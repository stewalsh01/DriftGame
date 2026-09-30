extends Control


# ================================================================
# REFERENCES
# ================================================================

@onready var car: CharacterBody3D = $"../../Car"


# ================================================================
# DIAL
# ================================================================

@export_category("Dial")

@export var dial_radius: float = 125.0

@export var start_angle: float = 135.0
@export var end_angle: float = 405.0

@export var outline_width: float = 4.0

@export var major_tick_length: float = 22.0
@export var minor_tick_length: float = 10.0

@export var major_tick_width: float = 7.0
@export var minor_tick_width: float = 3.0

@export var redline_rpm: float = 6500.0


# ================================================================
# NUMBERS
# ================================================================

@export_category("Numbers")

@export var number_size: int = 28
@export var number_radius_offset: float = 47.0


# ================================================================
# NEEDLE
# ================================================================

@export_category("Needle")

@export var needle_length: float = 94.0
@export var needle_width: float = 6.0
@export var needle_tail_length: float = 14.0


# ================================================================
# NEEDLE BOUNCE
# ================================================================

@export_category("Needle Bounce")

@export var bounce_start_rpm: float = 7850.0
@export var bounce_amount: float = 1.5
@export var bounce_speed: float = 28.0


# ================================================================
# GLOW
# ================================================================

@export_category("Glow")

@export var glow_enabled: bool = true

@export_range(0.0, 1.0, 0.01)
var outer_glow_strength: float = 0.12

@export_range(0.0, 1.0, 0.01)
var redline_glow_strength: float = 0.28

@export var glow_width: float = 10.0


# ================================================================
# READY
# ================================================================

func _ready() -> void:
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


# ================================================================
# DRAW
# ================================================================

func _draw() -> void:
	var center: Vector2 = size * 0.5

	draw_glow(center)
	draw_dial_outline(center)
	draw_ticks(center)
	draw_numbers(center)
	draw_rpm_text(center)
	draw_needle(center)
	draw_center(center)


# ================================================================
# GLOW
# ================================================================

func draw_glow(center: Vector2) -> void:
	if not glow_enabled:
		return

	# ------------------------------------------------
	# DARK GAUGE FACE
	# ------------------------------------------------

	draw_circle(
		center,
		dial_radius - 2.0,
		Color(
			0.02,
			0.02,
			0.02,
			0.38
		)
	)


	# ------------------------------------------------
	# SUBTLE OUTER HALO
	# ------------------------------------------------

	var gap_start: float = deg_to_rad(45.0)
	var gap_end: float = deg_to_rad(135.0)

	draw_arc(
		center,
		dial_radius + 4.0,
		gap_end,
		TAU + gap_start,
		128,
		Color(1.0, 1.0, 1.0, 0.06),
		12.0,
		true
	)

	draw_arc(
		center,
		dial_radius + 3.0,
		gap_end,
		TAU + gap_start,
		128,
		Color(1.0, 1.0, 1.0, 0.10),
		6.0,
		true
	)


	# ------------------------------------------------
	# REDLINE ANGLE
	# ------------------------------------------------

	var redline_ratio: float = clampf(
		redline_rpm / 8000.0,
		0.0,
		1.0
	)

	var redline_angle: float = deg_to_rad(
		lerpf(
			start_angle,
			end_angle,
			redline_ratio
		)
	)

	var redline_end: float = deg_to_rad(
		end_angle
	)


	# ------------------------------------------------
	# RED OUTER GLOW
	# ------------------------------------------------

	# Wide faint layer.
	draw_arc(
		center,
		dial_radius + 5.0,
		redline_angle,
		redline_end,
		48,
		Color(
			1.0,
			0.0,
			0.0,
			0.08
		),
		22.0,
		true
	)

	# Medium glow layer.
	draw_arc(
		center,
		dial_radius + 4.0,
		redline_angle,
		redline_end,
		48,
		Color(
			1.0,
			0.0,
			0.0,
			0.16
		),
		13.0,
		true
	)

	# Bright inner glow.
	draw_arc(
		center,
		dial_radius + 3.0,
		redline_angle,
		redline_end,
		48,
		Color(
			1.0,
			0.05,
			0.02,
			0.35
		),
		6.0,
		true
	)


# ================================================================
# DIAL OUTLINE
# ================================================================

func draw_dial_outline(center: Vector2) -> void:
	# Open bottom section between 0 and 8.
	var gap_start: float = deg_to_rad(45.0)
	var gap_end: float = deg_to_rad(135.0)

	draw_arc(
		center,
		dial_radius,
		gap_end,
		TAU + gap_start,
		128,
		Color.WHITE,
		outline_width,
		true
	)


# ================================================================
# TICKS
# ================================================================

func draw_ticks(center: Vector2) -> void:
	var total_minor_ticks: int = 40

	for i in range(total_minor_ticks + 1):
		var ratio: float = (
			float(i) / float(total_minor_ticks)
		)

		var rpm_value: float = (
			ratio * 8000.0
		)

		var angle: float = deg_to_rad(
			lerpf(
				start_angle,
				end_angle,
				ratio
			)
		)

		var is_major: bool = (
			i % 5 == 0
		)

		var tick_length: float = minor_tick_length
		var tick_width: float = minor_tick_width

		if is_major:
			tick_length = major_tick_length
			tick_width = major_tick_width

		var tick_color: Color = Color.WHITE

		if rpm_value >= redline_rpm:
			tick_color = Color.RED

			tick_length += 3.0
			tick_width += 2.0

		var direction: Vector2 = Vector2(
			cos(angle),
			sin(angle)
		)

		var outer_point: Vector2 = (
			center
			+ direction * dial_radius
		)

		var inner_point: Vector2 = (
			center
			+ direction
			* (dial_radius - tick_length)
		)

		draw_line(
			inner_point,
			outer_point,
			tick_color,
			tick_width,
			true
		)


# ================================================================
# NUMBERS
# ================================================================

func draw_numbers(center: Vector2) -> void:
	var font: Font = ThemeDB.fallback_font

	for number in range(9):
		var ratio: float = (
			float(number) / 8.0
		)

		var angle: float = deg_to_rad(
			lerpf(
				start_angle,
				end_angle,
				ratio
			)
		)

		var direction: Vector2 = Vector2(
			cos(angle),
			sin(angle)
		)

		var number_position: Vector2 = (
			center
			+ direction
			* (
				dial_radius
				- number_radius_offset
			)
		)

		var text: String = str(number)

		var text_size: Vector2 = (
			font.get_string_size(
				text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				number_size
			)
		)

		draw_string(
			font,
			number_position
			- Vector2(
				text_size.x * 0.5,
				-text_size.y * 0.35
			),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			number_size,
			Color.WHITE
		)


# ================================================================
# RPM TEXT
# ================================================================

func draw_rpm_text(center: Vector2) -> void:
	var font: Font = ThemeDB.fallback_font

	draw_string(
		font,
		center + Vector2(-27.0, 52.0),
		"x1000",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color.WHITE
	)

	draw_string(
		font,
		center + Vector2(-20.0, 70.0),
		"RPM",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		15,
		Color(
			1.0,
			0.25,
			0.15,
			1.0
		)
	)


# ================================================================
# NEEDLE
# ================================================================

func draw_needle(center: Vector2) -> void:
	var rpm_ratio: float = clampf(
		car.rpm / car.max_rpm,
		0.0,
		1.0
	)

	var needle_angle: float = lerpf(
		start_angle,
		end_angle,
		rpm_ratio
	)

	if car.rpm >= bounce_start_rpm:
		var bounce: float = sin(
			Time.get_ticks_msec()
			/ 1000.0
			* bounce_speed
		)

		needle_angle += (
			bounce
			* bounce_amount
		)

	var angle: float = deg_to_rad(
		needle_angle
	)

	var direction: Vector2 = Vector2(
		cos(angle),
		sin(angle)
	)

	var needle_end: Vector2 = (
		center
		+ direction * needle_length
	)

	var needle_back: Vector2 = (
		center
		- direction * needle_tail_length
	)

	# Needle shadow.
	draw_line(
		needle_back,
		needle_end,
		Color(
			0.05,
			0.05,
			0.05,
			1.0
		),
		needle_width + 4.0,
		true
	)

	# Red needle.
	draw_line(
		needle_back,
		needle_end,
		Color.RED,
		needle_width,
		true
	)


# ================================================================
# CENTER CAP
# ================================================================

func draw_center(center: Vector2) -> void:
	draw_circle(
		center,
		11.0,
		Color(
			0.05,
			0.05,
			0.05,
			1.0
		)
	)

	draw_circle(
		center,
		6.0,
		Color.RED
	)
