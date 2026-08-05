extends Node2D

@onready var bullet_manager: MultiMeshInstance2D = $BulletManager
@onready var plane: CharacterBody2D = $Plane

var fire_rate_timer: Timer
var fire_rate: float = 0.2 # Example fire rate (seconds)

@onready var speed: Label = %Speed
@onready var input_axis: Label = %InputAxis
@onready var turn_rate: Label = %TurnRate
@onready var rotation_label: Label = %Rotation

func _ready() -> void:
	plane.shoot_bullet.connect(_on_shoot_bullet)
	fire_rate_timer = Timer.new()
	fire_rate_timer.wait_time = fire_rate
	fire_rate_timer.one_shot = true
	add_child(fire_rate_timer)


func _on_shoot_bullet(start_pos: Vector2, direction: Vector2, bullet_speed: float) -> void:
	bullet_manager.spawn_bullet(start_pos, direction, bullet_speed)
	print("Bullet spawned at ", start_pos, " with direction ", direction, " and speed ", bullet_speed)


func _process(_delta: float) -> void:
	speed.text = "Speed: " + str(round(plane.current_speed)) + " px/sec"
	input_axis.text = "Input Axis: " + str(plane.turn_input)
	turn_rate.text = "Turn Rate: " + str(round(plane.turn_rate))
	rotation_label.text = "Rotation: " + str(round(rad_to_deg(plane.rotation))) + "°"
