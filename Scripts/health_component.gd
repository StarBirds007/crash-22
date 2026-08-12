extends Node
class_name HealthComponent

@export var MAX_HEALTH: float = 100
var health: float = 100
var critical_percentage: float = 0.25

signal dead
signal critical_health

func _ready() -> void:
    health = MAX_HEALTH


func take_damage(dmg: float):
    health -= dmg
    # print("took damage", dmg)
    if health <= 0:
        # print("DED")
        dead.emit()
    
    if health <= MAX_HEALTH * critical_percentage:
        critical_health.emit()