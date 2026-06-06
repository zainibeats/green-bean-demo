extends Node2D

const SPEED = 60

var movement_direction = 1

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var killzone: Area2D = $"../../Killzones/Killzone"
@onready var fadeto_black: ColorRect = $"../../Player/FadetoBlack"

# Flip sprite if raycast is colliding
func _process(delta: float) -> void:
	if ray_cast_right.is_colliding():
		movement_direction = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		movement_direction = 1
		animated_sprite.flip_h = false

	# Move the Enemy if play is alive
	
	position.x += movement_direction * SPEED * delta
