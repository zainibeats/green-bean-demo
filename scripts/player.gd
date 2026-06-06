extends CharacterBody2D

const SPEED: float = 80.0
const RUN_MULTIPLIER: float = 1.5
const CROUCH_SPEED: float = 40.0
const JUMP_VELOCITY: float = -300.0
const MAX_JUMPS: int = 2
const COYOTE_TIME: float = 0.2
const JUMP_BUFFER_TIME: float = 0.12
const JUMP_CUT_MULTIPLIER: float = 0.45
const FALL_GRAVITY_MULTIPLIER: float = 1.35
const APEX_GRAVITY_MULTIPLIER: float = 0.65
const APEX_GRAVITY_THRESHOLD: float = 40.0
const EDGE_RAY_RIGHT: Vector2 = Vector2(8, 2)
const EDGE_RAY_LEFT: Vector2 = Vector2(-8, 2)
const LANDING_GRUNT_CHANCE: float = 0.8
const DEATH_SOUND_1_CHANCE: float = 0.8

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dust_fx: AnimatedSprite2D = $DustFX
@onready var jump_sound: AudioStreamPlayer2D = $Sounds/JumpSound
@onready var jump_sound_2: AudioStreamPlayer2D = $Sounds/JumpSound2
@onready var grunt_sound: AudioStreamPlayer2D = $Sounds/GruntSound
@onready var grunt_sound_2: AudioStreamPlayer2D = $Sounds/GruntSound2
@onready var hurt_sound_1: AudioStreamPlayer2D = $Sounds/HurtSound
@onready var hurt_sound_2: AudioStreamPlayer2D = $Sounds/HurtSound2
@onready var edge_ray: RayCast2D = $EdgeRay
@onready var animated_sprites = [
	$AnimatedSprite2D,
	$AnimatedSprite_Boy,
]

var active_skin_index = 0
var jumps_remaining = MAX_JUMPS
var coyote_timer = 0.0 
var is_airborne = false
var has_died = false
var is_first_landing = true
var double_jump_started = false
var jump_started = false
var safe_landing = true
var is_crouched = false
var jump_buffer_timer = 0.0

# DEBUG VARIABLES. DELETE WHEN EXPORTING
var teleport_target = null
var teleport_speed: float = 200.0

func _on_ready() -> void:
	hurt_sound_1.connect("finished", Callable(self, "_on_death_sound_finished"))
	hurt_sound_2.connect("finished", Callable(self, "_on_death_sound_finished"))

	_set_active_skin(active_skin_index)
	if GlobalStats.try_start_spite_mode():
		GlobalUiTime.show_status_burst("SPITE MODE", Color(1.0, 0.18, 0.12))

func _set_active_skin(index: int) -> void:
	for i in range(animated_sprites.size()):
		animated_sprites[i].visible = i == index # Only make the chosen sprite visible

func change_skin(index: int) -> void:
	if index >= 0 and index < animated_sprites.size():
		active_skin_index = index
		_set_active_skin(active_skin_index)

func _physics_process(delta: float) -> void:
	if Gamestate.is_paused:
		return
	
	if not Gamestate.alive and not has_died:
		_handle_death()
		return

	if Gamestate.cannot_move:
		velocity = Vector2.ZERO
		return

	GlobalStats.update_spite_mode(delta)
	_update_vertical_state(delta)

	_handle_crouch()
	
	if not is_crouched:
		_handle_jump(delta)
		_handle_jump_release()
	
	_handle_horizontal_movement()
	_update_animation()
	
	_handle_debug()

	move_and_slide()

func _update_vertical_state(delta: float) -> void:
	if is_on_floor():
		_reset_ground_state()
		return

	velocity += _get_weighted_gravity() * delta
	coyote_timer -= delta
	is_airborne = true

func _get_weighted_gravity() -> Vector2:
	var gravity := get_gravity()
	if velocity.y > 0.0:
		gravity *= FALL_GRAVITY_MULTIPLIER
	elif absf(velocity.y) < APEX_GRAVITY_THRESHOLD:
		gravity *= APEX_GRAVITY_MULTIPLIER
	return gravity * GlobalStats.get_gravity_multiplier()

func _handle_debug() -> void:
	if Input.is_action_pressed("debug_mode") and not Gamestate.debug_mode:
		Gamestate.debug_mode = true
		print("Debug Mode ON")
		Gamestate.start_game()
	if Gamestate.debug_mode:
		if Input.is_action_pressed("level_complete"):
			Gamestate.level_complete()
			print("Cheat Activated: Level Complete!")
		if Input.is_action_pressed("click_debug"):
			teleport_target = get_global_mouse_position()
			velocity = position.direction_to(get_global_mouse_position()) * teleport_speed

func _handle_crouch() -> void:
	if Input.is_action_pressed("crouch"):
		if not is_crouched:
			is_crouched = true
			animated_sprite.play("crouch")
			_stop_dust_fx()
	else:
		if is_crouched:
			is_crouched = false
			animated_sprite.play("idle")

		if velocity.x != 0 and not dust_fx.is_playing():
			_play_dust_fx()

