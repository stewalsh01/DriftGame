extends Control


func _ready() -> void:
	$MenuCenter/MenuBox/Location1Button.grab_focus()


func _on_location_1_button_pressed() -> void:
	LocationSelection.selected_location = preload(
		"res://DriftGame/scenes/location_01_environment.tscn"
	)
	get_tree().change_scene_to_file("res://DriftGame/scenes/game.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_location_2_button_pressed() -> void:
	LocationSelection.selected_location = preload(
		"res://DriftGame/scenes/location_02_environment.tscn"
	)
	get_tree().change_scene_to_file("res://DriftGame/scenes/game.tscn")
