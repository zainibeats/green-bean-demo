extends Area2D

const MUSIC_FADE_VOLUME_DB: float = -80.0
const FINISH_FADE_DURATION: float = 1.5

@onready var player: CharacterBody2D = $"../Player"
@onready var timer: Timer = $Timer
@onready var finish_sound: AudioStreamPlayer2D = $LevelFinishSound

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player" or Gamestate.is_level_finished:
		return

	_start_finish_sequence(body)

func _on_timer_timeout() -> void:
	Gamestate.level_complete()

func _start_finish_sequence(body: Node2D) -> void:
	Gamestate.is_level_finished = true
	Gamestate.cannot_move = true
	_fade_music_out()
	_fade_player_to_black(body)
	finish_sound.play()
	# The timer gives the fade and finish sound time to complete before loading.
	timer.start()

func _fade_music_out() -> void:
	var music_tween = create_tween()
	music_tween.tween_property(
		Music.background_music,
		"volume_db",
		MUSIC_FADE_VOLUME_DB,
		FINISH_FADE_DURATION
	)

func _fade_player_to_black(body: Node2D) -> void:
	var fade_overlay = body.get_node("FadetoBlack")
	if fade_overlay:
		var fade_tween = create_tween()
		fade_tween.tween_property(fade_overlay, "modulate:a", 1.0, FINISH_FADE_DURATION)
