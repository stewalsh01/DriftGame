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
