extends CharacterBody2D

@onready var hurt_component: HurtComponent = $HurtComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var targeting_component: TargetingComponent = $TargetingComponent
@onready var death_component: DeathComponent = $DeathComponent

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var plane_path: Path2D = $PlanePath
@onready var plane_trail: Line2D = $PlaneTrail

@export var resource: EntityResource

@export var planes_distance: float = 30
@export var number_of_planes: int = 10
@export var speed: float = 200
@export var rotation_speed: float = 2 # rad/sec
@export var damage: float = 10

@onready var following_planes: Array[CharacterBody2D]

var is_leading_plane_dead: bool = false

func _ready() -> void:
	z_index = RenderLayers.BOATS
	plane_trail.set_shader_speed(speed)

	targeting_component.set_target(resource.target)
	health_component.dead.connect(_on_death.call_deferred)
	# death_component.override_velocity = speed
	
	animated_sprite_2d.frame_changed.connect(_on_frame_changed)

	plane_path.curve.clear_points()

	var target_length: float = planes_distance * (number_of_planes - 1)
	
	for i in range(target_length):
		var point_pos: Vector2 = Vector2(position.x - i, position.y)
		plane_path.curve.add_point(rotate_to_pivot(point_pos, position, rotation),
								   Vector2.ZERO, Vector2.ZERO, 0)

	_create_planes()


func _create_planes() -> void:
	for i in range(number_of_planes - 1):
		# This function creates new CharacterBody2D's meant to follow the original plane's path
		var new_plane := CharacterBody2D.new()

		# Adding new sprite
		var new_animated_sprite_2d := animated_sprite_2d.duplicate()
		var new_material := animated_sprite_2d.material.duplicate()
		new_animated_sprite_2d.material = new_material
		new_animated_sprite_2d.frame_changed.connect(func():
				var shader = new_animated_sprite_2d.material as ShaderMaterial
				shader.set_shader_parameter("frame", new_animated_sprite_2d.frame))
		new_plane.add_child(new_animated_sprite_2d)


		# Adding new waveline
		var new_plane_trail := plane_trail.duplicate()
		new_plane_trail.node_to_follow = new_plane
		new_plane.add_child(new_plane_trail)


		# Adding new HealthComponent, also handles death of the plane
		var new_health_component := health_component.duplicate()
		new_health_component.dead.connect(func():
			for child in new_plane.get_children():
				if child is DeathComponent:
					child.die()
					child.death_complete.connect(func():
						following_planes.remove_at(following_planes.find(new_plane))
						call_deferred("_on_following_plane_death")))
		new_plane.add_child(new_health_component)


		# Adding new HurtComponent
		var new_hurt_component := hurt_component.duplicate()
		new_hurt_component.visual_component = new_animated_sprite_2d
		new_hurt_component.health_component = new_health_component
		new_plane.add_child(new_hurt_component)


		# Adding new DeathComponent
		var new_death_component := death_component.duplicate()
		new_death_component.hurt_component = new_hurt_component
		new_death_component.visual_components.clear()
		new_death_component.visual_components.append(new_animated_sprite_2d)
		new_death_component.visual_components.append(new_plane_trail)
		new_death_component.body_freed.connect(func(pos:Vector2): death_component.body_freed.emit(pos))
		new_plane.add_child(new_death_component)


		# Adding a script to the following planes so they can have their own EntityResource
		new_plane.set_script(load("res://Scripts/following_planes.gd"))
		new_plane.resource = resource.duplicate()

		# Creating new PathFollow2D and adding the new plane as a child
		var path_follow: PathFollow2D = PathFollow2D.new()
		path_follow.add_child(new_plane)
		plane_path.add_child(path_follow)
		following_planes.append(new_plane)



func _physics_process(delta: float) -> void:
	_handle_leading_plane(delta)
	_create_path()
	_update_points()


func _handle_leading_plane(delta: float) -> void:
	var target_vector: Vector2 = targeting_component.get_target()

	var dist_vector: Vector2 = target_vector - position
	var desired_rotation = dist_vector.angle()

	if targeting_component.is_within_radius:
		rotation = rotate_toward(rotation, desired_rotation, - delta * rotation_speed)
	else:
		rotation = rotate_toward(rotation, desired_rotation, delta * rotation_speed)

	velocity = Vector2.from_angle(rotation) * speed

	move_and_slide()


func _create_path() -> void:
	var target_length: float = planes_distance * (number_of_planes - 1)
	var target_position: Vector2 = position
	while (plane_path.curve.get_baked_length() > target_length):
		plane_path.curve.remove_point(0)

	plane_path.curve.add_point(target_position)


func _update_points():
	if plane_path.curve.point_count > 1:
		var path_children := plane_path.get_children()
		for i in range(number_of_planes - 1):
			path_children[i].progress_ratio = float(i) / (number_of_planes - 1)


func _on_following_plane_death() -> void:
	if following_planes.is_empty() and is_leading_plane_dead:
		resource.died.emit()
		queue_free()


func _on_death() -> void:
	if following_planes.is_empty():
		resource.died.emit()
		death_component.die()
	else:
		death_component.die(true)
		is_leading_plane_dead = true


func _on_frame_changed() -> void:
	var shader = animated_sprite_2d.material as ShaderMaterial
	shader.set_shader_parameter("frame", animated_sprite_2d.frame)


func _on_hurt_component_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
	# health_component.take_damage(health_component.MAX_HEALTH)


func rotate_to_pivot(target: Vector2, pivot: Vector2, angle: float) -> Vector2:
	var offset = target - pivot
	var rotated_offset = offset.rotated(angle)
	return pivot + rotated_offset
