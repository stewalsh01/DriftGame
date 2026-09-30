extends Node3D

@onready var lap_label: Label = $"../HUD/LapInfoPanel/LapInfoRow/LapSection/LapLabel"
@onready var lap_timer_label: Label = $"../HUD/LapInfoPanel/LapInfoRow/TimeSection/LapTimerLabel"
@onready var lap_drift_score_label: Label = $"../HUD/LapDriftScoreLabel"
@onready var total_score_label: Label = $"../HUD/TotalScoreLabel"
@onready var drift_scoring = $"../DriftScoring"
@onready var best_lap_score_label: Label = $"../HUD/BestLapScoreLabel"
@onready var last_lap_score_label: Label = $"../HUD/LastLapScoreLabel"

var current_lap: int = 0
var lap_time: float = 0.0
var lap_running: bool = false
var lap_drift_score: int = 0
var best_lap_score: int = 0

func _on_car_crossed() -> void:
	if not lap_running:
		current_lap = 1
		lap_time = 0.0
		lap_running = true
		print("Lap 1 started")
	else:
		drift_scoring.bank_current_drift()

		last_lap_score_label.text = "LAST LAP SCORE: %d" % lap_drift_score

		if lap_drift_score > best_lap_score:
			best_lap_score = lap_drift_score
			best_lap_score_label.text = "BEST LAP SCORE: %d" % best_lap_score

		print("Lap %d completed in %.2f seconds" % [current_lap, lap_time])
		current_lap += 1
		lap_drift_score = 0
		lap_drift_score_label.text = "LAP SCORE: 0"
		lap_time = 0.0
		print("Lap %d started" % current_lap)
	
	lap_label.text = "%d" % current_lap

func _physics_process(delta: float) -> void:
	if lap_running:
		lap_time += delta

	var minutes: int = int(lap_time) / 60
	var seconds: int = int(lap_time) % 60
	var hundredths: int = int((lap_time - floorf(lap_time)) * 100.0)

	lap_timer_label.text = "%02d:%02d.%02d" % [
		minutes,
		seconds,
		hundredths
	]
	
func _on_score_banked(points: int) -> void:
	if not lap_running:
		return

	lap_drift_score += points
	lap_drift_score_label.text = "LAP SCORE: %d" % lap_drift_score

	lap_drift_score_label.add_theme_color_override(
		"font_color", Color("#55ff66")
	)

	lap_drift_score_label.pivot_offset = Vector2(
		0,
		lap_drift_score_label.size.y
	)

	var pop_tween: Tween = create_tween()
	pop_tween.tween_property(
		lap_drift_score_label, "scale", Vector2(1.2, 1.2), 0.12
	)
	pop_tween.tween_property(
		lap_drift_score_label, "scale", Vector2.ONE, 0.25
	)

	await get_tree().create_timer(1.5).timeout
	lap_drift_score_label.remove_theme_color_override("font_color")
