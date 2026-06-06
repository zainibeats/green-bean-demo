extends Node

var total_coins: int = 0
var total_keys: int = 0
var boy_skin_unlocked = false

const SPITE_MAX: float = 100.0
const SPITE_RUN_DURATION: float = 8.0

var total_deaths: int = 0
var level_deaths: int = 0
var coins_this_life: int = 0
var coin_streak: int = 0
var best_coin_streak: int = 0
var spite_meter: float = 0.0
var spite_mode_time_remaining: float = 0.0
var pending_spite_mode: bool = false
var last_taunt: String = ""

var death_taunts: Array[String] = [
	"Again. Cleaner this time.",
	"That spike has your timing downloaded.",
	"You saw the trap. Your hands disagreed.",
	"The checkpoint is your pride.",
	"Tiny mistake. Huge bill.",
	"Respect the jump. Then disrespect it faster.",
	"Greed tax collected.",
	"The level is laughing quietly."
]

func reset_run_stats() -> void:
	total_deaths = 0
	level_deaths = 0
	coins_this_life = 0
	coin_streak = 0
	best_coin_streak = 0
	spite_meter = 0.0
	spite_mode_time_remaining = 0.0
	pending_spite_mode = false
	last_taunt = ""

func start_next_level() -> void:
	level_deaths = 0
	coins_this_life = 0
	coin_streak = 0
	last_taunt = ""

func record_coin() -> Dictionary:
	total_coins += 1
	coins_this_life += 1
	coin_streak += 1
	best_coin_streak = max(best_coin_streak, coin_streak)
	spite_meter = min(SPITE_MAX, spite_meter + 3.0 + min(coin_streak, 10) * 0.5)
	return {
		"coin_streak": coin_streak,
		"best_coin_streak": best_coin_streak,
		"spite_meter": spite_meter,
	}

func record_death() -> String:
	total_deaths += 1
	level_deaths += 1
	coins_this_life = 0
	coin_streak = 0
	spite_meter = min(SPITE_MAX, spite_meter + 24.0 + min(level_deaths, 8) * 2.0)
	pending_spite_mode = spite_meter >= SPITE_MAX
	last_taunt = _pick_death_taunt()
	return last_taunt

func try_start_spite_mode() -> bool:
	if not pending_spite_mode:
		return false

	pending_spite_mode = false
	spite_meter = max(0.0, spite_meter - SPITE_MAX)
	spite_mode_time_remaining = SPITE_RUN_DURATION
	return true

func update_spite_mode(delta: float) -> void:
	if spite_mode_time_remaining > 0.0:
		spite_mode_time_remaining = max(0.0, spite_mode_time_remaining - delta)

func is_spite_mode_active() -> bool:
	return spite_mode_time_remaining > 0.0

func get_speed_multiplier() -> float:
	return 1.18 if is_spite_mode_active() else 1.0

func get_jump_multiplier() -> float:
	return 1.08 if is_spite_mode_active() else 1.0

func get_gravity_multiplier() -> float:
	return 0.92 if is_spite_mode_active() else 1.0

func get_spite_percent() -> int:
	return int(round((spite_meter / SPITE_MAX) * 100.0))

func _pick_death_taunt() -> String:
	var index := (total_deaths + level_deaths * 3) % death_taunts.size()
	return death_taunts[index]
