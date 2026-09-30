extends Node3D


func _ready() -> void:
	var selected_location: Node3D = LocationSelection.selected_location.instantiate()
	selected_location.name = "Location"
	add_child(selected_location)

	var car: CharacterBody3D = $Car
	car.global_transform = selected_location.get_node("CarSpawn").global_transform

	var skid_marks = $SkidMarks
	skid_marks.grass_area = selected_location.get_node_or_null("GrassDetection01")
	$DriftScoring.grass_area = selected_location.get_node_or_null("GrassDetection01")
	
	skid_marks.road_path = selected_location.get_node_or_null("Racetrack/RoadPath")
	skid_marks.road_mesh = selected_location.get_node_or_null("Racetrack/RoadMesh")

	if skid_marks.road_mesh != null:
		skid_marks.road_width = skid_marks.road_mesh.road_width

	var start_finish_line: Node3D = selected_location.get_node_or_null(
		"CarSpawn/StartFinishLine"
	)

	var is_track_mode: bool = start_finish_line != null

	$HUD/LapInfoPanel.visible = is_track_mode
	$HUD/LapInfoBackground.visible = is_track_mode
	$HUD/LapInfoAccent.visible = is_track_mode
	$HUD/LapDriftScoreLabel.visible = is_track_mode
	$HUD/BestLapScoreLabel.visible = is_track_mode
	$HUD/LastLapScoreLabel.visible = is_track_mode

	$HUD/TotalScoreLabel.visible = not is_track_mode
	$HUD/LapInfoPanel.visible = is_track_mode
	$HUD/LapDriftScoreLabel.visible = is_track_mode

	if start_finish_line != null:
		start_finish_line.car_crossed.connect(
			$LapManager._on_car_crossed
		)
	
	$DriftScoring.score_banked.connect($LapManager._on_score_banked)
