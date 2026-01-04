extends Node3D

## Movement speed in meters per second
@export var move_speed: float = 2.5
## Minimum distance to maintain from player
@export var stop_distance: float = 2.0
## Rotation speed (radians per second)
@export var rotation_speed: float = 5.0

var player: Node3D


func _ready() -> void:
	# Find the player in the scene
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		# Fallback: search by name
		player = get_node_or_null("/root/Main/Player")


func _physics_process(delta: float) -> void:
	if not player:
		return

	var to_player := player.global_position - global_position
	to_player.y = 0  # Keep movement horizontal
	var distance := to_player.length()

	# Rotate to face player
	if distance > 0.1:
		var target_rotation := atan2(to_player.x, to_player.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

	# Move toward player if not too close
	if distance > stop_distance:
		var direction := to_player.normalized()
		global_position += direction * move_speed * delta
