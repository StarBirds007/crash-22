extends Area2D
class_name PowerUp

@onready var shader: ShaderMaterial = $Sprite2D.material as ShaderMaterial

@export var max_rotation_speed: float = 2.0
@export var min_rotation_speed: float = 1

@export var max_speed: float = 50.0
@export var min_speed: float = 10

@export var rotation_decel: float = 0.5
@export var speed_decel: float = 3.0

var rotation_speed: float
var speed: float
var rand_direction: float

var rand_distort_direction: Vector2
@export var max_distort_strength: float = 20.0
@export var min_distort_strength: float = 10.0
@export var distort_speed: float = 50

var distort_strength: float
var current_distort: Vector2

@export var effect: PowerUpEffect


func _ready() -> void:
    rotation_speed = randf_range(min_rotation_speed, max_rotation_speed)
    speed = randf_range(min_speed, max_speed)
    rand_direction = randf_range(0, PI * 2)
    rotation = randf_range(0, PI * 2)

    distort_strength = randf_range(min_distort_strength, max_distort_strength)
    rand_distort_direction = Vector2.from_angle(randf_range(0, PI*2)).normalized()
    var distortion_vector: Vector2 = rand_distort_direction * distort_strength

    current_distort = distortion_vector
    shader.set_shader_parameter("y_rot", distortion_vector.y)
    shader.set_shader_parameter("x_rot", distortion_vector.x)

func _physics_process(delta: float) -> void:
    rotation += rotation_speed * delta
    position += Vector2.from_angle(rand_direction).normalized() * speed * delta
    
    rotation_speed = max(0, rotation_speed - (rotation_decel * delta))
    speed = max(0, speed - (speed_decel * delta))

    var target_distort: Vector2 = rand_distort_direction * distort_strength

    current_distort = current_distort.move_toward(target_distort, delta * distort_speed)

    if current_distort == target_distort:
        rand_distort_direction = Vector2.from_angle(randf_range(0, PI*2)).normalized()
        distort_strength /= 1.25
        distort_speed /= 1.25

    shader.set_shader_parameter("y_rot", current_distort.y)
    shader.set_shader_parameter("x_rot", current_distort.x)