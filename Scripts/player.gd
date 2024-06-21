extends CharacterBody2D

#constants
#movement
const MOVE_SPEED = 400.0
#jumping
const JUMP_VELOCITY = -400.0
const RISE_GRAVITY = 1600
const FALL_GRAVITY = 2200
const FLOAT_GRAVITY = 200
const JUMP_HOLD_GRAVITY = 300
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.15
const JUMP_HOLD_TIME = 0.2
const DASH_BUFFER_TIME = 0.15
const DASH_SPEED = 800.0
const CAMERA_ZOOM = Vector2(1.3, 1.3)

#variables
var coyote_time_left: float = 0.0
var jump_buffer_time_left: float = 0.0
var jump_time: float = 0.0
var direction_x: float = 0.0 #axis between left and right
var direction_y: float = 0.0 #axis between up and down
var player_state: states
var ignore_inputs: bool
var can_dash: bool
var dash_buffer_time_left: float = 0.0
#player state
enum states {
	GROUNDED,
	AIRBORNE,
	FLOATING,
	DASHING,
	DEAD,
}

@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera
@onready var dash_length_timer = $Timers/Dash_Length_Timer
@onready var dash_cooldown_timer = $Timers/Dash_Cooldown_Timer

func _ready():
	player_state = states.GROUNDED
	coyote_time_left = COYOTE_TIME
	jump_buffer_time_left = JUMP_BUFFER_TIME
	camera.zoom = CAMERA_ZOOM
	ignore_inputs = false
	can_dash = true
	
func _process(_delta):
	animate()

func _physics_process(delta):
	if player_state == states.DEAD:
		handle_death()
		pass
	handle_gravity(delta)
	if not ignore_inputs:
		handle_input_buffer(delta)
		handle_jump()
		handle_dash()
	handle_movement()
	move_and_slide()

func get_gravity():
	if player_state == states.FLOATING:
		return FLOAT_GRAVITY
	elif velocity.y > 0:
		return RISE_GRAVITY
	return FALL_GRAVITY

func handle_gravity(delta):
	if not is_on_floor():
		coyote_time_left -= delta
		if player_state == states.FLOATING:
			velocity.y = get_gravity()
		elif player_state == states.DASHING:
			pass #don't apply gravity while dashing
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
		can_dash = true
		coyote_time_left = COYOTE_TIME
		jump_time = 0.0
		#can dash/other abilities = true

func handle_input_buffer(delta):
	jump_buffer_time_left -= delta
	dash_buffer_time_left -= delta
	if Input.is_action_just_pressed("jump"):
		jump_buffer_time_left = JUMP_BUFFER_TIME
	if Input.is_action_just_pressed("dash"):
		dash_buffer_time_left = DASH_BUFFER_TIME
	
func handle_jump():
	if jump_buffer_time_left > 0:
		if is_on_floor() or coyote_time_left > 0:
			velocity.y = JUMP_VELOCITY
			player_state = states.AIRBORNE
			jump_buffer_time_left = 0	
	elif Input.is_action_pressed("jump") and not is_on_floor() and velocity.y >= 0:
		player_state = states.FLOATING
	elif Input.is_action_just_released("jump") and player_state == states.FLOATING:
		player_state = states.AIRBORNE

func handle_dash():
	if can_dash and dash_buffer_time_left > 0:
		direction_x = Input.get_axis("left", "right")
		direction_y = Input.get_axis("up", "down")
		ignore_inputs = true
		dash_length_timer.start()
		player_state = states.DASHING
		can_dash = false
		velocity.x = direction_x * DASH_SPEED
		velocity.y = direction_y * DASH_SPEED	

func handle_movement():
	if player_state == states.DASHING:
		return #don't change velocity while dashing
	direction_x = Input.get_axis("left", "right")
	direction_y = Input.get_axis("up", "down")
	if direction_x != 0 and not ignore_inputs:
		velocity.x = direction_x * MOVE_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, MOVE_SPEED)
		#if dashing, dont change movement
		

func handle_flip():
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func handle_death():
	queue_free()

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
		states.DASHING:
			sprite.play("dash")
		states.DEAD:
			sprite.play("dead")


func _on_dash_length_timer_timeout():
	ignore_inputs = false
	if is_on_floor():
		player_state = states.GROUNDED
	else:
		player_state = states.AIRBORNE
	dash_cooldown_timer.start()


func _on_dash_cooldown_timer_timeout():
	can_dash = true
