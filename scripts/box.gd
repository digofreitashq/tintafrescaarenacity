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
onready var player = global.get_player()

func _ready():
	global.boxes.append(self)

func _apply_gravity(delta):
	linear_vel.y += delta * global.GRAVITY

func _apply_movement(delta):
	var previous_direction = direction
	var desaccel = 0
	
	direction = 0
	
	for surface in [TOP, BOTTOM, LEFT, RIGHT]:
		check_surface(surface)
	
	if player.player_sm.is_on(player.player_sm.states.push): 
		if player.siding_left:
			for body in right_area_bodies:
				if global.is_player(body) and box_sm.is_on(box_sm.states.idle):
					if box_sm.is_on(box_sm.states.idle):
						direction = -1
					else:
						direction = -1.5
		elif !player.siding_left:
			for body in left_area_bodies:
				if global.is_player(body):
					if box_sm.is_on(box_sm.states.idle):
						direction = 1
					else:
						direction = 1.5
	
	if player.player_sm.is_on(player.player_sm.states.push) and direction == 0 and previous_direction != 0:
		direction = previous_direction
	
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
			if linear_vel.x > 0 and linear_vel.x < body.linear_vel.x: return
			elif linear_vel.x < 0 and linear_vel.x > body.linear_vel.x: return
			body.linear_vel.x = linear_vel.x
	
	if box_sm.is_on(box_sm.states.idle):
		desaccel = 0.5
	else:
		desaccel = 0.05
	
	linear_vel = move_and_slide(linear_vel, FLOOR_NORMAL, SLOPE_SLIDE_STOP)
	linear_vel.x = lerp(linear_vel.x, direction * WALK_SPEED, desaccel)
	on_floor = is_on_floor()
	
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
			
			if box_sm.is_on(box_sm.states.idle):
				if in_sewer:
					box_sm.set_state(box_sm.states.floating)
			elif box_sm.is_on(box_sm.states.floating):
				if !in_sewer:
					box_sm.set_state(box_sm.states.idle)

func _on_Area2D_top_body_entered(body):
	if global.is_box(body):
		global.set_all_zindex()
