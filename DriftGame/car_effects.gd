extends Node3D


# ================================================================
# REFERENCES
# ================================================================

@onready var rear_left: Marker3D = (
	$"../RearLeftTyre"
)

@onready var rear_right: Marker3D = (
	$"../RearRightTyre"
)

@export var skid_marks_path: NodePath

@onready var skid_marks: Node3D = get_node_or_null(
	skid_marks_path
) as Node3D


# ================================================================
# STATE
# ================================================================

var previous_left: Vector3
var previous_right: Vector3

var was_skidding: bool = false


# ================================================================
# READY
# ================================================================

func _ready() -> void:
	previous_left = rear_left.global_position
	previous_right = rear_right.global_position


# ================================================================
# UPDATE EFFECTS
# ================================================================

func update_effects(
	is_skidding: bool,
	skid_intensity: float
) -> void:
	var current_left: Vector3 = (
		rear_left.global_position
	)

	var current_right: Vector3 = (
		rear_right.global_position
	)

	if is_skidding and was_skidding:
		skid_marks.create_mark(
			previous_left,
			current_left,
			skid_intensity
		)

		skid_marks.create_mark(
			previous_right,
			current_right,
			skid_intensity
		)

	previous_left = current_left
	previous_right = current_right

	was_skidding = is_skidding
