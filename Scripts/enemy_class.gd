extends Node

var health: float = 100
var damage: float = 1


signal dead


func take_damage(dmg: float):
    health -= dmg
    if health <= 0:
        dead.emit(self)


func deal_damage(body: CharacterBody2D):
    if body.has_method("take_damage"):
        body.take_damage(damage)