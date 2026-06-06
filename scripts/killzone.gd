extends Area2D

const FADE_DURATION: float = 1.0
const DEATH_TIME_SCALE: float = 0.5

@onready var timer: Timer = $Timer

var timer_duration: float = 1.0

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player" or Gamestate.is_invincible:
		return

	_fade_player_to_black(body)
	_notify_player_collision(body)
	_enter_death_state()
	_remove_player_collision(body)
	_start_reload_timer()
	
func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
	Gamestate.cannot_move = false
	Gamestate.alive = true

func _fade_player_to_black(body: Node2D) -> void:
	var fade_node = body.get_node("FadetoBlack")
	if fade_node and fade_node is ColorRect:
		var tween = create_tween()
		tween.tween_property(fade_node, "modulate:a", 1.0, FADE_DURATION)

func _notify_player_collision(body: Node2D) -> void:
	if body.has_method("_on_body_entered"):
		body._on_body_entered(self)

func _enter_death_state() -> void:
	Engine.time_scale = DEATH_TIME_SCALE
	Gamestate.cannot_move = true
	Gamestate.alive = false

func _remove_player_collision(body: Node2D) -> void:
	if body.has_node("CollisionShape2D"):
		body.get_node("CollisionShape2D").queue_free()

func _start_reload_timer() -> void:
	timer.wait_time = timer_duration
	timer.start()
