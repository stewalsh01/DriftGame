extends Control


@onready var resume_button: Button = %ResumeButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()


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
