extends CharacterBody2D

const SPEED = 80.0
const CROUCH_SPEED = 40.0
const JUMP_VELOCITY = -300.0
const MAX_JUMPS = 2
const COYOTE_TIME = 0.2

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
var in_air = false 
var has_died = false
var first_landing = true
var doublejump_started = false
var first_jump = false
var safe_landing = true
var is_crouched = false

# DEBUG VARIABLES. DELETE WHEN EXPORTING
var teleport_target = null
var teleport_speed = 200
var invincibility = false

func _on_ready() -> void:
	hurt_sound_1.connect("finished", Callable(self, "_on_death_sound_finished"))
	hurt_sound_2.connect("finished", Callable(self, "_on_death_sound_finished"))

	_set_active_skin(active_skin_index)

func _set_active_skin(index: int) -> void:
	for i in range(animated_sprites.size()):
		animated_sprites[i].visible = i == index # Only make the chosen sprite visible

func change_skin(index: int) -> void:
	if index >= 0 and index < animated_sprites.size():
		active_skin_index = index
		_set_active_skin(active_skin_index)

func _physics_process(delta: float) -> void:
	if Gamestate.is_paused:
		return # Block all player logic while paused
	
	# Death handling
	if not Gamestate.alive and not has_died:
		_handle_death()
		return

	if Gamestate.cannot_move:
		velocity = Vector2.ZERO
		return

	# Reset states when grounded else apply gravity
	if is_on_floor():
		_reset_ground_state()
	else:
		velocity += get_gravity() * delta
		coyote_timer -= delta
		in_air = true

	# Handle input and movement
	_handle_crouch()
	
	if not is_crouched:
		_handle_jump()
	
	_handle_horizontal_movement()
	_update_animation()
	
	_handle_debug()

	# Move and slide
	move_and_slide()

func _handle_debug():
	if Input.is_action_pressed("debug_mode") and not Gamestate.debug_mode:
		Gamestate.debug_mode = true
		print ("Debug Mode ON")
		Gamestate.start_game()
	if Gamestate.debug_mode:
		if Input.is_action_pressed("level_complete"):
			Gamestate.level_complete()
			print ("Cheat Activated: Level Complete!")
		if Input.is_action_pressed("click_debug"):
			teleport_target = get_global_mouse_position()
			velocity = position.direction_to(get_global_mouse_position()) * teleport_speed
		#if Input.is_action_just_pressed("invincibility") and not Gamestate.is_invincible:
			#Gamestate.is_invincible = true
			#print ("Invincibility = ON")
		#else:
			#Gamestate.is_invincible = false
			#print ("Invincibility = OFF")

func _handle_crouch():
	if Input.is_action_pressed("crouch"):
		if not is_crouched:
			is_crouched = true
			animated_sprite.play("crouch")
			_stop_dust_fx()
	else:
		if is_crouched:
			is_crouched = false
			animated_sprite.play("idle")
			
		# If not crouched, make dust visible again when running
		if velocity.x != 0 and not dust_fx.is_playing():
			dust_fx.visible = true
			dust_fx.play("dustfx")

func _handle_jump():
	if Input.is_action_just_pressed("jump"):
		if jumps_remaining == MAX_JUMPS and (is_on_floor() or coyote_timer > 0): # First Jump
			_perform_jump("jump")
			coyote_timer = 0 # Disable further coyote jumps
			jump_sound.play()
		elif jumps_remaining == 1: # Double jump
			_perform_jump("doublejump", true)
			jump_sound_2.play()
		elif jumps_remaining == MAX_JUMPS and in_air and coyote_timer <= 0:
			_perform_jump("jump")
			jumps_remaining -= 1
			jump_sound.play()

func _perform_jump(animation: String, is_double_jump: bool = false):
	velocity.y = JUMP_VELOCITY
	animated_sprite.play(animation)
	jumps_remaining -= 1
	first_jump = true
	if is_double_jump:
		doublejump_started = true

func _reset_ground_state():
	if has_died: # Prevent reset if in death state
		return

	if jumps_remaining != MAX_JUMPS:
		jumps_remaining = MAX_JUMPS
		doublejump_started = false
	coyote_timer = COYOTE_TIME
	
	# Play landing sound randomly
	if in_air and not first_landing:
		var roll = randf()
		if roll <= 0.8:
			grunt_sound.play()
		else:
			grunt_sound_2.play()
		
	# Reset flags
	in_air = false
	first_landing = false
	first_jump = false

func _handle_horizontal_movement():
	var direction := Input.get_axis("move_left", "move_right")
	var is_walking := Input.is_action_pressed("walk")
	var current_speed = SPEED * (1.0 if is_walking else 1.5)
	
	# Crouch speed when grounded
	if is_on_floor() and is_crouched:
		current_speed = CROUCH_SPEED
		
		# Stop movement if no floor is detected ahead
		if not edge_ray.is_colliding():
			if (direction > 0 and edge_ray.target_position.x > 0) or (direction < 0 and edge_ray.target_position.x < 0):
				direction = 0
	
	# Update horizontal velocity
	velocity.x = direction * current_speed if direction != 0  else move_toward(
		velocity.x,
		0,
		current_speed,
		)
		
	# Flip the Sprite and DustFX based on direction
	if direction > 0:
		animated_sprite.flip_h = false
		dust_fx.flip_h = false
		dust_fx.position.x = -abs(dust_fx.position.x)
		edge_ray.target_position = Vector2(8,2) # Forward-right and down
	elif direction < 0:
		animated_sprite.flip_h = true
		dust_fx.flip_h = true
		dust_fx.position.x = abs(dust_fx.position.x)
		edge_ray.target_position = Vector2(-8,2) # Forward-right and down
		
func _update_animation():
	if is_on_floor():
		if is_crouched:
			animated_sprite.play("crouch")
			# Stop the dust FX when crouched
			_stop_dust_fx()
			
		# Grounded animations
		elif velocity.x != 0:
			var is_running := not Input.is_action_pressed("walk") and velocity.x != 0
			
			# Play walk or run animation
			animated_sprite.play("walk" if Input.is_action_pressed("walk") else "run")
			
			# Only show dust while running
			if is_running and not dust_fx.is_playing():
				dust_fx.visible = true
				dust_fx.play("dustfx")
			elif not is_running:
				_stop_dust_fx()
			
		else:
			animated_sprite.play("idle")
			# Stop dust when idle
			_stop_dust_fx()

	elif doublejump_started:
		# Ensure double jump anim is maintained
		if animated_sprite.animation != "doublejump":
			animated_sprite.play("doublejump")
		# Stop dust when doublejump
		_stop_dust_fx()
			
	elif velocity.y > 0:
		# Falling animation
		if animated_sprite.animation != "fall" and not first_jump:
			animated_sprite.play("fall")
		# Stop dust when falling
		_stop_dust_fx()
		
	else:
		# Regular jump animation
		if animated_sprite.animation != "jump":
			animated_sprite.play("jump")
		# Stop dust while jumping
		_stop_dust_fx()

func _stop_dust_fx():
	if dust_fx.is_playing():
		dust_fx.stop()
	dust_fx.visible = false

func _handle_death():
	var roll = randf()
	if roll <= 0.8:
		hurt_sound_1.play()
	else:
		hurt_sound_2.play()
	has_died = true	
	first_landing = true
	animated_sprite.play("death")

func _on_death_sound_finished():
	if Gamestate.alive:
		has_died = false
