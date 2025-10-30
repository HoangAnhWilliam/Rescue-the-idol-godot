extends Node2D
class_name DamageNumber

@onready var label = $Label
var velocity := Vector2(0, -50)  # Bay lên
var lifetime := 1.0
var elapsed := 0.0

func _ready():
	# Random offset nhẹ
	position += Vector2(randf_range(-10, 10), randf_range(-10, 10))

func setup(damage: float, is_crit: bool = false):
	# Format số
	label.text = str(int(damage))
	
	# Style cho crit vs normal
	if is_crit:
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_color", Color.YELLOW)
		label.text = "CRIT! " + label.text
		velocity.y = -80  # Bay nhanh hơn
	else:
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color.WHITE)
	
	# Outline để dễ đọc
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)

func _process(delta):
	elapsed += delta
	
	# Di chuyển lên
	position += velocity * delta
	
	# Fade out
	var alpha = 1.0 - (elapsed / lifetime)
	label.modulate.a = alpha
	
	# Xóa khi hết thời gian
	if elapsed >= lifetime:
		queue_free()
