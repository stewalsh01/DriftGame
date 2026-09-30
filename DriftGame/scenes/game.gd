extends Node3D


func _ready() -> void:
	var selected_location: Node3D = LocationSelection.selected_location.instantiate()
	selected_location.name = "Location"
	add_child(selected_location)

	var skid_marks = $SkidMarks
	skid_marks.grass_area = selected_location.get_node("GrassDetection01")
