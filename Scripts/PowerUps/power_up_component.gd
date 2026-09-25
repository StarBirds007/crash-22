extends Area2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var pickup_radius: float = 10.0
@export var target_node: Node

func _ready() -> void:
	collision_shape_2d.shape.radius = pickup_radius

func _on_area_entered(area: Area2D) -> void:
	if area is PowerUp:
		area.effect.apply(target_node)
	area.queue_free()
