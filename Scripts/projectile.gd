extends Node2D

var speed: float
var dir: Vector2

@onready var sprite = $Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	position += dir * speed * delta

func shoot(initial_position: Vector2, direction: Vector2, velocity: float, lifetime: float):
	position = initial_position
	dir = direction
	speed = velocity
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.start()


func _on_timer_timeout():
	queue_free()

func _on_area_2d_body_entered(body):
	#if body.is_in_group("enemy"):
		#enemy.take_hit()
	queue_free()
