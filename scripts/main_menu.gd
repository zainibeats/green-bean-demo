extends Control

const GAME_SCENE_PATH: String = "res://scenes/game1.tscn"
const OPTIONS_SCENE_PATH: String = "res://scenes/options_menu.tscn"
const START_DELAY: float = 2.5
const FADE_DURATION: float = 2.0

@export var tween_intensity: float
@export var tween_duration: float
@onready var start: Button = $VBoxContainer/Start
@onready var options: Button = $VBoxContainer/Options
@onready var quit: Button = $VBoxContainer/Quit
@onready var button_sound: AudioStreamPlayer2D = $"Button Sound"
@onready var start_sound: AudioStreamPlayer2D = $StartSound
@onready var fadeto_black: ColorRect = $FadetoBlack
@onready var start_delay_timer: Timer = $Timers/Playtimer
@onready var animation_player: AnimationPlayer = $VBoxContainer/TitleReal/AnimationPlayer

func _on_ready() -> void:
	if Music.background_music.playing:
		Music.background_music.stop()
	
	if not Music.menu_music.playing:
		Music.play_menu_music()

func _on_start_pressed() -> void:
	start.disabled = true
	Music.menu_music.stop()
	start_sound.play()
	start_delay_timer.start(START_DELAY)
	
	_fade_to_black(FADE_DURATION)
	animation_player.play("shake")

func _on_playtimer_timeout() -> void:
	Gamestate.start_game()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_options_pressed() -> void:
	button_sound.play()
	options.disabled = true
	await button_sound.finished
	get_tree().change_scene_to_file(OPTIONS_SCENE_PATH)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _fade_to_black(duration: float) -> void:
	var fade_tween = create_tween()
	fade_tween.tween_property(fadeto_black, "modulate:a", 1.0, duration)
