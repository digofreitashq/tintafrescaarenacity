extends KinematicBody2D

const PLAYER_SCALE = 2
const GRAVITY = 900
const NO_GRAVITY = 0
const FLOOR_NORMAL = Vector2(0, -2)
const SLOPE_SLIDE_STOP = 25.0
const WALK_SPEED = 400 # pixels/sec

var linear_vel = Vector2()
var direction = 0
var on_floor = false

var siding_left = false
var top_boxes = []
var bottom_boxes = []
var aside_boxes = []

onready var box_sm = $box_sm
onready var anim = $anim

signal walked

func _apply_gravity(delta):
	if is_on_floor(): return
	
	if box_sm.state == box_sm.states.over_box:
		linear_vel.y = 0
	else:
		print('aa')
		linear_vel.y += delta * GRAVITY

func _apply_movement(delta):
	linear_vel = move_and_slide(linear_vel, FLOOR_NORMAL)
	linear_vel.x = lerp(linear_vel.x, direction * WALK_SPEED, 0.1)
	
	check_surface()
	
	for abody in aside_boxes:
		abody.linear_vel.x = linear_vel.x
	
	for abody in top_boxes:
		abody.linear_vel.x = linear_vel.x

func check_surface():
	var in_sewer = false
	top_boxes = []
	bottom_boxes = []
	aside_boxes = []
	
	for abody in $Area2D_top.get_overlapping_bodies():
		if abody == self: continue
		
		if global.is_box(abody):
			top_boxes.append(abody)
	
	for abody in $Area2D_bottom.get_overlapping_bodies():
		if abody == self: continue
		
		if global.is_sewer(abody):
			in_sewer = true
		if global.is_box(abody):
			bottom_boxes.append(abody)
	
	for abody in $Area2D.get_overlapping_bodies():
		if abody == self: continue
		
		if global.is_box(abody):
			aside_boxes.append(abody)
	
	if in_sewer and box_sm.state != box_sm.states.floating:
		box_sm.set_state(box_sm.states.floating)
	
	if not in_sewer:
		if bottom_boxes.size():
			box_sm.set_state(box_sm.states.over_box)
		else:
			box_sm.set_state(box_sm.states.idle)
	
func _on_Area2D_body_entered(body):
	check_surface()
	
	if global.is_player(body):
		direction = 1 if body.global_position.x < global_position.x else -1
		global.get_player().set_pushing()

func _on_Area2D_body_exited(body):
	check_surface()
	direction = 0

func _on_Area2D_bottom_body_entered(body):
	check_surface()

func _on_Area2D_bottom_body_exited(body):
	check_surface()

func _on_Area2D_top_body_entered(body):
	check_surface()

func _on_Area2D_top_body_exited(body):
	check_surface()
