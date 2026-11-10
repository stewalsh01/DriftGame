
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


# NODE REFERENCES

@onready var track_name_label: Label = $TrackNavigation/TrackName
@onready var track_preview: TextureRect = $TrackPreview

@onready var previous_track_button: Button = $TrackNavigation/PreviousTrackButton
@onready var next_track_button: Button = $TrackNavigation/NextTrackButton

@onready var previous_time_button: Button = $TimeOfDaySelection/PreviousTimeButton
@onready var time_of_day_label: Label = $TimeOfDaySelection/TimeOfDayButton
@onready var next_time_button: Button = $TimeOfDaySelection/NextTimeButton

@onready var menu_select_sound: AudioStreamPlayer = $"../MenuSelectSound"
@onready var start_button: Button = $StartButton

var selected_track_index: int = 0


func _ready() -> void:
	_update_track_preview()
	_update_time_of_day_display()


# TRACK SELECTION

func _update_track_preview() -> void:
	var track = TRACKS[selected_track_index]

	track_name_label.text = track["name"]
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


# TIME OF DAY

func _update_time_of_day_display() -> void:
	time_of_day_label.text = "DAY" if LocationSelection.is_day else "NIGHT"


func _change_time_of_day() -> void:
	LocationSelection.is_day = not LocationSelection.is_day

	_update_time_of_day_display()


func _on_previous_time_button_pressed() -> void:
	_change_time_of_day()


func _on_next_time_button_pressed() -> void:
	_change_time_of_day()


# MOUSE HOVER

func _on_next_track_button_mouse_entered() -> void:
	next_track_button.grab_focus()


func _on_previous_track_button_mouse_entered() -> void:
	previous_track_button.grab_focus()


func _on_back_button_mouse_entered() -> void:
	$BackButton.grab_focus()


func _on_previous_time_button_mouse_entered() -> void:
	previous_time_button.grab_focus()


func _on_next_time_button_mouse_entered() -> void:
	next_time_button.grab_focus()


func _on_start_button_mouse_entered() -> void:
	start_button.grab_focus()


func _on_start_button_pressed() -> void:
	var track_scene: PackedScene = TRACKS[selected_track_index]["scene"]
	track_selected.emit(track_scene)
