extends AudioStreamPlayer2D

const MUSIC_VOLUME_PERCENT_KEY: String = "music_volume_percent"
const LEGACY_MUSIC_VOLUME_KEY: String = "music_volume"
const DEFAULT_VOLUME_PERCENT: float = 100.0
const MIN_VOLUME_DB: float = -80.0
const MUSIC_BASE_GAIN_DB: float = 4.0

@onready var menu_music: AudioStreamPlayer2D = $MenuMusic
@onready var background_music: AudioStreamPlayer2D = $"."
@onready var current_volume: float = DEFAULT_VOLUME_PERCENT

var volume_dirty = false # Tracks when volume level is changed by user

func _ready() -> void:
	if not Engine.is_editor_hint():
		#await ConfigManager.ready
		load_volume()
		set_volume(current_volume)

# Play the background music (can be called from GameState)
func play_game_music() -> void:
	if menu_music and menu_music.playing:
		menu_music.stop()
	if background_music and not background_music.playing:
		set_volume(current_volume)
		background_music.play()

func play_menu_music() -> void:
	if background_music and background_music.playing:
		background_music.stop()
	if menu_music:
		set_volume(current_volume)
		menu_music.play()
		
func load_volume() -> void:
	current_volume = get_saved_volume_percent()
	set_volume(current_volume)

func get_saved_volume_percent() -> float:
	var saved_percent = ConfigManager.get_value("audio", MUSIC_VOLUME_PERCENT_KEY, null)
	if saved_percent != null:
		return clampf(float(saved_percent), 0.0, DEFAULT_VOLUME_PERCENT)

	var legacy_volume_db = ConfigManager.get_value("audio", LEGACY_MUSIC_VOLUME_KEY, 0.0)
	return remap(clampf(float(legacy_volume_db), MIN_VOLUME_DB, 0.0), MIN_VOLUME_DB, 0.0, 0.0, DEFAULT_VOLUME_PERCENT)

func set_volume(volume_percent: float) -> void:
	current_volume = clampf(volume_percent, 0.0, DEFAULT_VOLUME_PERCENT)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _percent_to_db(current_volume))
	if background_music:
		background_music.volume_db = 0.0
	if menu_music:
		menu_music.volume_db = 0.0

func _percent_to_db(volume_percent: float) -> float:
	if volume_percent <= 0.0:
		return MIN_VOLUME_DB

	return linear_to_db(volume_percent / DEFAULT_VOLUME_PERCENT) + MUSIC_BASE_GAIN_DB

func save_volume() -> void:
	ConfigManager.set_value("audio", MUSIC_VOLUME_PERCENT_KEY, current_volume)
	ConfigManager.save_config()
