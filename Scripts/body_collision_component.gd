extends Area2D
class_name BodyCollisionComponent

@export var damage: float = 100.0
@export var full_damage: bool = true

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if full_damage:
		if "health_component" in area:
			area.take_damage(area.health_component.MAX_HEALTH)
	else:
		if area.has_method("take_damage"):
			area.take_damage(damage)