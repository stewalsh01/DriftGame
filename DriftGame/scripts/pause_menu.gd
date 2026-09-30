extends Control


@onready var resume_button: Button = %ResumeButton

@onready var menu_center: Control = $Background/MenuCenter
@onready var options_center: Control = $Background/OptionsCenter

@onready var options_button: Button = $Background/MenuCenter.find_child(
	"OptionsButton",
	true,
	false
) as Button

@onready var sound_button: Button = $Background/OptionsCenter.find_child(
	"SoundButton",
	true,
	false
) as Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if options_center.visible:
			show_pause_menu()
		else:
			toggle_pause()

func show_pause_menu() -> void:
	options_center.hide()
	menu_center.show()

	options_button.grab_focus()

func toggle_pause() -> void:
	var is_paused: bool = not get_tree().paused

	get_tree().paused = is_paused
	visible = is_paused

	if is_paused:
		resume_button.grab_focus()
		$MenuMoveSound.stop()


func _on_resume_button_pressed() -> void:
	$MenuSelectSound.play()
	await $MenuSelectSound.finished

	get_tree().paused = false
	hide()


func _on_restart_button_pressed() -> void:
	$MenuSelectSound.play()
	await $MenuSelectSound.finished

	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_main_menu_button_pressed() -> void:
	$MenuSelectSound.play()
	await $MenuSelectSound.finished

	get_tree().paused = false
	get_tree().change_scene_to_file(
        "res://DriftGame/scenes/main_menu.tscn"
	)


func _on_quit_button_pressed() -> void:
	$MenuSelectSound.play()
	await $MenuSelectSound.finished

	get_tree().paused = false
	get_tree().quit()

func _on_menu_button_focus_entered() -> void:
	$MenuMoveSound.play()


func _on_resume_button_focus_entered() -> void:
	$MenuMoveSound.play()


func _on_restart_button_focus_entered() -> void:
	$MenuMoveSound.play()


func _on_main_menu_button_focus_entered() -> void:
	$MenuMoveSound.play()


func _on_quit_button_focus_entered() -> void:
	$MenuMoveSound.play()


func _on_options_button_pressed() -> void:
	$MenuSelectSound.play()

	menu_center.hide()
	options_center.show()

	var master_bus: int = AudioServer.get_bus_index("Master")

	if AudioServer.is_bus_mute(master_bus):
		sound_button.text = "SOUND: OFF"
	else:
		sound_button.text = "SOUND: ON"

	sound_button.grab_focus()


func _on_back_button_pressed() -> void:
	$MenuSelectSound.play()

	options_center.hide()
	menu_center.show()

	options_button.grab_focus()


func _on_sound_button_pressed() -> void:
	var master_bus: int = AudioServer.get_bus_index("Master")
	var is_muted: bool = AudioServer.is_bus_mute(master_bus)

	AudioServer.set_bus_mute(master_bus, not is_muted)

	if is_muted:
		sound_button.text = "SOUND: ON"
	else:
		sound_button.text = "SOUND: OFF"
