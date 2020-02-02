extends KinematicBody2D

const PLAYER_SCALE = 2
const GRAVITY = 900
const FLOOR_NORMAL = Vector2(0, -2)
const SLOPE_SLIDE_STOP = 25.0
const WALK_SPEED = 250 # pixels/sec

var linear_vel = Vector2()
var direction = 0
var on_floor = false

var siding_left = false

onready var box_sm = $box_sm

signal walked

func _apply_gravity(delta):
	if is_on_floor(): return
	linear_vel.y += delta * GRAVITY

func _apply_movement(delta):
	linear_vel = move_and_slide(linear_vel, FLOOR_NORMAL)
	linear_vel.x = lerp(linear_vel.x, direction * WALK_SPEED, 0.1)

func _on_Area2D_body_entered(body):
	if "player" in body.get_name():
		direction = 1 if body.global_position.x < global_position.x else -1
		#walk_pixels = 50

func _on_Area2D_body_exited(body):
	direction = 0


func _on_Area2D_bottom_body_entered(body):
	if "player" in body.get_name():
		direction = 0.5 if body.global_position.x < global_position.x else -0.5
