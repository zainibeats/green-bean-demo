extends Area2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var enter_timer: Timer = $EnterTimer
@onready var exit_timer: Timer = $ExitTimer
@onready var player: CharacterBody2D = $"../../Player"
@onready var intro_instructions: Node2D = $IntroInstructions

var is_player_inside: bool = true
var is_animation_playing: bool = false

# Ensure the label is hidden initially
func _on_ready() -> void:
	intro_instructions.visible = true
	exit_timer.connect("timeout", Callable(self, "_on_exit_timer_timeout"))
	animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

# Triggered when the player enters the collision area
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not is_animation_playing:
		is_player_inside = true
		exit_timer.stop() # Cancel exit timer if running

# Triggered when the player leaves the collision area
func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" and not is_animation_playing:
		is_player_inside = false
		exit_timer.start()

# Display the message with fade-in animation
func _show_message() -> void:
	if animation_player.is_playing():
		animation_player.stop() # Stop any ongoing animation
	is_animation_playing = true
	intro_instructions.visible = true
	animation_player.play_backwards("fadeouttext") # Play fade-out backward to simulate fade-in


func _on_enter_timer_timeout() -> void:
	if is_player_inside:
		_show_message()

# Hide the message with fade-out animation when the timer times out
func _on_exit_timer_timeout() -> void:
	if not is_player_inside and not is_animation_playing:
		is_animation_playing = true
		animation_player.play("fadeouttext")
		await animation_player.animation_finished
		intro_instructions.visible = false
		queue_free()
		
# Handle animation completion
func _on_animation_finished(animation_name: String) -> void:
	is_animation_playing = false
	if animation_name == "fadeouttext" and not is_player_inside:
		intro_instructions.visible = false # Hide the label only after fade-out completes
