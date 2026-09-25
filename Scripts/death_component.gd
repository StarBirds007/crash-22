extends Node
class_name DeathComponent

@export var death_modulate: Color = Color(0.0, 0.0, 0.0, 0.400)

@export var bullet_manager: BulletManager
@export var hurt_component: HurtComponent
@export var visual_components: Array[Node2D]

@export var effect: PackedScene
@export var effect_scale_override: float = 1

@export_enum("Moving Forward", "Altitude Loss", "Random") var movement_mode: String = "Moving Forward"

@export var override_velocity: float

var entity_resource: EntityResource
var pwup_spawn_position: Vector2
var dead_character: CharacterBody2D
var target_velocity: Vector2

var movement_enabled: bool = false
var is_movement_set: bool = false
var random_rotation_direction: int = 1
var random_rotation_velocity: float

var is_dying: bool = false

signal death_complete
signal body_freed(global_position: Vector2)


func _ready() -> void:
	print(ComponentUtility.get_property(get_parent(), "EntityResource"))
	entity_resource = ComponentUtility.get_property(get_parent(), "EntityResource")



func die(disable_only: bool = false) -> void:
	if is_dying:
		return
	else:
		is_dying = true

	if bullet_manager:
		bullet_manager.disabled = true

	if hurt_component:
		hurt_component.set_deferred("monitorable", false)
		hurt_component.set_deferred("collision_layer", 0)
		hurt_component.default_color = death_modulate


	if not disable_only:
		get_parent().set_process(false)
		get_parent().set_physics_process(false)

	dead_character = CharacterBody2D.new()
	dead_character.global_transform = get_parent().global_transform

	for child in get_parent().get_children():
		if child is CollisionShape2D:
			child.reparent(dead_character)

	for component in visual_components:
		var mat = component.material as ShaderMaterial
		if mat.get_shader_parameter("overlay_color") != null:
			mat.set_shader_parameter("overlay_color", death_modulate)

		if component is WaveLine:
			component.node_to_follow = dead_character

		component.reparent(dead_character)

	var death_effect = effect.instantiate()
	get_tree().create_timer(death_effect.failsafe_timer).timeout.connect(dead_character.queue_free.call_deferred)

	for p in death_effect.get_children():
		var mat = p.process_material.duplicate() as ParticleProcessMaterial
		p.process_material = mat
		if mat:
			mat.scale_min *= effect_scale_override
			mat.scale_max *= effect_scale_override

	dead_character.add_child(death_effect)

	if "trigger" in death_effect:
		death_effect.trigger.connect(func():
			pwup_spawn_position = dead_character.global_position
			# _spawn_pwup()
			for component in visual_components:
				component.visible = false)

	if "done" in death_effect:
		death_effect.done.connect(func():
			_kill_dead_character()
			death_complete.emit()

			set_physics_process(false)
			set_process(false)

			if not disable_only:
				get_parent().call_deferred("queue_free")
			)
	else:
		push_error("\"done\" signal not found in death effect!")

	var container: Node = get_tree().current_scene.find_child("DeadBodiesContainer", false, false)

	if container == null:
		var dead_bodies_container: Node = Node.new()
		dead_bodies_container.name = "DeadBodiesContainer"
		get_tree().current_scene.add_child(dead_bodies_container)
		dead_bodies_container.add_child(dead_character)
	else:
		container.add_child(dead_character)

	movement_enabled = true


func _kill_dead_character():
	_spawn_pwup()
	dead_character.call_deferred("queue_free")


func _spawn_pwup() -> void:
	var pwup_drop_chance: float = entity_resource.pwup_drop_chance
	if randf_range(0.0, 1.0) <= pwup_drop_chance:
		if pwup_spawn_position:
			body_freed.emit(pwup_spawn_position)
		else:
			body_freed.emit(dead_character.global_position)


func _physics_process(delta: float) -> void:
	if not movement_enabled:
		return

	if override_velocity > 0.0:
		target_velocity = Vector2.from_angle(dead_character.global_rotation) * override_velocity
	elif override_velocity <= 0.0:
		target_velocity = get_parent().velocity

	if movement_mode == "Moving Forward":
		if not is_movement_set:
			dead_character.velocity = target_velocity
			is_movement_set = true
		dead_character.move_and_slide()
	
	if movement_mode == "Altitude Loss":
		if not is_movement_set:
			is_movement_set = true
			random_rotation_direction = 1 if randi_range(0, 1) else -1
			dead_character.rotation += randf_range(0 , PI / 4) * random_rotation_direction
		dead_character.global_rotation += 1 * delta * random_rotation_direction
		dead_character.velocity = target_velocity
		dead_character.move_and_slide()
