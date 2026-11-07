
extends Control


func _ready() -> void:
	$MenuCenter/MenuBox/PlayButton.grab_focus()
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



func _on_play_button_pressed() -> void:
	$MenuSelectSound.play()
	await $MenuSelectSound.finished

	$MenuCenter.hide()
	$CarSelection.show()

	$CarSelection/CarNavigation/CarName.grab_focus()


func _on_play_button_mouse_entered() -> void:
	$MenuCenter/MenuBox/PlayButton.grab_focus()


func _on_settings_button_mouse_entered() -> void:
	$MenuCenter/MenuBox/SettingsButton.grab_focus()


func _on_quit_button_mouse_entered() -> void:
	$MenuCenter/MenuBox/QuitButton.grab_focus()



func _on_back_button_pressed() -> void:
	$MenuSelectSound.play()
	await $MenuSelectSound.finished

	$CarSelection.hide()
	$MenuCenter.show()

	$MenuCenter/MenuBox/PlayButton.grab_focus()



func _on_settings_button_pressed() -> void:
	$MenuSelectSound.play()
	await $MenuSelectSound.finished

	$MenuCenter.hide()
	$SettingsMenu.show()

	var master_bus: int = AudioServer.get_bus_index("Master")
	var is_muted: bool = AudioServer.is_bus_mute(master_bus)

	if is_muted:
		$SettingsMenu/SettingsBox/SoundButton.text = "SOUND: OFF"
	else:
		$SettingsMenu/SettingsBox/SoundButton.text = "SOUND: ON"

	$SettingsMenu/SettingsBox/SoundButton.grab_focus()


func _on_sound_button_pressed() -> void:
	var master_bus: int = AudioServer.get_bus_index("Master")
	var is_muted: bool = AudioServer.is_bus_mute(master_bus)

	AudioServer.set_bus_mute(master_bus, not is_muted)

	if is_muted:
		$SettingsMenu/SettingsBox/SoundButton.text = "SOUND: ON"
	else:
		$SettingsMenu/SettingsBox/SoundButton.text = "SOUND: OFF"


func _on_settings_back_button_pressed() -> void:
	$MenuSelectSound.play()
	await $MenuSelectSound.finished

	$SettingsMenu.hide()
	$MenuCenter.show()

	$MenuCenter/MenuBox/SettingsButton.grab_focus()
