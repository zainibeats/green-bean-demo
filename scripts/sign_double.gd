extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var exit_timer: Timer = $ExitTimer
@onready var enter_timer: Timer = $EnterTimer

var is_player_inside: bool = false
var is_animation_playing: bool = false
var has_shown_hint: bool = false

# Ensure the label is hidden initially
func _on_ready() -> void:
	label.visible = false
	#exit_timer.connect("timeout", Callable(self, "_on_exit_timer_timeout"))
	#enter_timer.connect("timeout", Callable(self, "_on_enter_timer_timeout"))
	animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

# Triggered when the player enters the collision area
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not is_player_inside:
		is_player_inside = true
		has_shown_hint = false
		enter_timer.start(8)
		exit_timer.stop() # Cancel exit timer if running

# Triggered when the player leaves the collision area
func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_player_inside = false
		exit_timer.start()

# Display the message with fade-in animation
func _show_message() -> void:
	if not is_animation_playing and not has_shown_hint:
		has_shown_hint = true
		label.visible = true
		animation_player.play("fadeintext")

# Hide the message with fade-out animation when the timer times out
func _on_exit_timer_timeout() -> void:
	if not is_player_inside and not is_animation_playing:
		is_animation_playing = true
		animation_player.play_backwards("fadeintext")
		await animation_player.animation_finished
		label.visible = false
		queue_free()

func _on_animation_finished(animation_name: String) -> void:
	is_animation_playing = false
	if animation_name == "fadeintext" and not is_player_inside:
		label.visible = false # Hide the label only after fade-out completes
		
func _on_enter_timer_timeout() -> void:
	if is_player_inside and not is_animation_playing:
		_show_message()
