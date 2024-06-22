extends Node2D

@onready var slash_preview = $Marker/slash_preview
@onready var sprite = $sprite
@onready var death_timer = $Death_Timer

var dying: bool
# Called when the node enters the scene tree for the first time.
func _ready():
	hide_slash()
	dying = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dying:
		sprite.play("die")
	else:
		sprite.play("idle")

func _on_hitbox_body_entered(body):
	if body.is_in_group("player"):
		body.die()

func display_slash(target_position: Vector2):
	if dying:
		return
	slash_preview.visible = true
	slash_preview.look_at(target_position)

func hide_slash():
	slash_preview.visible = false

func die():
	hide_slash()
	death_timer.start()
	dying = true
func _on_death_timer_timeout():
	queue_free()
