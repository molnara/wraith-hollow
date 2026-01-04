extends Node3D

## Movement speed in meters per second
@export var move_speed: float = 2.5
## Minimum distance to maintain from player
@export var stop_distance: float = 2.0
## Rotation speed (radians per second)
@export var rotation_speed: float = 5.0
## Time between attacks in seconds
@export var attack_cooldown: float = 2.0

@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer
@onready var model: Node3D = $Model
@onready var armature: Node3D = $Model/Armature
@onready var skeleton: Skeleton3D = $Model/Armature/Skeleton3D

var player: Node3D
var hips_bone_idx: int = -1
var debug_frame_counter: int = 0
var is_moving: bool = false
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_position: Vector3  # Lock position during attack to prevent root motion drift

# Animation name mapping (logical name -> GLB name)
const ANIM_MAP := {
	"Looking": "Axe_Spin_Attack",
	"Spin_Attack": "Idle",
	"Charged_Attack": "Charged_Slash",
	"Slash_Attack": "Left_Slash",
	"Idle": "Running",
	"Dead": "Walking",
	"Sprint": "Combat_Stance",
	"Walking": "Dead"
}


func _ready() -> void:
	# Cache hips bone index for root motion cancellation
	hips_bone_idx = skeleton.find_bone("Hips")

	# Set animations to loop
	_set_animation_looping("Walking")
	_set_animation_looping("Idle")

	# Connect animation finished signal for attack
	anim_player.animation_finished.connect(_on_animation_finished)

	# Find the player in the scene
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		# Fallback: search by name
		player = get_node_or_null("/root/Main/Player")


func _get_glb_anim_name(logical_name: String) -> String:
	return ANIM_MAP.get(logical_name, logical_name)


func _play_anim(logical_name: String) -> void:
	anim_player.play(_get_glb_anim_name(logical_name))


func _set_animation_looping(logical_name: String) -> void:
	var glb_name := _get_glb_anim_name(logical_name)
	var anim := anim_player.get_animation(glb_name)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR


func _on_animation_finished(anim_name: String) -> void:
	# Check if the finished animation is Slash_Attack
	if anim_name == _get_glb_anim_name("Slash_Attack"):
		is_attacking = false
		attack_timer = attack_cooldown


func _process(_delta: float) -> void:
	# Cancel root motion by offsetting Model to keep Hips centered
	# Run in _process to apply after animation updates every visual frame
	if hips_bone_idx >= 0:
		var hips_pose := skeleton.get_bone_global_pose_no_override(hips_bone_idx).origin
		var scale_factor := armature.scale.x  # Uniform scale (0.01)
		# Offset Model in opposite direction of Hips to cancel root motion
		model.position.x = -hips_pose.x * scale_factor
		model.position.z = -hips_pose.z * scale_factor

	# Debug logging every 60 frames
	debug_frame_counter += 1
	if debug_frame_counter >= 60:
		debug_frame_counter = 0
		var hips_pose := skeleton.get_bone_global_pose_no_override(hips_bone_idx).origin if hips_bone_idx >= 0 else Vector3.ZERO
		print("=== Skeleton Warrior Debug ===")
		print("  Anim: ", anim_player.current_animation)
		print("  Hips pose (cm): ", hips_pose)
		print("  Model pos: ", model.position)
		print("  Armature scale: ", armature.scale.x)


func _physics_process(delta: float) -> void:
	if not player:
		return

	# Update attack cooldown
	if attack_timer > 0:
		attack_timer -= delta

	var to_player := player.global_position - global_position
	to_player.y = 0  # Keep movement horizontal
	var distance := to_player.length()

	# Rotate to face player (unless attacking)
	if distance > 0.1 and not is_attacking:
		var target_rotation := atan2(to_player.x, to_player.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

	# Lock position while attacking to prevent root motion drift
	if is_attacking:
		global_position = attack_position
		return

	# Move toward player if not too close
	if distance > stop_distance:
		var direction := to_player.normalized()
		global_position += direction * move_speed * delta
		if not is_moving:
			is_moving = true
			_play_anim("Walking")
	else:
		is_moving = false
		# Attack if cooldown is ready
		if attack_timer <= 0:
			is_attacking = true
			attack_position = global_position
			_play_anim("Slash_Attack")
		else:
			var current := anim_player.current_animation
			var idle_glb := _get_glb_anim_name("Idle")
			var attack_glb := _get_glb_anim_name("Slash_Attack")
			if current != idle_glb and current != attack_glb:
				_play_anim("Idle")
