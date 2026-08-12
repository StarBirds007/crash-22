extends Area2D
class_name HurtComponent

@export var visual_component: CanvasItem
@export var health_component: HealthComponent
@export var flash_color: Color = Color(1.0, 0.094, 0.106)
@export var flash_time: float = 0.1 # sec

var tween: Tween
var mat: ShaderMaterial

func _ready() -> void:
    if visual_component and visual_component.material != null:
        var temp_mat: ShaderMaterial = visual_component.material as ShaderMaterial
        if temp_mat.get_shader_parameter("overlay_color"):
            print("true")
            mat = temp_mat


func take_damage(dmg: float):
    if health_component:
        health_component.take_damage(dmg)
    
    if mat:
        _flash_effect()
        print("Flashing Red")


func _flash_effect():
    if tween and tween.is_valid():
        tween.kill()
    
    var target_color: Color = Color(flash_color.r, flash_color.g, flash_color.b, 0)

    mat.set_shader_parameter("overlay_color", flash_color)

    tween = create_tween()
    tween.tween_property(mat, "shader_parameter/overlay_color", target_color, flash_time)
    
