extends MultiMeshInstance2D

# Structure to hold each bullet's raw data
class Bullet:
	var position: Vector2
	var velocity: Vector2
	var prev_position: Vector2
	var starting_position: Vector2
	var rotation: float = 0.0

var active_bullets: Array[Bullet] = []

func _physics_process(delta: float) -> void:
	var space_state = get_world_2d().direct_space_state
	var i = active_bullets.size() - 1

	# Loop backwards so we can safely remove dead bullets
	while i >= 0:
		var bullet = active_bullets[i]

		# 1. Update positions
		bullet.prev_position = bullet.position
		bullet.position += bullet.velocity * delta

		# 2. Setup the Raycast query
		var query = PhysicsRayQueryParameters2D.create(bullet.prev_position, bullet.position)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.collision_mask = 2

		var result = space_state.intersect_ray(query)

		# 3. Check for hit
		if not result.is_empty():
			handle_bullet_hit(result, bullet)
			active_bullets.remove_at(i)
			i -= 1
			continue

		# 4. Optional: Remove bullets that flew too far away (e.g., beyond a certain distance from the origin)
		if bullet.position.distance_to(bullet.starting_position) > 1000:  # Example distance limit
			active_bullets.remove_at(i)

		i -= 1

	# 5. Update the GPU to draw all bullets at once
	update_multimesh()

# This function passes all bullet positions to the GPU in one single batch
func update_multimesh() -> void:
	multimesh.instance_count = active_bullets.size()
	for i in range(active_bullets.size()):
		var t = Transform2D(active_bullets[i].rotation, active_bullets[i].position)
		multimesh.set_instance_transform_2d(i, t)

# Function to spawn a bullet from your gun
func spawn_bullet(start_pos: Vector2, direction: Vector2, speed: float) -> void:
	var new_bullet = Bullet.new()
	new_bullet.starting_position = start_pos
	new_bullet.position = start_pos
	new_bullet.prev_position = start_pos
	new_bullet.velocity = direction.normalized() * speed
	new_bullet.rotation = direction.angle() - PI / 2  # Adjust rotation to match the direction
	active_bullets.append(new_bullet)

func handle_bullet_hit(result: Dictionary, _bullet: Bullet) -> void:
	var hit_object = result.collider
	# Add your damage logic here, for example:
	if hit_object.has_method("take_damage"):
		hit_object.take_damage(10)
	
	# Spawn a hit particle effect here if desired
