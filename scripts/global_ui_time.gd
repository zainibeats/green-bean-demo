extends CanvasLayer

@onready var minutes_label: Label = %MinutesLabel
@onready var seconds_label: Label = %SecondsLabel
@onready var timer_panel: Panel = $Panel
@onready var final_time_panel: Panel = $FinalLabel/Panel
@onready var final_time_label: Label = $FinalLabel/Panel/FinalTime

var rage_panel: Control
var rage_label: Label
var burst_label: Label
var burst_tween: Tween

func _on_ready() -> void:
	final_time_panel.visible = false
	_build_rage_hud()

func _process(delta: float) -> void:
	# Timer remains visible if showing final time
	if Gamestate.game_started and not Gamestate.is_final_level:
		timer_panel.visible = true
		_update_rage_hud()
	else:
		timer_panel.visible = false
		if rage_panel:
			rage_panel.visible = false

func update_timer(minutes: int, seconds: int):
	minutes_label.text = "%02d:" % minutes
	seconds_label.text = "%02d" % seconds

func show_final_message(message: String) -> void:
	# Display the final time
	final_time_label.text = "%s\nDeaths: %d\nBest chain: %d" % [
		message,
		GlobalStats.total_deaths,
		GlobalStats.best_coin_streak,
	]
	final_time_panel.visible = true

func show_death_taunt(message: String) -> void:
	show_status_burst(message, Color(1.0, 0.22, 0.1))

func show_coin_feedback(coin_stats: Dictionary) -> void:
	if int(coin_stats.get("coin_streak", 0)) < 3:
		return
	show_status_burst("CHAIN x%d" % coin_stats["coin_streak"], Color(1.0, 0.86, 0.2))

func show_status_burst(message: String, color: Color = Color.WHITE) -> void:
	if not burst_label:
		_build_rage_hud()

	if burst_tween:
		burst_tween.kill()

	burst_label.text = message
	burst_label.modulate = color
	burst_label.visible = true
	burst_label.scale = Vector2(0.9, 0.9)
	burst_tween = create_tween()
	burst_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	burst_tween.tween_property(burst_label, "scale", Vector2(1.08, 1.08), 0.12)
	burst_tween.tween_interval(0.9)
	burst_tween.tween_property(burst_label, "modulate:a", 0.0, 0.35)
	burst_tween.tween_callback(_hide_burst_label)

func _build_rage_hud() -> void:
	if rage_panel:
		return

	rage_panel = PanelContainer.new()
	rage_panel.name = "RagePanel"
	rage_panel.z_index = 40
	rage_panel.anchors_preset = Control.PRESET_TOP_LEFT
	rage_panel.offset_left = 16.0
	rage_panel.offset_top = 16.0
	rage_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rage_panel)

	var margin_container = MarginContainer.new()
	margin_container.name = "Margin"
	margin_container.add_theme_constant_override("margin_left", 12)
	margin_container.add_theme_constant_override("margin_top", 8)
	margin_container.add_theme_constant_override("margin_right", 12)
	margin_container.add_theme_constant_override("margin_bottom", 8)
	rage_panel.add_child(margin_container)

	rage_label = Label.new()
	rage_label.name = "RageLabel"
	rage_label.add_theme_font_size_override("font_size", 22)
	rage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	margin_container.add_child(rage_label)

	burst_label = Label.new()
	burst_label.name = "BurstLabel"
	burst_label.z_index = 45
	burst_label.anchor_left = 0.5
	burst_label.anchor_right = 0.5
	burst_label.offset_left = -470.0
	burst_label.offset_top = 92.0
	burst_label.offset_right = 470.0
	burst_label.offset_bottom = 150.0
	burst_label.add_theme_font_size_override("font_size", 34)
	burst_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	burst_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	burst_label.visible = false
	add_child(burst_label)

func _update_rage_hud() -> void:
	if not rage_panel:
		return

	rage_panel.visible = true
	var mode_text := ""
	if GlobalStats.is_spite_mode_active():
		mode_text = "\nSPITE %.1fs" % GlobalStats.spite_mode_time_remaining
	rage_label.text = "Deaths: %d\nLevel: %d\nChain: %d\nSpite: %d%%%s" % [
		GlobalStats.total_deaths,
		GlobalStats.level_deaths,
		GlobalStats.coin_streak,
		GlobalStats.get_spite_percent(),
		mode_text,
	]

func _hide_burst_label() -> void:
	if burst_label:
		burst_label.visible = false
		burst_label.modulate.a = 1.0
