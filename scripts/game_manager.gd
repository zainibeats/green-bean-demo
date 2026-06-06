extends Node

@onready var player: CharacterBody2D = $"../Player"
@onready var score_label: Label = $ScoreLabel
@onready var coins_done_sound: AudioStreamPlayer2D = $"../Player/Coinsdonesound"

var score: int = 0
var total_coins: int = 30

func _on_ready() -> void:
	if Gamestate.game_started:
		update_score_label()

func add_point() -> void:
	score += 1
	update_score_label()

	_play_completion_sound_if_needed()

func update_score_label() -> void:
	score_label.text = _get_score_text()

func _get_score_text() -> String:
	var streak_text := ""
	if GlobalStats.coin_streak >= 3:
		streak_text = "  x%d chain" % GlobalStats.coin_streak
	return "%d of %d coins%s" % [score, total_coins, streak_text]

func _play_completion_sound_if_needed() -> void:
	if score == total_coins:
		coins_done_sound.play()
