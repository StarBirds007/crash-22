extends Node

@export var spawn_center_node: Node2D
@export var spawnable_objects: Array[PackedScene] = []
@export var spawn_radius: float = 600.0

var alive_counts: Dictionary = {} 
var scene_caps: Dictionary = {}

var dead_enemies: int = 0


func _ready() -> void:
	_build_scene_caps()


func _build_scene_caps() -> void:
	for scene in spawnable_objects:
		if not scene:
			continue

		var temp: Node = scene.instantiate()
		var cap: int = -1

		if "resource" in temp and temp.resource:
			cap = temp.resource.no_of_instances

		scene_caps[scene] = cap
		alive_counts[scene] = 0
		temp.free()


func _is_scene_available(scene: PackedScene) -> bool:
	var cap: int = scene_caps.get(scene, -1)
	if cap < 0:
		return true
	return alive_counts.get(scene, 0) < cap


func spawn_random_enemy() -> Node:
	if not spawn_center_node:
		push_warning("Spawner: No Spawn Center Node2D assigned!")
		return null
		
	if spawnable_objects.is_empty():
		push_warning("Spawner: Spawnable Objects array is empty!")
		return null

	var eligible_objects: Array[PackedScene] = spawnable_objects.filter(
		func(scene: PackedScene) -> bool:
			return scene != null and _is_scene_available(scene)
	)

	if eligible_objects.is_empty():
		return null

	var random_scene: PackedScene = eligible_objects[randi() % eligible_objects.size()]

	var angle: float = randf() * PI * 2
	var offset: Vector2 = Vector2.from_angle(angle).normalized() * spawn_radius
	
	var spawn_position: Vector2 = spawn_center_node.global_position + offset

	var instance = random_scene.instantiate()
	
	if instance is Node2D:
		instance.global_position = spawn_position
	
	if "resource" in instance:
		instance.resource.target = spawn_center_node
		instance.resource.died.connect(func():
			dead_enemies += 1
			alive_counts[random_scene] = max(alive_counts.get(random_scene, 0) - 1, 0))

	alive_counts[random_scene] = alive_counts.get(random_scene, 0) + 1

	add_child(instance)

	return instance


func spawn_up_to_capacity() -> void:
	var attempts: int = 0
	var max_attempts: int = spawnable_objects.size() * 10
	while attempts < max_attempts:
		var spawned := spawn_random_enemy()
		if spawned == null:
			break
		attempts += 1


# func has_resource_type(object: Object, resource_type: Script) -> bool:
# 	for property in object.get_property_list():
# 		var prop_name = property.name
# 		var prop_value = object.get(prop_name)
		
# 		# Check if the value is a Resource and matches the target type/script
# 		if prop_value is Resource and is_instance_of(prop_value, resource_type):
# 			return true
			
# 	return false


# func get_resource_name(object: Object, resource_type: Script) -> String:
# 	for property in object.get_property_list():
# 		var prop_name = property.name
# 		var prop_value = object.get(prop_name)
		
# 		# Check if the value is a Resource and matches the target type/script
# 		if prop_value is Resource and is_instance_of(prop_value, resource_type):
# 			return prop_name
			
# 	return ""f