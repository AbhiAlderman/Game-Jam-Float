extends Node2D

@onready var sprite: AnimatedSprite2D = $Sprite2D

const ACTIVE_TIME: float = 0.04
var tolerance: int = 15
var active_timer: float

# Called when the node enters the scene tree for the first time.
func _ready():
	active_timer = -20


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if active_timer >= 0.0:
		sprite.play("slash")
	else:
		sprite.play("invisible")

func _physics_process(delta):
	if active_timer > 0.0:
		active_timer -= delta

func appear():
	look_at(get_global_mouse_position())
	if global_rotation_degrees <= -90 or global_rotation_degrees >= 90:
		if sprite.flip_v == true:
			tolerance *= -1
		sprite.flip_v = false
		position.x = abs(position.x) * -1
	else:
		if sprite.flip_v == false:
			tolerance *= -1
		sprite.flip_v = true
		position.x = abs(position.x)
	active_timer = ACTIVE_TIME

