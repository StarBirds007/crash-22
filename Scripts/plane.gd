extends CharacterBody2D

@onready var shader: ShaderMaterial = $AnimatedSprite2D.material as ShaderMaterial
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var muzzle_2: Marker2D = $Muzzle2
@onready var rate_of_fire_timer: Timer = $RateOfFire

@export var cruise_speed: float = 200.0 # px/sec
@export var min_speed: float = 40.0 # px/sec
@export var max_speed: float = 400.0 # px/sec
@export var acceleration: float = 240.0 # px/sec^2
@export var brake_deceleration: float = 250.0 # px/sec^2
@export var deceleration_turn_multiplier: float = 0.5

@export var boost_speed: float = 400.0 # px/sec
@export var boost_turn_multiplier: float = 1 # Mutiplier for turn rate while boosting (0.0 = no turning, 1.0 = normal turning)

@export var turn_rate_at_min_speed: float = 3.0 # radians/sec
@export var turn_rate_at_max_speed: float = 1.0 # radians/sec

@export var max_x_rot: int = 45 # degrees
@export var max_y_rot: int = 45
@export var x_rotation_speed: float = 45 # degrees/sec
@export var y_rotation_speed: float = 45 # degrees/sec

@export var min_propeller_speed: int = 30 # frames/sec
@export var max_propeller_speed: int = 60 # frames/sec

@export var bullet_speed: float = 400 # px/sec
@export var rate_of_fire: float = 0.1 # sec
var can_shoot: bool = true


var current_speed: float = 0.0
var turn_input: float = 0.0
var turn_rate: float = 0.0
enum MovementState { CRUISE, BOOST, BRAKE }
var movement_state: MovementState = MovementState.CRUISE
var is_decelerating: bool = false

signal shoot_bullet


func _ready() -> void:
	current_speed = min_speed

	rate_of_fire_timer.wait_time = rate_of_fire
	rate_of_fire_timer.one_shot = true
	rate_of_fire_timer.timeout.connect(func function():
		print("Rate of fire timer finished, can shoot again.")
		can_shoot = true)

	animated_sprite_2d.frame_changed.connect(_on_frame_changed)


func _shoot_bullet(from_muzzle: Marker2D):
	can_shoot = false
	rate_of_fire_timer.start()
	shoot_bullet.emit(from_muzzle.global_position, Vector2.from_angle(rotation), bullet_speed + current_speed)


func _on_frame_changed() -> void:
	shader.set_shader_parameter("frame", animated_sprite_2d.frame)


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("shoot") and can_shoot:
		_shoot_bullet(muzzle)
		_shoot_bullet(muzzle_2)

	boost(Input.is_action_pressed("boost"))
	air_brake(Input.is_action_pressed("brake"))
	_handle_speed(delta)
	_handle_turning(delta)
	_handle_movement()
	_handle_shader(delta)


func _handle_speed(delta: float) -> void:
	# Determine which target speed and accel/decel rate applies this frame.
	var target_speed: float
	var rate: float

	if movement_state == MovementState.BRAKE:
		target_speed = min_speed
		rate = brake_deceleration
	elif movement_state == MovementState.BOOST:
		target_speed = boost_speed
		rate = acceleration
	else:
		target_speed = cruise_speed
		rate = acceleration

	# Using a temporary variable to check if speed has decreased from before.
	var temp_speed = move_toward(current_speed, target_speed, rate * delta)
	if temp_speed < current_speed:
		is_decelerating = true
	else:
		is_decelerating = false

	# Move current_speed toward target_speed at the given rate, without overshooting.
	current_speed = temp_speed

	# Safety clamp so bad exported values can't break things.
	current_speed = clamp(current_speed, min_speed, max_speed)


func _handle_turning(delta: float) -> void:
	turn_input = Input.get_axis("turn_left", "turn_right")
	if turn_input == 0.0:
		return

	# Interpolate turn rate based on current speed: slower = more maneuverable.
	var speed_t: float = inverse_lerp(min_speed, max_speed, current_speed)
	speed_t = clamp(speed_t, 0.0, 1.0)
	turn_rate = lerp(turn_rate_at_min_speed, turn_rate_at_max_speed, speed_t)

	# Boosting further restricts maneuverability on top of the speed penalty.
	if movement_state == MovementState.BOOST:
		turn_rate *= boost_turn_multiplier
	# if is_decelerating and movement_state == MovementState.BRAKE:
	# 	turn_rate *= deceleration_turn_multiplier

	rotation += turn_input * turn_rate * delta


func _handle_movement() -> void:
	# The plane sprite faces up (-Y) at rotation 0, so use Vector2.UP as the
	# base direction instead of the default rightward-facing convention.
	# var forward: Vector2 = Vector2.UP.rotated(rotation)
	velocity = Vector2.from_angle(rotation) * current_speed
	move_and_slide()


func _handle_shader(delta: float) -> void:
	var x_rot: float = shader.get_shader_parameter("x_rot")
	var y_rot: float = shader.get_shader_parameter("y_rot")


	if movement_state == MovementState.BRAKE and is_decelerating:
		x_rot = x_rot - x_rotation_speed * delta
	else:
		x_rot = x_rot + x_rotation_speed * 2 * delta
	
	x_rot = clampf(x_rot, -max_x_rot, 0)
	shader.set_shader_parameter("x_rot", x_rot)

	if turn_input > 0:
		if y_rot < 0:
			y_rot = y_rot + y_rotation_speed * turn_rate * delta * 2
		else:
			y_rot = y_rot + y_rotation_speed * turn_rate * delta
	elif turn_input < 0:
		if y_rot > 0:
			y_rot = y_rot - y_rotation_speed * turn_rate * delta * 2
		else:
			y_rot = y_rot - y_rotation_speed * turn_rate * delta
	else:
		y_rot = move_toward(y_rot, 0, y_rotation_speed * turn_rate * delta)

	y_rot = clampf(y_rot, -max_y_rot, max_y_rot)
	shader.set_shader_parameter("y_rot", y_rot)

	var prop_speed: int = int(lerp(min_propeller_speed, max_propeller_speed, inverse_lerp(min_speed, max_speed, current_speed)))
	animated_sprite_2d.sprite_frames.set_animation_speed("default", prop_speed)

func boost(active: bool) -> void:
	if active:
		movement_state = MovementState.BOOST
	else:
		if movement_state == MovementState.BOOST:
			movement_state = MovementState.CRUISE

func air_brake(active: bool) -> void:
	if active:
		movement_state = MovementState.BRAKE
	else:
		if movement_state == MovementState.BRAKE:
			movement_state = MovementState.CRUISE