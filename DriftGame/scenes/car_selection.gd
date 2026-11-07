
extends Control

var selected_car_index: int = 0

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



func _ready() -> void:
	_update_car_preview()


func _on_next_car_button_pressed() -> void:
	selected_car_index = (selected_car_index + 1) % CARS.size()
	_update_car_preview()


func _on_previous_car_button_pressed() -> void:
	selected_car_index = (selected_car_index - 1 + CARS.size()) % CARS.size()
	_update_car_preview()


func _update_car_preview() -> void:
	var car = CARS[selected_car_index]

	$CarPreview.texture = car["texture"]
	$CarNavigation/CarName.text = car["name"]
