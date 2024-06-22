extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var tolerance: int = 15


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	look_at(get_global_mouse_position())
	if global_rotation_degrees <= -90 + tolerance or global_rotation_degrees + tolerance >= 90:
		if sprite.flip_v == true:
			tolerance *= -1
		sprite.flip_v = false
		position.x = abs(position.x) * -1
	else:
		if sprite.flip_v == false:
			tolerance *= -1
		sprite.flip_v = true
		position.x = abs(position.x)
