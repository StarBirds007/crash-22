extends Node2D

@onready var enemy_spawner: Node = $EnemySpawner
@onready var power_up_spawner: Node = $PowerUpSpawner

@onready var plane: Node = $Plane
@onready var camera_2d: Camera2D = $Plane/Camera2D
@onready var enemy_spawn_timer: Timer
@onready var ocean_parallax: Parallax2D = $OceanParallax

@onready var health_bar: ProgressBar = %HealthBar
@onready var kill_count: Label = %KillCount

@export var max_zoom: float = 0.75
@export var min_zoom: float = 0.5
@export var offset_length: float = 10.0 # How far ahead of the plane the camera should look

@export var enemy_spawn_rate: float = 3.0 # sec

var player_health_component: HealthComponent


func _ready() -> void:
	ocean_parallax.z_index = RenderLayers.WATER

	player_health_component = ComponentUtility.get_component(plane, HealthComponent)
	health_bar.max_value = player_health_component.MAX_HEALTH

	enemy_spawner.body_freed.connect(func(pwup_pos: Vector2):
		power_up_spawner.spawn_random_pwup(pwup_pos))

	enemy_spawn_timer = Timer.new()
	enemy_spawn_timer.wait_time = enemy_spawn_rate
	enemy_spawn_timer.one_shot = false
	enemy_spawn_timer.timeout.connect(_spawn_enemies)
	add_child(enemy_spawn_timer)
	enemy_spawn_timer.start()


func _process(_delta: float) -> void:
	kill_count.text = "Kill Count: " + str(enemy_spawner.dead_enemies)
	health_bar.value = player_health_component.health

	queue_redraw()
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
	# print("Enemy Spawned: " + str(enemy_spawner.spawn_random_enemy()))
	enemy_spawner.spawn_random_enemy()

func get_enemies_in_radius() -> int:
	var count: int = 0
	for child in enemy_spawner.get_children():
		if "targeting_component" in child:
			if child.targeting_component.is_within_radius:
					count += 1
	return count


func _draw() -> void:
	return
	draw_circle(plane.global_position, enemy_spawner.spawn_radius, Color.RED, false, 2)
