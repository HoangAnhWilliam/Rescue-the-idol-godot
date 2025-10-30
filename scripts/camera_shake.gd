extends Camera2D
class_name CameraShake

var shake_amount: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready():
	original_offset = offset

func _process(delta):
	if shake_timer > 0:
		shake_timer -= delta
		
		# Random shake
		offset = original_offset + Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		
		# Giảm dần shake
		shake_amount = lerp(shake_amount, 0.0, delta * 10.0)
	else:
		# Reset về vị trí gốc
		offset = lerp(offset, original_offset, delta * 10.0)

func shake(amount: float = 10.0, duration: float = 0.3):
	shake_amount = amount
	shake_duration = duration
	shake_timer = duration
	
	print("Camera shake: ", amount, " for ", duration, "s")

# Preset shakes
func small_shake():
	shake(5.0, 0.2)

func medium_shake():
	shake(10.0, 0.3)

func large_shake():
	shake(20.0, 0.5)

func crit_shake():
	shake(15.0, 0.4)
