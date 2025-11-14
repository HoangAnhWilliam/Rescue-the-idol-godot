extends Weapon
class_name EnchantingFlute

## Enchanting Flute - EPIC Rarity
## Charm/control weapon that turns enemies against each other
## Charmed enemies attack other enemies then die from heartbreak

# Weapon metadata
var weapon_id: String = "enchanting_flute"
var weapon_name: String = "Enchanting Flute"
var rarity: int = 3  # EPIC
var charm_duration: float = 4.0

func _ready():
	# Set weapon stats
	damage = 0.0  # Doesn't deal direct damage
	attack_speed = 0.4  # 1 hit per 2.5 seconds
	attack_range = 300.0
	is_projectile = false

	super._ready()

	print("🎵 Enchanting Flute equipped - Charm enemies with music!")

func attack(target: CharacterBody2D):
	if not is_instance_valid(target):
		return

	# Charm the enemy
	charm_enemy(target)

	# Visual: Musical notes
	create_music_notes(target.global_position)

	# Reset cooldown
	attack_cooldown = 1.0 / attack_speed

func charm_enemy(enemy: CharacterBody2D):
	if not is_instance_valid(enemy):
		return

	# Set charm metadata
	enemy.set_meta("charmed", true)
	enemy.set_meta("charm_duration", charm_duration)

	# Visual: Pink tint
	if enemy.has_node("Sprite") or enemy.has_node("ColorRect"):
		var sprite = enemy.get_node_or_null("Sprite")
		if not sprite:
			sprite = enemy.get_node_or_null("ColorRect")

		if sprite:
			enemy.set_meta("original_modulate", sprite.modulate)
			sprite.modulate = Color(1.0, 0.5, 0.8)  # Pink tint

	print("💕 Charmed enemy: ", enemy.name, " for ", charm_duration, " seconds")

	# Schedule uncharm and death
	await get_tree().create_timer(charm_duration).timeout

	if is_instance_valid(enemy):
		print("💔 Charm ended - enemy dies from broken heart!")

		# Restore color before death
		if enemy.has_meta("original_modulate"):
			var sprite = enemy.get_node_or_null("Sprite")
			if not sprite:
				sprite = enemy.get_node_or_null("ColorRect")
			if sprite:
				sprite.modulate = enemy.get_meta("original_modulate")

		# Kill charmed enemy
		if enemy.has_method("take_damage"):
			enemy.take_damage(9999, global_position)

		# Clear metadata
		enemy.remove_meta("charmed")
		enemy.remove_meta("charm_duration")

func create_music_notes(position: Vector2):
	# Spawn 5 pink particles floating up
	for i in range(5):
		await get_tree().create_timer(0.1 * i).timeout

		var note_pos = position + Vector2(
			randf_range(-20, 20),
			randf_range(-20, 20)
		)

		ParticleManager.create_hit_effect(
			note_pos,
			Color(1.0, 0.4, 0.8)  # Pink
		)
