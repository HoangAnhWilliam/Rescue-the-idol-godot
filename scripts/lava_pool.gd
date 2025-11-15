extends Area2D
class_name LavaPool

var damage_per_second: float = 5.0
var pool_radius: float = 20.0
var pool_lifetime: float = 3.0
var damage_timer: float = 0.0

var players_in_pool: Array = []

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	print("Lava pool created at ", global_position)

func _process(delta):
	pool_lifetime -= delta
	damage_timer -= delta

	# Apply damage to players in pool
	if damage_timer <= 0:
		for player in players_in_pool:
			if is_instance_valid(player) and player.has_method("take_damage"):
				player.take_damage(damage_per_second)

		if players_in_pool.size() > 0:
			damage_timer = 1.0  # Damage every second

	# Despawn after lifetime
	if pool_lifetime <= 0:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if not players_in_pool.has(body):
			players_in_pool.append(body)
			print("Player entered lava pool")

func _on_body_exited(body):
	if body.is_in_group("player"):
		players_in_pool.erase(body)
		print("Player exited lava pool")

func _on_area_entered(area):
	if area.is_in_group("player"):
		var player = area.get_parent()
		if player and not players_in_pool.has(player):
			players_in_pool.append(player)

func _on_area_exited(area):
	if area.is_in_group("player"):
		var player = area.get_parent()
		if player:
			players_in_pool.erase(player)
