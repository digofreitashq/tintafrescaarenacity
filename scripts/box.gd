extends KinematicBody2D

const PLAYER_SCALE = 2
const FLOOR_NORMAL = Vector2(0, -2)
const SLOPE_SLIDE_STOP = 25.0
const WALK_SPEED = 150 # pixels/sec

const TOP = 0
const BOTTOM = 1
const LEFT = 2
const RIGHT = 3

var linear_vel = Vector2()
var direction = 0
var on_floor = false

var top_area_bodies = []
var bottom_area_bodies = []
var left_area_bodies = []
var right_area_bodies = []

onready var box_sm = $box_sm
onready var anim = $anim
onready var timer = $timer
onready var state_label = $state_label
onready var player = global.get_player()

signal walked

func _apply_gravity(delta):
	linear_vel.y += delta * global.GRAVITY

func _apply_movement(delta):
	var previous_direction = direction
	
	direction = 0
	
	for body in left_area_bodies:
		if global.is_box(body): body.check_surface(LEFT)
		
		if !player.player_sm.is_on(player.player_sm.states.push): 
			break
		elif global.is_player(body) and box_sm.is_on(box_sm.states.idle):
			direction = 1
		elif global.is_box(body) and !right_area_bodies.has(player) and body.linear_vel.x > 0:
			direction = 0.5
	
	for body in right_area_bodies:
		if global.is_box(body): body.check_surface(RIGHT)
		
		if !player.player_sm.is_on(player.player_sm.states.push): 
			break
		elif global.is_player(body) and box_sm.is_on(box_sm.states.idle):
			direction = -1
		elif global.is_box(body) and !left_area_bodies.has(player) and body.linear_vel.x < 0:
			direction = -0.5
	
	if previous_direction != 0 and direction == 0 and player.player_sm.is_on(player.player_sm.states.push):
		direction = previous_direction
	
	var original_linear_vel = linear_vel
	
	if linear_vel.x != 0:
		if linear_vel.x < 0:
			for body in left_area_bodies:
				if global.is_box(body):
					body.linear_vel.x = linear_vel.x
		elif linear_vel.x > 0:
			for body in right_area_bodies:
				if global.is_box(body):
					body.linear_vel.x = linear_vel.x
		
		for body in top_area_bodies:
			body.check_surface(TOP)
			body.linear_vel.x = linear_vel.x
	
	linear_vel = move_and_slide(linear_vel, FLOOR_NORMAL, SLOPE_SLIDE_STOP)
	linear_vel.x = lerp(linear_vel.x, direction * WALK_SPEED, 0.5)
	on_floor = is_on_floor()
	box_sm.update_label()
	
func check_surface(area):
	var in_sewer = false
	var body = null
	
	match area:
		LEFT:
			left_area_bodies.clear()
			for body in $Area2D_left.get_overlapping_bodies():
				if body == self: continue
				if global.is_box(body) or global.is_player(body):
					left_area_bodies.append(body)
		RIGHT:
			right_area_bodies.clear()
			for body in $Area2D_right.get_overlapping_bodies():
				if body == self: continue
				if global.is_box(body) or global.is_player(body):
					right_area_bodies.append(body)
		TOP:
			top_area_bodies.clear()
			for body in $Area2D_top.get_overlapping_bodies():
				if body == self: continue
				if global.is_box(body):
					top_area_bodies.append(body)
		BOTTOM:
			bottom_area_bodies.clear()
			for body in $Area2D_bottom.get_overlapping_bodies():
				if body == self: continue
				if global.is_player(body):
					linear_vel.y = -WALK_SPEED
				if global.is_sewer(body):
					in_sewer = true
				if global.is_box(body):
					bottom_area_bodies.append(body)
	
	if !box_sm.is_on(box_sm.states.floating):
		if in_sewer:
			box_sm.set_state(box_sm.states.floating)
		elif bottom_area_bodies.size() == 0:
			box_sm.set_state(box_sm.states.idle)
	
func _on_Area2D_bottom_body_entered(body):
	check_surface(BOTTOM)

func _on_Area2D_bottom_body_exited(body):
	$bottom_area_timer.start()

func _on_Area2D_top_body_entered(body):
	check_surface(TOP)

func _on_Area2D_top_body_exited(body):
	top_area_bodies.erase(body)

func _on_Area2D_left_body_entered(body):
	check_surface(LEFT)

func _on_Area2D_left_body_exited(body):
	$left_area_timer.start()

func _on_Area2D_right_body_entered(body):
	check_surface(RIGHT)

func _on_Area2D_right_body_exited(body):
	$right_area_timer.start()

func _on_left_area_timer_timeout():
	check_surface(LEFT)

func _on_right_area_timer_timeout():
	check_surface(RIGHT)

func _on_bottom_area_timer_timeout():
	check_surface(BOTTOM)
