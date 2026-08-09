extends Area2D
class_name HurtComponent

@export var health_component: HealthComponent

func take_damage(dmg: float):
    if health_component:
        health_component.take_damage(dmg)