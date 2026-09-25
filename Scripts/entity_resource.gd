extends Resource
class_name EntityResource

@export var no_of_instances: int
@export_range(0.0, 1.0, 0.05) var pwup_drop_chance: float
var target: Node2D



signal died(Node: Node)
