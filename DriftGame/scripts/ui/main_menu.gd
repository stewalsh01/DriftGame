
extends Control


func _ready() -> void:
	$MenuCenter/MenuBox/DemoTrackButton.grab_focus()
	$MenuMoveSound.stop()


func _on_demo_track_button_pressed() -> void:
	$MenuSelectSound.play()
	await $MenuSelectSound.finished

	LocationSelection.selected_location = preload(
		"res://DriftGame/scenes/location_demo_track.tscn"
	)
	get_tree().change_scene_to_file("res://DriftGame/scenes/game.tscn")


func _on_location_4_button_pressed() -> void:
	$MenuSelectSound.play()
	await $MenuSelectSound.finished

	LocationSelection.selected_location = preload(
		"res://DriftGame/scenes/location_oval_track.tscn"
	)
	get_tree().change_scene_to_file("res://DriftGame/scenes/game.tscn")


func _on_location_1_button_pressed() -> void:
	$MenuSelectSound.play()
	await $MenuSelectSound.finished

	LocationSelection.selected_location = preload(
		"res://DriftGame/scenes/location_drift_yard.tscn"
	)
	get_tree().change_scene_to_file("res://DriftGame/scenes/game.tscn")


func _on_quit_button_pressed() -> void:
	$MenuSelectSound.play()
	await $MenuSelectSound.finished
	get_tree().quit()


func _on_demo_track_button_focus_entered() -> void:
	$MenuMoveSound.play()


func _on_location_4_button_focus_entered() -> void:
	$MenuMoveSound.play()


func _on_location_1_button_focus_entered() -> void:
	$MenuMoveSound.play()


func _on_quit_button_focus_entered() -> void:
	$MenuMoveSound.play()


func _on_menu_button_focus_entered() -> void:
	$MenuMoveSound.play()
