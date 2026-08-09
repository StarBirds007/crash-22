extends Node

@export var spawn_center_node: Node2D
@export var spawnable_objects: Array[PackedScene] = []
@export var spawn_radius: float = 400.0

var dead_enemies: int = 0

func spawn_random_enemy() -> Node:
	# Validation checks to ensure proper setup in the editor
	if not spawn_center_node:
		push_warning("Spawner: No Spawn Center Node2D assigned!")
		return null
		
	if spawnable_objects.is_empty():
		push_warning("Spawner: Spawnable Objects array is empty!")
		return null

	# 1. Pick a random object from the exported array
	var random_scene: PackedScene = spawnable_objects[randi() % spawnable_objects.size()]
	if not random_scene:
		return null

	# 2. Calculate a random position inside/on the imaginary circle
	# Using polar coordinates for a uniform distribution within a circle
	var angle: float = randf() * PI * 2
	var distance: float = sqrt(randf()) * spawn_radius
	var offset: Vector2 = Vector2(cos(angle), sin(angle)) * distance
	
	var spawn_position: Vector2 = spawn_center_node.global_position + offset

	# 3. Instantiate and add the object to the scene tree
	var instance = random_scene.instantiate()
	
	# If the spawned object is a Node2D, set its global position
	if instance is Node2D:
		instance.global_position = spawn_position
	
	if "target" in instance:
		instance.target = spawn_center_node
	
	if instance.has_signal("died"):
		instance.died.connect(func():
			dead_enemies += 1)

	# Add the instance to the current scene (adjust path if you want them parented elsewhere)
	add_child(instance)

	return instance