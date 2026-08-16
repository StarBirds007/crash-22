extends CharacterBody2D

@onready var health_component: HealthComponent = $HealthComponent
@onready var targeting_component: TargetingComponent = $TargetingComponent

@onready var gun_sprite: Sprite2D = $GunSprite
@onready var muzzle: Marker2D = $GunSprite/Muzzle
@onready var rate_of_fire_timer: Timer = $RateOfFire
@onready var reload_timer: Timer = $ReloadTimer
@onready var bullet_manager: MultiMeshInstance2D = $BulletManager

@export var resource: EntityResource

@export var speed: float = 100.0 # px/sec
@export var turn_rate: float = 2.0 # rad/sec

@export var bullets_before_reload: int = 10
@export var bullet_speed: float = 500.0
@export var reload_time: float = 3.0
@export var rate_of_fire: float = 0.1

@export var damage: float = 1

var can_shoot: bool = true
var is_reloading: bool = false
var bullets_shot: int = 0

func _ready() -> void:
	z_index = RenderLayers.BOATS

	rate_of_fire_timer.timeout.connect(_rate_of_fire_timeout)
	reload_timer.timeout.connect(_reload_timeout)
	rate_of_fire_timer.wait_time = rate_of_fire
	reload_timer.wait_time = reload_time

	health_component.dead.connect(_on_death)
	health_component.critical_health.connect(_on_critical_health)
	targeting_component.set_target(resource.target)

	bullet_manager.enemy_hit.connect(_on_enemy_hit)


func _physics_process(delta: float) -> void:
	var target_vector: Vector2 = targeting_component.get_target()
	var dist_vector = target_vector - global_position
	var desired_rotation = dist_vector.angle()

	var exact_target_vector: Vector2 = targeting_component.get_exact_target()
	dist_vector = exact_target_vector - gun_sprite.global_position
	var desired_gun_rotation = dist_vector.angle()

	rotation = rotate_toward(rotation, desired_rotation, delta)

	velocity = Vector2.from_angle(rotation) * speed

	move_and_slide()

	gun_sprite.global_rotation = rotate_toward(gun_sprite.global_rotation, desired_gun_rotation, delta * 1.5)
	# gun_sprite.look_at(targeting_component.get_exact_target())


func _process(_delta: float) -> void:
	if can_shoot and not is_reloading and targeting_component.is_within_radius:
		can_shoot = false
		rate_of_fire_timer.start()
		bullet_manager.spawn_bullet(muzzle.global_position, Vector2.RIGHT.rotated(gun_sprite.global_rotation), bullet_speed)
		bullets_shot += 1
		if bullets_shot > bullets_before_reload:
			bullets_shot = 0
			is_reloading = true
			reload_timer.start()


func _on_enemy_hit(object: Dictionary) -> void:
	if object.collider.has_method("take_damage"):
		object.collider.take_damage(damage)



func _reload_timeout() -> void:
	is_reloading = false

func _rate_of_fire_timeout() -> void:
	can_shoot = true


func _on_death() -> void:
	resource.died.emit()
	queue_free()


func _on_critical_health() -> void:
	pass
