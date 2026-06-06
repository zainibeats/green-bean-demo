extends CanvasLayer

@onready var minutes_label: Label = %MinutesLabel
@onready var seconds_label: Label = %SecondsLabel
@onready var timer_panel: Panel = $Panel
@onready var final_time_panel: Panel = $FinalLabel/Panel
@onready var final_time_label: Label = $FinalLabel/Panel/FinalTime

func _on_ready() -> void:
	final_time_panel.visible = false

func _process(delta: float) -> void:
	# Timer remains visible if showing final time
	if Gamestate.game_started and not Gamestate.is_final_level:
		timer_panel.visible = true
	else:
		timer_panel.visible = false

func update_timer(minutes: int, seconds: int):
	minutes_label.text = "%02d:" % minutes
	seconds_label.text = "%02d" % seconds

func show_final_message(message: String) -> void:
	# Display the final time
	final_time_label.text = message
	final_time_panel.visible = true
