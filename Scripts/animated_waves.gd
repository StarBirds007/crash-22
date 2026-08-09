extends AnimatedSprite2D


var chance_to_spawn_wave: float = 0.99 # 1% chance to spawn a wave each frame


func _process(delta: float) -> void:
    # Start the animation
    await get_tree().create_timer(5).timeout
    if not is_playing():
        if randi() % 100 < chance_to_spawn_wave * 100:
            play("default")