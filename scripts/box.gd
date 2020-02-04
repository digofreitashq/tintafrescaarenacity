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
var floating = false

onready var box_sm = $box_sm

signal walked

func _apply_gravity(delta):
	if is_on_floor(): return
	linear_vel.y += delta * GRAVITY

func _apply_movement(delta):
	linear_vel = move_and_slide(linear_vel, FLOOR_NORMAL)
	linear_vel.x = lerp(linear_vel.x, direction * WALK_SPEED, 0.1)

func check_surface():
	var in_sewer = false
	
	for abody in $Area2D_bottom.get_overlapping_bodies():
		if global.is_sewer(abody):
			in_sewer = true
			break
	
	if in_sewer and not floating:
		floating = true
		$anim.play("floating")
	
	if not in_sewer and floating:
		floating = false
		$anim.play("idle")

func _on_Area2D_body_entered(body):
	if global.is_player(body):
		direction = 1 if body.global_position.x < global_position.x else -1
		global.get_player().set_pushing()
	
	check_surface()

func _on_Area2D_body_exited(body):
	direction = 0
	
	check_surface()

func _on_Area2D_bottom_body_entered(body):
	#if global.is_player(body):
	#	direction = -0.5 if body.global_position.x < global_position.x else 0.5
	
	check_surface()

func _on_Area2D_bottom_body_exited(body):
	check_surface()
