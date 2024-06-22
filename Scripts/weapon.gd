extends Node2D

const PROJECTILE_SPEED: float = 800
const PROJECTILE_LIFETIME: float = 10

@onready var projectile_scene: PackedScene = preload("res://Scenes/projectile.tscn")
@onready var shoot_point = $Anchor/shoot_point

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func shoot(shoot_vector: Vector2):
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.shoot(shoot_point.global_position, shoot_vector, PROJECTILE_SPEED, PROJECTILE_LIFETIME)

