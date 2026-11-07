
extends Control

signal track_selected(track_scene: PackedScene)


const TRACKS = [
	{
		"name": "DEMO TRACK",
		"scene": preload("res://DriftGame/scenes/location_demo_track.tscn"),
		"texture": preload("res://DriftGame/assets/menu/tracks/demo_track.png")
	},
	{
		"name": "OVAL TRACK",
		"scene": preload("res://DriftGame/scenes/location_oval_track.tscn"),
		"texture": preload("res://DriftGame/assets/menu/tracks/oval_track.png")
	},
	{
		"name": "DRIFT YARD",
		"scene": preload("res://DriftGame/scenes/location_drift_yard.tscn"),
		"texture": preload("res://DriftGame/assets/menu/tracks/drift_yard.png")
	}
]


@onready var track_name_button: Button = $TrackNavigation/TrackName
@onready var track_preview: TextureRect = $TrackPreview


var selected_track_index: int = 0

func _ready() -> void:
	_update_track_preview()

func _update_track_preview() -> void:
	var track = TRACKS[selected_track_index]
	track_name_button.text = track["name"]
	track_preview.texture = track["texture"]

func _on_next_track_button_pressed() -> void:
	_change_track(1)

func _on_previous_track_button_pressed() -> void:
	_change_track(-1)

func _change_track(direction: int) -> void:
	selected_track_index = (
		selected_track_index + direction + TRACKS.size()
	) % TRACKS.size()

	_update_track_preview()

func _on_track_name_pressed() -> void:
	var track_scene: PackedScene = TRACKS[selected_track_index]["scene"]
	track_selected.emit(track_scene)


func _on_next_track_button_mouse_entered() -> void:
	$TrackNavigation/NextTrackButton.grab_focus()


func _on_previous_track_button_mouse_entered() -> void:
	$TrackNavigation/PreviousTrackButton.grab_focus()


func _on_track_name_mouse_entered() -> void:
	$TrackNavigation/TrackName.grab_focus()


func _on_back_button_mouse_entered() -> void:
	$BackButton.grab_focus()
