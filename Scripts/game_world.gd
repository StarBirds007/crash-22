extends Node2D

@onready var enemy_spawner: Node = $EnemySpawner

@onready var plane: Node = $Plane
@onready var camera_2d: Camera2D = $Plane/Camera2D
@onready var enemy_spawn_timer: Timer

@onready var speed: Label = %Speed
@onready var radius: Label = %Radius
@onready var kill_count: Label = %KillCount

@export var max_zoom: float = 1.0
@export var min_zoom: float = 0.75
@export var offset_length: float = 10.0 # How far ahead of the plane the camera should look

@export var enemy_spawn_rate: float = 5.0 # sec


func _ready() -> void:
	enemy_spawn_timer = Timer.new()
	enemy_spawn_timer.wait_time = enemy_spawn_rate
	enemy_spawn_timer.one_shot = false
	enemy_spawn_timer.timeout.connect(_spawn_enemies)
	add_child(enemy_spawn_timer)
	enemy_spawn_timer.start()



func _process(_delta: float) -> void:
	speed.text = "Speed: " + str(round(plane.current_speed)) + " px/sec"
	radius.text = "Enemies in Radius: " + str(get_enemies_in_radius())
	kill_count.text = "Kill Count: " + str(enemy_spawner.dead_enemies)

	_handle_camera()


func _handle_camera() -> void:
	var max_speed = plane.max_speed
	var min_speed = plane.min_speed
	var current_speed = plane.current_speed

	var speed_ratio = inverse_lerp(min_speed, max_speed, current_speed)
	var zoom_level = clamp(speed_ratio, 0.0, 1.0)
	zoom_level = lerp(max_zoom, min_zoom, zoom_level)

	camera_2d.zoom = Vector2(zoom_level, zoom_level)

	camera_2d.offset = Vector2(cos(plane.rotation), sin(plane.rotation)) * offset_length * speed_ratio


func _spawn_enemies() -> void:
	print("HEHEHEHE")
	print("Enemy Spawned: " + str(enemy_spawner.spawn_random_enemy()))


func get_enemies_in_radius() -> int:
	var count: int = 0
	for child in enemy_spawner.get_children():
		if "targeting_component" in child:
			if child.targeting_component.is_within_radius:
					count += 1
	return count