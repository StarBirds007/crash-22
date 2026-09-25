extends Node2D

@onready var amber_particle: GPUParticles2D = $AmberParticle
@onready var explosion_particle: GPUParticles2D = $ExplosionParticle
@onready var fire_particle: GPUParticles2D = $FireParticle
@onready var smoke_particle: GPUParticles2D = $SmokeParticle
@onready var mini_splash_particle: GPUParticles2D = $MiniSplashParticle

@export var exit_fire_time: float = 2
@export var exit_smoke_time: float = 2

var failsafe_timer: float = 10.0

signal trigger
signal done

func _ready() -> void:
	for particle in get_children():
		if particle == mini_splash_particle:
			particle.z_index = RenderLayers.WATER
		else:
			particle.z_index = RenderLayers.BOATS

	amber_particle.emitting = true
	explosion_particle.emitting = true
	fire_particle.emitting = true
	smoke_particle.emitting = true
	await get_tree().create_timer(exit_fire_time).timeout
	fire_particle.emitting = false
	await get_tree().create_timer(exit_smoke_time).timeout
	smoke_particle.emitting = false
	mini_splash_particle.emitting = true
	trigger.emit()
	await get_tree().create_timer(smoke_particle.lifetime).timeout
	done.emit()