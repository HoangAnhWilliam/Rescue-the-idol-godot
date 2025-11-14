extends Weapon
class_name FrostBow

## Frost Bow - RARE Rarity
## Long-range piercing projectile with slow effect
## Arrow pierces up to 3 enemies and slows them

var projectile_speed: float = 400.0
var piercing_count: int = 3
var slow_duration: float = 2.0
var slow_amount: float = 0.3  # 30% slow

func _ready():
	# Set weapon properties
	weapon_id = "frost_bow"
	weapon_name = "Frost Bow"
	rarity = 2  # RARE

	damage = 18.0
	attack_speed = 0.9
	range = 450.0  # Very long
	is_projectile = true

	super._ready()

	print("🏹 Frost Bow equipped - Piercing ice arrows!")

func attack(target_position: Vector2):
	# Find closest enemy
	var target = find_closest_enemy()

	if not target:
		return

	# Spawn ice arrow
	spawn_ice_arrow(target.global_position)

	# Reset cooldown
	attack_cooldown = 1.0 / attack_speed

func spawn_ice_arrow(target_position: Vector2):
	# Create arrow node
	var arrow = Area2D.new()
	arrow.name = "FrostArrow"

	# Visual: Ice blue rectangle
	var sprite = ColorRect.new()
	sprite.size = Vector2(20, 4)
	sprite.position = -sprite.size / 2
	sprite.color = Color(0.4, 0.8, 1.0)  # Ice blue
	arrow.add_child(sprite)

	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 4)
	collision.shape = shape
	arrow.add_child(collision)

	# Calculate direction
	var direction = (target_position - global_position).normalized()
	arrow.rotation = direction.angle()

	# Set metadata
	arrow.set_meta("direction", direction)
	arrow.set_meta("speed", projectile_speed)
	arrow.set_meta("damage", damage)
	arrow.set_meta("lifetime", 5.0)
	arrow.set_meta("piercing_left", piercing_count)
	arrow.set_meta("hit_enemies", [])
	arrow.set_meta("slow_duration", slow_duration)
	arrow.set_meta("slow_amount", slow_amount)

	# Set position
	arrow.global_position = global_position

	# Add to scene
	get_tree().root.add_child(arrow)

	# Connect collision
	arrow.body_entered.connect(_on_arrow_hit.bind(arrow))

	# Add movement script
	arrow.set_script(load("res://scripts/frost_arrow_mover.gd"))

	print("🏹 Frost arrow fired! Piercing: ", piercing_count)

func _on_arrow_hit(body: Node, arrow: Area2D):
	if not body.is_in_group("enemies"):
		return

	# Check if already hit this enemy
	var hit_list = arrow.get_meta("hit_enemies", [])
	if body in hit_list:
		return

	# Deal damage
	var dmg = arrow.get_meta("damage", damage)
	if body.has_method("take_damage"):
		body.take_damage(dmg, arrow.global_position)

	# Apply slow effect
	apply_slow_to_enemy(body, arrow.get_meta("slow_amount", 0.3), arrow.get_meta("slow_duration", 2.0))

	# Visual feedback
	ParticleManager.create_hit_effect(body.global_position, Color(0.4, 0.8, 1.0))

	# Add to hit list
	hit_list.append(body)
	arrow.set_meta("hit_enemies", hit_list)

	# Check piercing
	var piercing = arrow.get_meta("piercing_left", 0)
	piercing -= 1
	arrow.set_meta("piercing_left", piercing)

	print("❄️ Frost arrow hit! Piercing left: ", piercing)

	if piercing <= 0:
		# Destroy arrow
		arrow.queue_free()

func apply_slow_to_enemy(enemy: Node, slow_pct: float, duration: float):
	# Set slow metadata
	if not enemy.has_meta("slowed"):
		enemy.set_meta("slowed", true)
		enemy.set_meta("slow_duration", duration)

		# Reduce move speed
		if "move_speed" in enemy:
			var original_speed = enemy.move_speed
			enemy.set_meta("original_move_speed", original_speed)
			enemy.move_speed *= (1.0 - slow_pct)

			print("❄️ Enemy slowed by ", slow_pct * 100, "% for ", duration, " seconds")

			# Schedule slow removal
			await get_tree().create_timer(duration).timeout

			if is_instance_valid(enemy):
				if enemy.has_meta("original_move_speed"):
					enemy.move_speed = enemy.get_meta("original_move_speed")
					enemy.remove_meta("original_move_speed")
				enemy.remove_meta("slowed")
				enemy.remove_meta("slow_duration")
				print("❄️ Slow effect ended")
