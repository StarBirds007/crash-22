extends PowerUpEffect
class_name HealthEffect

@export var heal_amount: float = 10


func apply(player: Node) -> void:
    var health_component: HealthComponent = ComponentUtility.get_component(player, HealthComponent)
    if health_component:
        health_component.heal(heal_amount)