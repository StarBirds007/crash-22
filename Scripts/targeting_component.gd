extends Node2D
class_name TargetingComponent

var target: Node2D

@export var circle_radius: float = 100
@export var attack_radius: float = 225

var is_on_target: bool = false
var is_within_radius: bool = false

func get_target() -> Vector2:
	var circle_center = target.global_position
	var line_dir = Vector2.RIGHT.rotated(rotation)
	var line_point = global_position

	if line_point.distance_to(circle_center) >= attack_radius:
		is_within_radius = false
	else: 
		is_within_radius = true

	if line_point.distance_to(circle_center) > circle_radius:
		# 1. Find the closest point on the line to the circle
		var to_circle = circle_center - line_point
		var projection = to_circle.dot(line_dir) # line_dir must be normalized
		var closest_point_on_line = line_point + line_dir * projection
		
		# 2. Return the closest point as target if we are looking directly at the circle
		if circle_center.distance_to(closest_point_on_line) <= circle_radius:
			return closest_point_on_line
		# 3. Else return the closest point of the circle to the line
		else:
			# Get the direction vector from the circle center to that line point
			var dir_to_line = circle_center.direction_to(closest_point_on_line)
			# Push outwards from the center along that direction by the radius
			return circle_center + dir_to_line * circle_radius
	else:
		return circle_center


func get_exact_target() -> Vector2:
	return target.global_position


func set_target(input_target: Node2D) -> void:
	target = input_target
