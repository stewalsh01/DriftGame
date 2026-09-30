extends Control


func _ready() -> void:
	$MenuCenter/MenuBox/Track1Button.grab_focus()


func _on_track_1_button_pressed() -> void:
	get_tree().change_scene_to_file(
        "res://DriftGame/scenes/car_3d.tscn"
	)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
