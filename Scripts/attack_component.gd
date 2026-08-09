extends Node
class_name AttackComponent

func attack(hurt_component: HurtComponent, dmg: float):
    hurt_component.take_damage(dmg)