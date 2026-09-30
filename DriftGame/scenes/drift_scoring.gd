extends Node

@export var minimum_speed: float = 3.0
@export var minimum_drift_angle: float = 10.0
@export var points_per_second: float = 100.0

@onready var car: CharacterBody3D = $"../Car"
@onready var score_label: Label = $"../HUD/DriftScoreLabel"
@onready var combo_label: Label = $"../HUD/ComboLabel"
@onready var total_label: Label = $"../HUD/TotalScoreLabel"
@onready var banked_score_label: Label = $"../HUD/BankedScoreLabel"
@onready var skid_marks = $"../SkidMarks"

var grass_area: Area3D = null
var current_drift_score: float = 0.0
var total_score: int = 0

@export var combo_window: float = 0.5
var combo_timer: float = 0.0

var combo_multiplier: int = 1
var was_scoring: bool = false

var drift_invalidated: bool = false
var lost_score_timer: float = 0.0

func _physics_process(delta: float) -> void:
	var speed: float = car.get_horizontal_velocity().length()
	var drift_angle: float = absf(
		car.get_drift_angle(car.get_horizontal_velocity())
	)

	var is_scoring: bool = (
		car.drive_state == car.DriveState.DRIFT
		and speed >= minimum_speed
		and drift_angle >= minimum_drift_angle
	)
	
	var on_grass: bool = skid_marks.is_on_grass(car.global_position)

	# Touching grass invalidates the current drift.
	if on_grass:
		if not drift_invalidated and current_drift_score > 0.0:
			score_label.text = "%d" % roundi(current_drift_score)
			score_label.add_theme_color_override("font_color", Color("#FF6666"))
			score_label.visible = true
			lost_score_timer = 1.0

		drift_invalidated = true
		current_drift_score = 0.0
		combo_multiplier = 1
		combo_timer = 0.0

	# Only allow scoring again after the car has returned to
	# asphalt AND the previous drift has ended.
	if not on_grass and car.drive_state != car.DriveState.DRIFT:
		drift_invalidated = false

	if drift_invalidated:
		is_scoring = false

	if is_scoring:
		if current_drift_score == 0.0:
			score_label.pivot_offset = score_label.size / 2.0
			score_label.scale = Vector2.ONE

			var score_tween: Tween = create_tween()
			score_tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.12)
			score_tween.tween_property(score_label, "scale", Vector2.ONE, 0.25)
		# Increase the multiplier when a new drift links to the previous one.
		if not was_scoring and current_drift_score > 0.0:
			combo_multiplier += 1

			combo_label.pivot_offset = combo_label.size / 2.0

			var combo_tween: Tween = create_tween()
			combo_tween.tween_property(combo_label, "scale", Vector2(1.2, 1.2), 0.12)
			combo_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.25)
		# A new drift continues the current combo.
		combo_timer = combo_window

		var angle_multiplier: float = clampf(
			drift_angle / 20.0,
			0.5,
			4.0
		)

		current_drift_score += (
			points_per_second
			* angle_multiplier
			* delta
		)

	elif current_drift_score > 0.0:
		# Give the player time to start another drift.
		combo_timer = maxf(combo_timer - delta, 0.0)

		if combo_timer <= 0.0:
			var final_score: int = roundi(
				current_drift_score * combo_multiplier
			)

			total_score += final_score
			banked_score_label.text = "+%d" % final_score
			banked_score_label.visible = true
			total_label.add_theme_color_override("font_color", Color("#55ff66"))
			total_label.pivot_offset = Vector2(0, total_label.size.y)

			var pop_tween: Tween = create_tween()
			pop_tween.tween_property(total_label, "scale", Vector2(1.2, 1.2), 0.12)
			pop_tween.tween_property(total_label, "scale", Vector2.ONE, 0.25)

			current_drift_score = 0.0
			combo_multiplier = 1

			await get_tree().create_timer(1.5).timeout
			banked_score_label.visible = false
			total_label.remove_theme_color_override("font_color")
		
	if lost_score_timer > 0.0:
		lost_score_timer = maxf(lost_score_timer - delta, 0.0)
		score_label.visible = true

		if lost_score_timer == 0.0:
			score_label.remove_theme_color_override("font_color")
			score_label.visible = false
	else:
		score_label.text = "%d" % roundi(current_drift_score)
		score_label.visible = current_drift_score > 0.0
	
	combo_label.text = "×%d COMBO" % combo_multiplier
	combo_label.visible = (
		current_drift_score > 0.0
		and combo_multiplier >= 2
	)
	total_label.text = "TOTAL: %d" % total_score
	was_scoring = is_scoring
