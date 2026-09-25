extends Node

@export var spawn_center_node: Node2D
@export var spawnable_objects: Array[PackedScene] = []
@export var spawn_radius: float = 600.0
@export var active_radius: float = 1500.0

var active_radius_squared: float

var alive_counts: Dictionary = {}
var instances: Dictionary[PackedScene, Array]
var scene_caps: Dictionary = {}

var dead_enemies: int = 0

signal body_freed(global_position: Vector2)


func _ready() -> void:
	_build_scene_caps()
	_build_instances()
	active_radius_squared = active_radius * active_radius


func _build_instances():
	for scene in spawnable_objects:
		instances[scene] = []


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


func _process(_delta: float) -> void:
	var enemies_to_remove: Array[Array]
	for scene in instances:
		for entity in instances[scene]:
			if is_instance_valid(entity) and (entity is Node2D):
				if entity.global_position.distance_squared_to(spawn_center_node.global_position) > active_radius_squared:
					enemies_to_remove.append([scene, entity])

	for arr in enemies_to_remove:
		_count_entity_death(arr[0], arr[1], false)
		arr[1].queue_free()
				

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
		instance.look_at(spawn_center_node.global_position)
	
	if "resource" in instance:
		instance.resource.target = spawn_center_node
		instance.resource.died.connect(_count_entity_death.bind(random_scene, instance))

	var death_component: DeathComponent = ComponentUtility.get_component(instance, DeathComponent)
	death_component.body_freed.connect(func(position: Vector2): body_freed.emit(position))

	alive_counts[random_scene] = alive_counts.get(random_scene, 0) + 1
	instances[random_scene].append(instance)

	add_child(instance)

	return instance


func _count_entity_death(scene: PackedScene, instance: Node, player_killed: bool = true) -> void:
	if player_killed:
		dead_enemies += 1
	instances[scene].erase(instance)
	alive_counts[scene] = max(alive_counts.get(scene, 0) - 1, 0)
	


func spawn_up_to_capacity() -> void:
	var attempts: int = 0
	var max_attempts: int = spawnable_objects.size() * 10
	while attempts < max_attempts:
		var spawned := spawn_random_enemy()
		if spawned == null:
			break
		attempts += 1
