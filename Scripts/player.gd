extends CharacterBody2D

#constants
#movement
const GROUND_MOVE_SPEED = 400.0
const AIR_MOVE_SPEED = 300.0
const MAX_SPEED = 800.0
const GROUND_DECELERATION: float = 100
const AIR_DECELERATION: float = 30
const FLOAT_DECELERATION: float = 20
#jumping
const JUMP_VELOCITY = -300.0
const RISE_GRAVITY = 1600
const FALL_GRAVITY = 2200
const FLOAT_GRAVITY = 40
const JUMP_HOLD_GRAVITY = 600
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.15
const JUMP_HOLD_TIME = 0.2
const ROCKET_JUMP_X_VELOCITY = 550.0
const ROCKET_JUMP_Y_VELOCITY = 600.0
const ROCKET_JUMP_GRAVITY = 700

const CAMERA_ZOOM = Vector2(2.3, 2.3)
const ATTACK_BUFFER_TIME = 0.1
#variables
var coyote_time_left: float = 0.0
var jump_buffer_time_left: float = 0.0
var jump_time: float = 0.0
var direction_x: float = 0.0 #axis between left and right
var direction_y: float = 0.0 #axis between up and down
var player_state: states
var can_attack: bool
var attack_buffer_time_left: float = 0.0
var dying: bool
#player state
enum states {
	GROUNDED,
	AIRBORNE,
	FLOATING,
	ROCKET_JUMPING,
	DEAD,
}

@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera
@onready var death_timer = $Timers/Death_Timer
@onready var weapon = $weapon
@onready var attack_cooldown_timer = $Timers/Attack_Cooldown_timer
@onready var rocket_jump_timer = $Timers/Rocket_Jump_Timer

func _ready():
	player_state = states.GROUNDED
	coyote_time_left = COYOTE_TIME
	jump_buffer_time_left = JUMP_BUFFER_TIME
	camera.zoom = CAMERA_ZOOM
	can_attack = true
	dying = false
	
func _process(_delta):
	animate()

func _physics_process(delta):
	if dying:
		player_state = states.DEAD
	else:
		handle_gravity(delta)
		handle_input_buffer(delta)
		handle_jump()
		handle_movement()
		handle_attack()
		move_and_slide()

func get_gravity():
	if player_state == states.ROCKET_JUMPING:
		return ROCKET_JUMP_GRAVITY
	elif player_state == states.FLOATING:
		return FLOAT_GRAVITY
	elif velocity.y > 0:
		return RISE_GRAVITY
	return FALL_GRAVITY

func handle_gravity(delta):
	if not is_on_floor():
		coyote_time_left -= delta
		if player_state == states.ROCKET_JUMPING:
			velocity.y += get_gravity() * delta
		elif player_state == states.FLOATING:
			velocity.y = get_gravity()
		else:
			player_state = states.AIRBORNE
			if Input.is_action_pressed("jump") and jump_time < JUMP_HOLD_TIME and velocity.y < 0:
				jump_time += delta
				velocity.y += JUMP_HOLD_GRAVITY * delta
				player_state = states.AIRBORNE
			else:
				velocity.y += get_gravity() * delta
	else:
		player_state = states.GROUNDED
		coyote_time_left = COYOTE_TIME
		jump_time = 0.0
		#can dash/other abilities = true

func handle_input_buffer(delta):
	jump_buffer_time_left -= delta
	attack_buffer_time_left -= delta
	if Input.is_action_just_pressed("jump"):
		jump_buffer_time_left = JUMP_BUFFER_TIME
	if Input.is_action_just_pressed("attack"):
		attack_buffer_time_left = ATTACK_BUFFER_TIME
	
func handle_jump():
	if player_state == states.ROCKET_JUMPING:
		return
	if jump_buffer_time_left > 0:
		if is_on_floor() or coyote_time_left > 0:
			velocity.y = JUMP_VELOCITY
			refresh_attack()
			player_state = states.AIRBORNE
			jump_buffer_time_left = 0	
	elif Input.is_action_pressed("jump") and not is_on_floor() and velocity.y >= 0:
		player_state = states.FLOATING
	elif Input.is_action_just_released("jump") and player_state == states.FLOATING:
		player_state = states.AIRBORNE

func handle_movement():
	if player_state == states.ROCKET_JUMPING:
		return
	direction_x = Input.get_axis("left", "right")
	direction_y = Input.get_axis("up", "down")
	if is_on_floor():
		if direction_x != 0:
			velocity.x = direction_x * GROUND_MOVE_SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, GROUND_DECELERATION)
	else:
		if direction_x != 0:
			velocity.x = direction_x * AIR_MOVE_SPEED
		else:
			if player_state == states.FLOATING:
				velocity.x = move_toward(velocity.x, 0, FLOAT_DECELERATION)
			else:
				velocity.x = move_toward(velocity.x, 0, AIR_DECELERATION)
		

func handle_flip():
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func handle_attack():
	if can_attack and attack_buffer_time_left > 0:
		can_attack = false
		var shoot_vector: Vector2 = get_global_mouse_position() - global_position
		shoot_vector = shoot_vector.normalized()
		weapon.shoot(shoot_vector)
		attack_cooldown_timer.start()
		rocket_jump(shoot_vector)

func rocket_jump(shoot_vector: Vector2):
	jump_time = 0.0
	player_state = states.ROCKET_JUMPING
	velocity.x = -shoot_vector.x * ROCKET_JUMP_X_VELOCITY
	velocity.y = -shoot_vector.y * ROCKET_JUMP_Y_VELOCITY
	print(str(velocity.x) + " | " + str(velocity.y))
	rocket_jump_timer.start()

func refresh_attack():
	can_attack = true
	
func die():
	dying = true
	if player_state != states.DEAD:
		player_state = states.DEAD
		death_timer.start()
	else:
		pass
	
func handle_death():
	get_tree().reload_current_scene()

func animate():
	handle_flip()
	match player_state:
		states.GROUNDED:
			if velocity.x == 0:
				sprite.play("idle")
			else:
				sprite.play("run")
		states.AIRBORNE:
			if velocity.y < 0:
				sprite.play("jump_up")
			elif velocity.y > 0:
				sprite.play("jump_down")
			else:
				sprite.play("jump_peak")
		states.FLOATING:
			sprite.play("float")
		states.DEAD:
			sprite.play("dead")

func _on_death_timer_timeout():
	handle_death()


func _on_attack_cooldown_timer_timeout():
	if is_on_floor():
		refresh_attack()


func _on_rocket_jump_timer_timeout():
	if is_on_floor():
		player_state = states.GROUNDED
	else:
		player_state = states.AIRBORNE


func _on_kill_collision_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	if body is TileMap:
		die()
