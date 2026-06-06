extends Area2D

@onready var game_manager: Node = %GameManager
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		game_manager.add_point()
		var coin_stats := GlobalStats.record_coin()
		GlobalUiTime.show_coin_feedback(coin_stats)
		animation_player.play("pickup")
