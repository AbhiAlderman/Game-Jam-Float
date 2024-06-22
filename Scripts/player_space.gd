extends CharacterBody2D


#constants
#movement
const WALK_SPEED: float = 400.0
const AIR_SPEED: float = 350.0
const FLOAT_LAUNCH_SPEED: float = 500.0
const FLOAT_MIN_SPEED: float = 200.0
const HORIZONTAL_STOP_THRESHOLD = 50.0
const VERTICAL_STOP_THRESHOLD = 50
const FALL_GRAVITY: float = 2200.0
const JUMP_VELOCITY: float = -120.0
const RECOIL_VELOCITY: float = 600.0
const COYOTE_TIME: float = 0.1 
const FLOAT_DECELERATION: float = 10

const CAMERA_ZOOM = Vector2(1.6, 1.6)

#variables
var coyote_time_left: float = 0.0 
var direction_x: float = 0.0 #axis between left and right
var direction_y: float = 0.0 #axis between up and down
var can_attack: bool
var pressed_attack: bool 
var pressed_jump: bool
var dying: bool
var aim_vector: Vector2
var player_state: states 

enum states {
	GROUNDED,
	AIRBORNE,
	FLOATING,
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
	pressed_attack = false
	pressed_jump = false
	camera.zoom = CAMERA_ZOOM
	can_attack = true
	dying = false

func _process(_delta):
	handle_flip()
	animate()

func _physics_process(delta):
	handle_gravity(delta)
	handle_inputs()
	handle_jump()
	handle_movement()
	aim_vector = (get_global_mouse_position() - global_position).normalized()
	handle_attack()
	move_and_slide()

func handle_gravity(delta):
	if not is_on_floor():
		coyote_time_left -= delta
		if player_state == states.FLOATING:
			if abs(velocity.y) < VERTICAL_STOP_THRESHOLD:
				velocity.y = move_toward(velocity.y, 0, FLOAT_DECELERATION)
			elif velocity.y > 0:
				velocity.y = move_toward(velocity.y, FLOAT_MIN_SPEED, FLOAT_DECELERATION)
			elif velocity.y < 0:
				velocity.y = move_toward(velocity.y, -FLOAT_MIN_SPEED, FLOAT_DECELERATION)
		elif player_state == states.AIRBORNE or player_state == states.GROUNDED:
			player_state = states.AIRBORNE
			velocity.y += FALL_GRAVITY * delta
	else:
		player_state = states.GROUNDED
		coyote_time_left = COYOTE_TIME

func handle_inputs():
	if Input.is_action_just_pressed("jump"):
		pressed_jump = true
	if Input.is_action_just_pressed("attack"):	
		pressed_attack = true

func handle_jump():
	if pressed_jump:
		if player_state == states.GROUNDED or coyote_time_left > 0.0:
			player_state = states.FLOATING
			velocity.y = JUMP_VELOCITY
		elif player_state == states.AIRBORNE:
			#turn gravity off
			player_state = states.FLOATING
		elif player_state == states.FLOATING:
			#turn gravity on
			player_state = states.AIRBORNE
		pressed_jump = false

func handle_movement():
	direction_x = Input.get_axis("left", "right")
	direction_y = Input.get_axis("up", "down")
	if player_state == states.GROUNDED:
		refresh_attack()
		if direction_x != 0.0:
			velocity.x = WALK_SPEED * direction_x
		else:
			velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
	elif player_state == states.AIRBORNE:
		if abs(direction_x) > 0.0:
			velocity.x =  AIR_SPEED * direction_x
		else:
			velocity.x = move_toward(velocity.x, 0, AIR_SPEED)
	elif player_state == states.FLOATING:
		if abs(velocity.x) < HORIZONTAL_STOP_THRESHOLD:
			velocity.x = move_toward(velocity.x, 0, FLOAT_DECELERATION)
		elif velocity.x > FLOAT_MIN_SPEED:
			velocity.x = move_toward(velocity.x, FLOAT_MIN_SPEED, FLOAT_DECELERATION)
		elif velocity.x < FLOAT_MIN_SPEED:
			velocity.x = move_toward(velocity.x, -FLOAT_MIN_SPEED, FLOAT_DECELERATION)
		else:
			velocity.x = move_toward(velocity.x, 0, FLOAT_DECELERATION)
	
func handle_attack():
	if can_attack and pressed_attack:
		weapon.shoot(aim_vector)
		can_attack = false
		pressed_attack = false
		attack_cooldown_timer.start()
		rocket_jump()

func rocket_jump():
	velocity.x = -aim_vector.x * RECOIL_VELOCITY
	velocity.y = -aim_vector.y * RECOIL_VELOCITY
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

func handle_flip():
	if aim_vector.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

func animate():
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
	pass

func _on_kill_collision_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	if body is TileMap:
		die()
