extends Line2D

@export var node_to_follow: Node2D

@export var target_length: float = 100.0
@export var offset: Vector2 = Vector2.ZERO

var shader: ShaderMaterial = material as ShaderMaterial
var boolean: bool = false

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(node_to_follow):
		return
	
	var target_position: Vector2 = node_to_follow.global_position + offset.rotated(node_to_follow.rotation)

	while (get_line_length() > target_length):
		remove_point(get_point_count() - 1)

	add_point(target_position, 0)


func set_shader_speed(node_speed: float) -> void:
	var line_length = get_line_length()
	var shader_speed = (node_speed * 5) / line_length * shader.get_shader_parameter("noise_scale").x
	shader.set_shader_parameter("flow_speed", shader_speed)


func get_line_length() -> float:
	var total_length: float = 0.0
	var point_count: int = get_point_count()

	for i in range(point_count - 1):
		var current_point = get_point_position(i)
		var next_point = get_point_position(i + 1)	

		total_length += next_point.distance_to(current_point)
	
	return total_length