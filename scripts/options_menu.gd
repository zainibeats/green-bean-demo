extends CanvasLayer

@onready var master_bus: int = AudioServer.get_bus_index("Master")
@onready var button_sound: AudioStreamPlayer2D = $"Button Sound"
@onready var master_slider: HSlider = $MarginContainer/VBoxContainer/MasterSlider
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/VolumeSlider
@onready var confirmation_dialog: ConfirmationDialog = $MainMenuContainer/ConfirmationDialog
@onready var reset_level: Button = $ResetContainer/ResetLevel
@onready var back: Button = $BackMarginContainer/Back

func _on_ready() -> void:
	if not ConfigManager.is_connected("ready", Callable(self, "_on_config_ready")):
		ConfigManager.connect("ready", Callable(self, "_on_config_ready"))

	if ConfigManager.config:
		_on_config_ready()

func _on_config_ready() -> void:
	var saved_music_volume = Music.get_saved_volume_percent()
	Music.set_volume(saved_music_volume)
	music_slider.value = saved_music_volume
	master_slider.value = ConfigManager.get_value("audio", "master_volume", 0)

func _on_back_pressed() -> void:
	back.disabled = true
	await _play_button_sound()

	if Gamestate.is_paused:
		Gamestate.resume_game()
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_reset_level_pressed() -> void:
	reset_level.disabled = true
	await _play_button_sound()
	Gamestate.reset_level()

func _on_main_menu_pressed() -> void: 
	button_sound.play()
	confirmation_dialog.popup_centered()

func _on_confirmation_yes_pressed() -> void:
	await _play_button_sound()
	Gamestate.exit_to_main_menu()

func _on_confirmation_no_pressed() -> void:
	await _play_button_sound()
	confirmation_dialog.hide()

func _on_master_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus, value)

func _on_master_slider_drag_ended(value_changed: bool) -> void:
	_save_audio_value("master_volume", master_slider.value)

func _on_music_slider_value_changed(value: float) -> void:
	Music.set_volume(value)

func _on_volume_slider_drag_ended(value_changed: bool) -> void:
	var music_volume = music_slider.value
	Music.set_volume(music_volume)
	_save_audio_value(Music.MUSIC_VOLUME_PERCENT_KEY, music_volume)

func _play_button_sound() -> void:
	button_sound.play()
	await button_sound.finished

func _save_audio_value(key: String, value: float) -> void:
	ConfigManager.set_value("audio", key, value)
	ConfigManager.save_config()
