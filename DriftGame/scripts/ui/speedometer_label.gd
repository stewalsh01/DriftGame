extends Label

@onready var car: CharacterBody3D = $"../../Car"


func _process(_delta: float) -> void:
	text = str(roundi(car.speed_kmh))
