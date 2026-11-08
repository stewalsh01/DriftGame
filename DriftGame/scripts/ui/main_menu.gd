
extends Control


# NODE REFERENCES

@onready var menu_center: Control = $MenuCenter
@onready var car_selection: Control = $CarSelection
@onready var settings_menu: Control = $SettingsMenu

@onready var play_button: Button = $MenuCenter/MenuBox/PlayButton
@onready var settings_button: Button = $MenuCenter/MenuBox/SettingsButton
@onready var quit_button: Button = $MenuCenter/MenuBox/QuitButton

@onready var car_name_button: Button = $CarSelection/CarNavigation/CarName

@onready var sound_button: Button = $SettingsMenu/SettingsBox/SoundButton
@onready var settings_back_button: Button = $SettingsMenu/SettingsBox/BackButton

@onready var menu_select_sound: AudioStreamPlayer = $MenuSelectSound
@onready var menu_move_sound: AudioStreamPlayer = $MenuMoveSound

@onready var track_selection: Control = $TrackSelection
@onready var track_name_button: Button = $TrackSelection/TrackNavigation/TrackName


var suppress_focus_sound: bool = false


func _ready() -> void:
	menu_center.show()
	car_selection.hide()
	track_selection.hide()
	settings_menu.hide()

	_grab_focus_silently(play_button)
	menu_move_sound.stop()


# MAIN MENU

func _on_play_button_pressed() -> void:
	await _play_select_sound()

	menu_center.hide()
	car_selection.show()

	_grab_focus_silently(car_name_button)


func _on_settings_button_pressed() -> void:
	await _play_select_sound()

	menu_center.hide()
	settings_menu.show()

	_update_sound_button()
	_grab_focus_silently(sound_button)


func _on_quit_button_pressed() -> void:
	await _play_select_sound()
	get_tree().quit()


# CAR SELECTION

func _on_back_button_pressed() -> void:
	await _play_select_sound()

	car_selection.hide()
	menu_center.show()

	_grab_focus_silently(play_button)


# SETTINGS

func _on_sound_button_pressed() -> void:
	var master_bus: int = AudioServer.get_bus_index("Master")
	var is_muted: bool = AudioServer.is_bus_mute(master_bus)

	AudioServer.set_bus_mute(master_bus, not is_muted)
	_update_sound_button()


func _update_sound_button() -> void:
	var master_bus: int = AudioServer.get_bus_index("Master")
	var is_muted: bool = AudioServer.is_bus_mute(master_bus)

	sound_button.text = "SOUND: OFF" if is_muted else "SOUND: ON"


func _on_settings_back_button_pressed() -> void:
	await _play_select_sound()

	settings_menu.hide()
	menu_center.show()

	_grab_focus_silently(settings_button)


# LEGACY TRACK BUTTONS
# Temporary shortcuts until Track Selection is implemented.

func _on_demo_track_button_pressed() -> void:
	await _play_select_sound()

	LocationSelection.selected_location = preload(
		"res://DriftGame/scenes/location_demo_track.tscn"
	)
	get_tree().change_scene_to_file("res://DriftGame/scenes/game.tscn")


func _on_location_4_button_pressed() -> void:
	await _play_select_sound()

	LocationSelection.selected_location = preload(
		"res://DriftGame/scenes/location_oval_track.tscn"
	)
	get_tree().change_scene_to_file("res://DriftGame/scenes/game.tscn")


func _on_location_1_button_pressed() -> void:
	await _play_select_sound()

	LocationSelection.selected_location = preload(
		"res://DriftGame/scenes/location_drift_yard.tscn"
	)
	get_tree().change_scene_to_file("res://DriftGame/scenes/game.tscn")


# MOUSE HOVER

func _on_track_time_button_mouse_entered(button: Button) -> void:
	button.grab_focus()

func _on_play_button_mouse_entered() -> void:
	play_button.grab_focus()


func _on_settings_button_mouse_entered() -> void:
	settings_button.grab_focus()


func _on_quit_button_mouse_entered() -> void:
	quit_button.grab_focus()


func _on_sound_button_mouse_entered() -> void:
	sound_button.grab_focus()


func _on_settings_back_button_mouse_entered() -> void:
	settings_back_button.grab_focus()


# FOCUS SOUNDS

func _on_button_focus_entered() -> void:
	if suppress_focus_sound:
		return

	menu_move_sound.play()


func _on_menu_button_focus_entered() -> void:
	_on_button_focus_entered()


func _on_quit_button_focus_entered() -> void:
	_on_button_focus_entered()


func _on_demo_track_button_focus_entered() -> void:
	_on_button_focus_entered()


func _on_location_4_button_focus_entered() -> void:
	_on_button_focus_entered()


func _on_location_1_button_focus_entered() -> void:
	_on_button_focus_entered()


func _on_play_button_focus_entered() -> void:
	_on_button_focus_entered()


func _on_settings_button_focus_entered() -> void:
	_on_button_focus_entered()


func _on_sound_button_focus_entered() -> void:
	_on_button_focus_entered()


func _on_back_button_focus_entered() -> void:
	_on_button_focus_entered()


func _on_previous_car_button_focus_entered() -> void:
	_on_button_focus_entered()


func _on_car_name_focus_entered() -> void:
	_on_button_focus_entered()


func _on_next_car_button_focus_entered() -> void:
	_on_button_focus_entered()


# SHARED HELPERS

func _play_select_sound() -> void:
	menu_select_sound.play()
	await menu_select_sound.finished


func _grab_focus_silently(button: Button) -> void:
	suppress_focus_sound = true
	button.grab_focus()
	suppress_focus_sound = false


func _on_car_selection_car_selected(car_index: int) -> void:
	LocationSelection.selected_car = car_index
	await _play_select_sound()
	car_selection.hide()
	track_selection.show()
	_grab_focus_silently(track_name_button)


func _on_track_selection_track_selected(track_scene: PackedScene) -> void:
	LocationSelection.selected_location = track_scene
	await _play_select_sound()
	get_tree().change_scene_to_file("res://DriftGame/scenes/game.tscn")


func _on_track_back_button_pressed() -> void:
	await _play_select_sound()
	track_selection.hide()
	car_selection.show()
	_grab_focus_silently(car_name_button)


func _on_previous_time_button_mouse_entered() -> void:
	$TrackSelection/TimeOfDaySelection/PreviousTimeButton.grab_focus()


func _on_time_of_day_button_mouse_entered() -> void:
	$TrackSelection/TimeOfDaySelection/TimeOfDayButton.grab_focus()


func _on_next_time_button_mouse_entered() -> void:
	$TrackSelection/TimeOfDaySelection/NextTimeButton.grab_focus()
