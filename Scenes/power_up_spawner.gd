extends Node

@export var power_up: PackedScene
@export var effects: Array[PowerUpEffect]

# func _ready() -> void:
# 	if power_up.get_script() != PowerUp:
# 		push_error("The PowerUp scene: " + str(power_up) + "does not inherit from class PowerUp.")


func spawn_random_pwup(global_position: Vector2) -> void:
	var pwup: PowerUp = power_up.instantiate()
	pwup.effect = effects[(randi() % effects.size()) - 1]
	pwup.global_position = global_position
	add_child(pwup)
