extends Area2D
class_name GhostProjectile

# Projectile properties
@export var damage: float = 8.0
@export var speed: float = 150.0
@export var lifetime: float = 5.0
@export var pierce: bool = false  # Ghost projectiles don't pierce (for now)

# State
var velocity: Vector2 = Vector2.ZERO
var elapsed: float = 0.0
var hit_enemies: Array = []  # Track hit enemies

func _ready():
	# Visual setup will be done in scene
	print("Ghost projectile spawned")
	
	# Connect collision
	body_entered.connect(_on_body_entered)

func setup(direction: Vector2, proj_damage: float = 8.0):
	velocity = direction.normalized() * speed
	damage = proj_damage
	
	# Rotate visual to face direction
	rotation = velocity.angle()

func _process(delta):
	# Move projectile
	position += velocity * delta
	
	# Lifetime countdown
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D):
	# Check if hit player
	if body.is_in_group("player"):
		# Damage player
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("Ghost projectile hit player for ", damage, " damage!")
		
		# Destroy projectile
		queue_free()
	
	# Ghost projectiles ignore enemies (only hit player)
