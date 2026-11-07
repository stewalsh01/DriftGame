
extends Control


const CARS = [
	{
		"name": "MAZDA RX-7",
		"texture": preload("res://DriftGame/assets/menu/cars/car_mazda_rx7.png")
	},
	{
		"name": "SUBARU BRZ",
		"texture": preload("res://DriftGame/assets/menu/cars/car_subaru_brz.png")
	}
]


@onready var car_preview: TextureRect = $CarPreview
@onready var car_name_button: Button = $CarNavigation/CarName

@onready var previous_car_button: Button = $CarNavigation/PreviousCarButton
@onready var next_car_button: Button = $CarNavigation/NextCarButton
@onready var back_button: Button = $BackButton


var selected_car_index: int = 0


func _ready() -> void:
	_update_car_preview()


# CAR NAVIGATION

func _on_next_car_button_pressed() -> void:
	_change_car(1)


func _on_previous_car_button_pressed() -> void:
	_change_car(-1)


func _change_car(direction: int) -> void:
	selected_car_index = (
		selected_car_index + direction + CARS.size()
	) % CARS.size()

	_update_car_preview()


# CAR PREVIEW

func _update_car_preview() -> void:
	var car = CARS[selected_car_index]

	car_preview.texture = car["texture"]
	car_name_button.text = car["name"]


# MOUSE HOVER

func _on_previous_car_button_mouse_entered() -> void:
	previous_car_button.grab_focus()


func _on_car_name_mouse_entered() -> void:
	car_name_button.grab_focus()


func _on_next_car_button_mouse_entered() -> void:
	next_car_button.grab_focus()


func _on_back_button_mouse_entered() -> void:
	back_button.grab_focus()
