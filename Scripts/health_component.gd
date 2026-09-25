extends Node
class_name HealthComponent

@export var MAX_HEALTH: float = 100
var health: float = 100
var critical_percentage: float = 0.25

var is_critical: bool = false
var is_dead: bool = false

signal dead
signal critical_health
signal normal_health

func _ready() -> void:
    health = MAX_HEALTH


func take_damage(dmg: float) -> void:
    health = max(health - dmg, 0)

    if health <= 0:
        if not is_dead:
            is_dead = true
            dead.emit()
        else:
            return
    
    if health <= MAX_HEALTH * critical_percentage and not is_critical:
        critical_health.emit()
        is_critical = true


func heal(heal_amount: float) -> void:
    if is_dead or health == 0:
        return

    health = min(health + heal_amount, MAX_HEALTH)

    if health > MAX_HEALTH * critical_percentage and is_critical:
        normal_health.emit()
        is_critical = false