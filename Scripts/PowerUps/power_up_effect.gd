extends Resource
class_name PowerUpEffect

var display_name: String = ""
var duration: float = 0.0

func apply(player: Node) -> void:
    push_warning("apply() not defined in PowerUp: " + display_name)


func remove() -> void:
    pass