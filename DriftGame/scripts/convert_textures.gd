@tool
extends EditorScript

func _run() -> void:
	var folder: String = "res://DriftGame/assets/terrain/textures/"

	var textures: Array[String] = [
		"brown_dirt_normal",
		"gravel_normal"
	]

	for texture_name in textures:
		var source_path: String = folder + texture_name + ".tres"
		var destination_path: String = folder + texture_name + ".res"

		var resource: Resource = load(source_path)

		if resource == null:
			push_error("Could not load: " + source_path)
			continue

		var result: Error = ResourceSaver.save(resource, destination_path)

		if result == OK:
			print("Converted: ", destination_path)
		else:
			push_error("Failed to convert: ", source_path)