func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

	if jump_buffer_timer <= 0.0:
		return

	# Coyote time allows a first jump just after leaving an edge.
	if _can_first_jump():
		_perform_first_jump()
	elif _can_double_jump():
		_perform_double_jump()
	elif _can_air_jump_without_coyote():
		_perform_air_jump_without_coyote()

func _handle_jump_release() -> void:
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

func _can_first_jump() -> bool:
	return jumps_remaining == MAX_JUMPS and (is_on_floor() or coyote_timer > 0)

func _can_double_jump() -> bool:
	return jumps_remaining == 1

func _can_air_jump_without_coyote() -> bool:
	return jumps_remaining == MAX_JUMPS and is_airborne and coyote_timer <= 0

func _perform_first_jump() -> void:
	_perform_jump("jump")
	coyote_timer = 0.0
	jump_sound.play()

func _perform_double_jump() -> void:
	_perform_jump("doublejump", true)
	jump_sound_2.play()

func _perform_air_jump_without_coyote() -> void:
	_perform_jump("jump")
	jumps_remaining -= 1
	jump_sound.play()

func _perform_jump(animation: String, is_double_jump: bool = false) -> void:
	velocity.y = JUMP_VELOCITY * GlobalStats.get_jump_multiplier()
	animated_sprite.play(animation)
	jumps_remaining -= 1
	jump_buffer_timer = 0.0
	jump_started = true
	if is_double_jump:
		double_jump_started = true

func _reset_ground_state() -> void:
	if has_died:
		return

	if jumps_remaining != MAX_JUMPS:
		jumps_remaining = MAX_JUMPS
		double_jump_started = false
	coyote_timer = COYOTE_TIME
	
	if is_airborne and not is_first_landing:
		_play_landing_sound()
		
	is_airborne = false
	is_first_landing = false
	jump_started = false

func _play_landing_sound() -> void:
	if randf() <= LANDING_GRUNT_CHANCE:
		grunt_sound.play()
	else:
		grunt_sound_2.play()

func _handle_horizontal_movement() -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var current_speed := _get_current_speed()
	
	if is_on_floor() and is_crouched:
		current_speed = CROUCH_SPEED
		direction = _block_crouch_edge_movement(direction)
	
	velocity.x = direction * current_speed if direction != 0  else move_toward(
		velocity.x,
		0,
		current_speed,
		)
		
	_update_facing(direction)

func _get_current_speed() -> float:
	return SPEED * (1.0 if Input.is_action_pressed("walk") else RUN_MULTIPLIER) * GlobalStats.get_speed_multiplier()

func _block_crouch_edge_movement(direction: float) -> float:
	if edge_ray.is_colliding():
		return direction
	# Prevent crouch-walking off a ledge when the forward edge ray has no floor.
	if (direction > 0 and edge_ray.target_position.x > 0) or (direction < 0 and edge_ray.target_position.x < 0):
		return 0.0
	return direction

func _update_facing(direction: float) -> void:
	if direction > 0:
		animated_sprite.flip_h = false
		dust_fx.flip_h = false
		dust_fx.position.x = -abs(dust_fx.position.x)
		edge_ray.target_position = EDGE_RAY_RIGHT
	elif direction < 0:
		animated_sprite.flip_h = true
		dust_fx.flip_h = true
		dust_fx.position.x = abs(dust_fx.position.x)
		edge_ray.target_position = EDGE_RAY_LEFT
		
func _update_animation() -> void:
	if is_on_floor():
		_update_ground_animation()
		return

	_update_air_animation()

func _update_ground_animation() -> void:
	if is_crouched:
		animated_sprite.play("crouch")
		_stop_dust_fx()
	elif velocity.x != 0:
		animated_sprite.play("walk" if Input.is_action_pressed("walk") else "run")
		if Input.is_action_pressed("walk"):
			_stop_dust_fx()
		else:
			_play_dust_fx()
	else:
		animated_sprite.play("idle")
		_stop_dust_fx()

func _update_air_animation() -> void:
	if double_jump_started:
		_play_if_needed("doublejump")
	elif velocity.y > 0:
		if not jump_started:
			_play_if_needed("fall")
	else:
		_play_if_needed("jump")

	_stop_dust_fx()

func _play_if_needed(animation: String) -> void:
	if animated_sprite.animation != animation:
		animated_sprite.play(animation)

func _play_dust_fx() -> void:
	dust_fx.visible = true
	if not dust_fx.is_playing():
		dust_fx.play("dustfx")

func _stop_dust_fx() -> void:
	if dust_fx.is_playing():
		dust_fx.stop()
	dust_fx.visible = false

func _handle_death() -> void:
	if randf() <= DEATH_SOUND_1_CHANCE:
		hurt_sound_1.play()
	else:
		hurt_sound_2.play()
	has_died = true	
	# Treat the respawn as a fresh landing so the first floor contact stays silent.
	is_first_landing = true
	animated_sprite.play("death")

func _on_death_sound_finished() -> void:
	if Gamestate.alive:
		has_died = false
