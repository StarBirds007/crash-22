extends CharacterBody2D

@onready var hurt_component: Area2D = $HurtComponent
@onready var health_component: Node = $HealthComponent
@onready var targeting_component: Node2D = $TargetingComponent

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

func _ready() -> void:
	z_index = RenderLayers.BOATS

	targeting_component.set_target(resource.target)
	health_component.dead.connect(_on_death)
	
	animated_sprite_2d.frame_changed.connect(_on_frame_changed)

	plane_path.curve.clear_points()
	_create_planes()


func _create_planes() -> void:
	for i in range(number_of_planes - 1):
		var new_plane := CharacterBody2D.new()

		var new_animated_sprite_2d := animated_sprite_2d.duplicate()
		var new_material := animated_sprite_2d.material.duplicate()
		new_animated_sprite_2d.material = new_material
		new_animated_sprite_2d.frame_changed.connect(func():
				var shader = new_animated_sprite_2d.material as ShaderMaterial
				shader.set_shader_parameter("frame", new_animated_sprite_2d.frame))
		new_plane.add_child(new_animated_sprite_2d)

		var new_plane_trail := plane_trail.duplicate()
		new_plane_trail.node_to_follow = new_plane
		new_plane.add_child(new_plane_trail)

		var new_health_component := health_component.duplicate()
		new_health_component.dead.connect(func():
			new_plane.queue_free())
		new_plane.add_child(new_health_component)

		var new_hurt_component := hurt_component.duplicate()
		new_hurt_component.visual_component = new_animated_sprite_2d
		new_hurt_component.health_component = new_health_component
		new_plane.add_child(new_hurt_component)

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


func _on_death() -> void:
	resource.died.emit()
	queue_free()


func _on_frame_changed() -> void:
	var shader = animated_sprite_2d.material as ShaderMaterial
	shader.set_shader_parameter("frame", animated_sprite_2d.frame)


func _on_hurt_component_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
	# health_component.take_damage(health_component.MAX_HEALTH)
