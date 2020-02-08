extends KinematicBody2D

const PLAYER_SCALE = 2
const NO_GRAVITY = 0
const FLOOR_NORMAL = Vector2(0, -2)
const SLOPE_SLIDE_STOP = 25.0
const WALK_SPEED = 100 # pixels/sec

var linear_vel = Vector2()
var direction = 0
var on_floor = false

var on_top = []
var on_bottom = []
var on_left = []
var on_right = []

onready var box_sm = $box_sm
onready var anim = $anim

signal walked

func _apply_gravity(delta):
	if is_on_floor(): return
	
	if box_sm.state == box_sm.states.over_box:
		linear_vel.y = 0
	else:
		linear_vel.y += delta * global.GRAVITY

func _apply_movement(delta):
	if !on_left.size() and !on_right.size():
		linear_vel.x = 0
	else:
		for body in on_left+on_right:
			if global.is_player(body) and body.on_floor:
				direction = 1 if body.global_position.x < global_position.x else -1
				global.get_player().set_pushing()
		
	var original_linear_vel = linear_vel
	
	linear_vel = move_and_slide(linear_vel, FLOOR_NORMAL, SLOPE_SLIDE_STOP)
	linear_vel.x = lerp(linear_vel.x, direction * WALK_SPEED, 0.1)
	
	if direction == -1:
		for body in on_left:
			if global.is_box(body):
				body.linear_vel.x = linear_vel.x
	elif direction == 1:
		for body in on_right:
			if global.is_box(body):
				body.linear_vel.x = linear_vel.x
	
	#for body in on_top:
	#	body.linear_vel.x = linear_vel.x

func check_surface():
	var in_sewer = false
	var body = null
	
	on_top = []
	on_bottom = []
	on_left = []
	on_right = []
	
	for body in $Area2D_left.get_overlapping_bodies():
		if body == self: continue
		if global.is_box(body) or global.is_player(body):
			on_left.append(body)
	
	for body in $Area2D_right.get_overlapping_bodies():
		if body == self: continue
		if global.is_box(body) or global.is_player(body):
			on_right.append(body)
	
	for body in $Area2D_top.get_overlapping_bodies():
		if body == self: continue
		if global.is_box(body):
			on_top.append(body)
			
	for body in $Area2D_bottom.get_overlapping_bodies():
		if body == self: continue
		if global.is_player(body) and body.on_floor:
			linear_vel.y = -WALK_SPEED
		if global.is_sewer(body):
			in_sewer = true
		if global.is_box(body):
			on_bottom.append(body)
	
	if in_sewer and box_sm.state != box_sm.states.floating:
		box_sm.set_state(box_sm.states.floating)
	elif box_sm.state != box_sm.states.floating:
		if on_bottom.size():
			if box_sm.state == box_sm.states.idle:
				box_sm.set_state(box_sm.states.over_box)
		elif box_sm.state == box_sm.states.over_box:
			box_sm.set_state(box_sm.states.idle)

func _on_Area2D_bottom_body_entered(body):
	check_surface()

func _on_Area2D_bottom_body_exited(body):
	check_surface()

func _on_Area2D_top_body_entered(body):
	check_surface()

func _on_Area2D_top_body_exited(body):
	check_surface()

func _on_Area2D_left_body_entered(body):
	check_surface()

func _on_Area2D_left_body_exited(body):
	check_surface()

func _on_Area2D_right_body_entered(body):
	check_surface()

func _on_Area2D_right_body_exited(body):
	check_surface()
