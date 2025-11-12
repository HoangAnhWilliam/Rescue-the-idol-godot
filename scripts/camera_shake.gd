extends Node
class_name CameraShake

## Singleton pattern for camera shake effects
## Use static method: CameraShake.shake(intensity, duration)

static var instance: CameraShake = null

var camera: Camera2D = null
var shake_amount: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0

func _ready():
	instance = self

	# Find player's camera
	await get_tree().process_frame  # Wait one frame for player to be ready
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Camera2D"):
		camera = player.get_node("Camera2D")
		print("📸 CameraShake connected to camera!")
	else:
		push_warning("❌ CameraShake: Could not find Camera2D in player!")

## Trigger a camera shake effect
## intensity: Shake strength (5.0 = light, 10.0 = medium, 20.0 = heavy, 30.0 = extreme)
## duration: How long the shake lasts in seconds
static func shake(intensity: float, duration: float):
	if not instance:
		push_warning("CameraShake instance not found!")
		return

	if not instance.camera:
		return  # No camera, no shake

	# If already shaking, use the stronger shake
	if intensity > instance.shake_amount:
		instance.shake_amount = intensity
		instance.shake_duration = duration
		instance.shake_timer = 0.0

	print("📷 Camera shake: ", intensity)

func _process(delta):
	if shake_timer < shake_duration:
		shake_timer += delta

		# Calculate decay (shake gets weaker over time)
		var progress = shake_timer / shake_duration
		var current_intensity = shake_amount * (1.0 - progress)

		# Apply random offset
		if camera:
			camera.offset = Vector2(
				randf_range(-current_intensity, current_intensity),
				randf_range(-current_intensity, current_intensity)
			)
	else:
		# Shake finished, reset camera
		if camera and shake_amount > 0.0:
			camera.offset = Vector2.ZERO
			shake_amount = 0.0
