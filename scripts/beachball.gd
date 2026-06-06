extends Node2D

const SPEED = 60

var movement_direction = 1

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var killzone: Area2D = $Killzone
#@onready var fadeto_black: ColorRect = $Player/FadetoBlack
@onready var explode_sound: AudioStreamPlayer2D = $ExplodeSound

func _ready() -> void:
	# Ensure the body_entered signal is connected
	killzone.connect("body_entered", Callable(self, "_on_Area2D_body_entered"))
	# Connect to the animations frame changed signal
	animated_sprite.connect("frame_changed", Callable(self, "_on_frame_changed"))

# Flip sprite if raycast is colliding
func _process(delta: float) -> void:
	if ray_cast_right.is_colliding():
		movement_direction = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		movement_direction = 1
		animated_sprite.flip_h = false

	# Move the Enemy if player is alive
	if Gamestate.alive:
		position.x += movement_direction * SPEED * delta

# Called when the player enters the enemy's kill zone
func _on_Area2D_body_entered(body: Node2D) -> void:
		if body.name == "Player":
			animated_sprite.play("explode")

# Play explosion sound on frame of choice
func _on_frame_changed() -> void:
	if animated_sprite.frame == 5:
		explode_sound.play()
