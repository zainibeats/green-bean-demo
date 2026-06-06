extends Node

const FILE_BEGIN: String = "res://scenes/game_"
const FINAL_LEVEL_PATH: String = "res://scenes/game_3.tscn"
const MAIN_MENU_PATH: String = "res://scenes/MainMenu.tscn"
const PAUSE_COOLDOWN: float = 0.25
const PAUSE_TIME_SCALE: float = 0.0001 ** 3

@onready var game_started: bool = false
@onready var is_final_level: bool = false
@onready var pause_menu_scene = preload("res://scenes/options_menu.tscn")
var start_time: float = 0.0
var is_level_finished: bool = false
var is_paused: bool = false
var cannot_move: bool = false
var alive: bool = true
var default_music_pitch: float = 1.14
var pause_menu: CanvasLayer
var last_pause_time: float = 0.0
var can_pause: bool = false

var debug_mode: bool = false
var is_invincible: bool = false

func _ready() -> void:
	ConfigManager.load_config()
	set_process(false)

func _process(delta: float) -> void:
	if game_started and not is_final_level:
		start_time += delta
		GlobalUiTime.update_timer(_get_elapsed_minutes(), _get_elapsed_seconds())

func start_game() -> void:
	if not ConfigManager.ready:
		await ConfigManager.ready
	
	_apply_audio_settings()
	can_pause = true
	game_started = true
	start_time = 0 
	set_process(true)
	_show_active_timer()
		
func level_complete() -> void:
	is_level_finished = true
	_restart_background_music()
	
	var next_level_path := _get_next_level_path()
	
	# The final scene is a results screen, not a playable timed level.
	if next_level_path == FINAL_LEVEL_PATH:
		_prepare_final_level()
		
	get_tree().change_scene_to_file(next_level_path)
	reset()
	
func reset() -> void:
	Engine.time_scale = 1.0
	cannot_move = false
	is_level_finished = false

func freeze_timer() -> void:
	set_process(false)

func pause_game() -> void:
	if is_paused or not alive or (pause_menu and pause_menu != null):
		return 

	Engine.time_scale = PAUSE_TIME_SCALE
	is_paused = true
	pause_menu = pause_menu_scene.instantiate()
	get_tree().current_scene.add_child(pause_menu)
	_configure_pause_menu()
	
func resume_game() -> void:
	if not is_paused:
		return 

	is_paused = false
	Engine.time_scale = 1

	if pause_menu:
		pause_menu.call_deferred("queue_free")
		pause_menu = null

func exit_to_main_menu() -> void:
	reset()
	can_pause = false
	game_started = false
	is_paused = false
	is_final_level = false
	Engine.time_scale = 1.0
	
	Music.background_music.stop()
	Music.background_music.pitch_scale = default_music_pitch 
	
	GlobalUiTime.hide()
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
	ConfigManager.save_config()

func reset_level() -> void:
	var current_scene_path = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file(current_scene_path)
	
	can_pause = true
	start_time = 0
	reset()
	resume_game()
	
	# Wait for the reloaded scene tree before restarting its music.
	await get_tree().process_frame
	Music.background_music.stop()
	Music.background_music.seek(0)
	Music.play_game_music()

func _input(event: InputEvent) -> void:
	if not _can_handle_pause_input(event):
		return

	last_pause_time = Time.get_ticks_msec()
	if is_paused:
		resume_game()
	elif can_pause:
		pause_game()

func _apply_audio_settings() -> void:
	var master_volume = ConfigManager.get_value("audio", "master_volume", 0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_volume)
	Music.play_game_music()

func _show_active_timer() -> void:
	if not GlobalUiTime.visible:
		GlobalUiTime.show()
	if GlobalUiTime.final_time_panel.visible:
		GlobalUiTime.final_time_panel.hide()

func _restart_background_music() -> void:
	Music.background_music.seek(0)
	Music.set_volume(Music.current_volume)
	Music.background_music.play()

func _get_next_level_path() -> String:
	var current_scene_file = get_tree().current_scene.scene_file_path
	# The level filenames are game1.tscn, game_2.tscn, game_3.tscn.
	var next_level_number = current_scene_file.to_int() + 2
	return FILE_BEGIN + str(next_level_number) + ".tscn"

func _prepare_final_level() -> void:
	is_final_level = true
	freeze_timer()
	GlobalUiTime.show_final_message("Final Time: %s" % _format_elapsed_time())
	Music.background_music.pitch_scale = 0.95

func _format_elapsed_time() -> String:
	return "%d:%02d" % [_get_elapsed_minutes(), _get_elapsed_seconds()]

func _get_elapsed_minutes() -> int:
	return int(start_time / 60)

func _get_elapsed_seconds() -> int:
	return int(fmod(start_time, 60))

func _configure_pause_menu() -> void:
	pause_menu.get_node("MainMenuContainer").visible = true
	pause_menu.get_node("ResetContainer").visible = true
	pause_menu.get_node("Panel").visible = false

func _can_handle_pause_input(event: InputEvent) -> bool:
	if not game_started or not alive or not event.is_action_pressed("pause"):
		return false
	return (Time.get_ticks_msec() - last_pause_time) > PAUSE_COOLDOWN * 1000
