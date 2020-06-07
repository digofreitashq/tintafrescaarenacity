extends KinematicBody2D

export var ID = 0

const SPRITE_SCALE = 2
const FLOOR_NORMAL = Vector2(0, -1)
const SLOPE_SLIDE_STOP = 25.0
const MIN_ONAIR_TIME = 0.1
const WALK_SPEED = 100 # pixels/sec

var linear_velocity = Vector2()
var target_speed = 0
var onair_time = 0
var on_floor = false

var times_talked = 0
var walk_pixels = 0
var initial_position_x = 0
var last_position_x = 0
var position_repeated = 0

var siding_left = false

onready var sprite = $sprite
onready var anim = $anim
onready var left_wall_raycast = $left_wall_raycast
onready var right_wall_raycast = $right_wall_raycast
onready var porco_sm = $porco_sm
onready var dialog = global.get_dialog()
onready var player = global.get_player()

signal walked

func _ready():
	reset()

func reset():
	pass

func _apply_gravity(delta):
	linear_velocity.y += delta * global.GRAVITY

func _apply_movement(_delta):
	linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL, SLOPE_SLIDE_STOP)
	
	if is_on_floor():
		onair_time = 0

	on_floor = onair_time < MIN_ONAIR_TIME
	target_speed *= WALK_SPEED
	linear_velocity.x = lerp(linear_velocity.x, target_speed, 0.1)
	$sprite.scale = Vector2(global.SIDE[siding_left] * SPRITE_SCALE, SPRITE_SCALE)
	
	if abs(initial_position_x - global_position.x) > abs(walk_pixels):
		walk_pixels = 0
		last_position_x = 0
		emit_signal("walked")
	elif last_position_x == global_position.x:
		position_repeated += 1
		
		if position_repeated > 10:
			position_repeated = 0
			walk_pixels = 0
			last_position_x = 0
			emit_signal("walked")
	
	last_position_x = global_position.x

func _handle_move_input():
	target_speed = 0
	
	if walk_pixels == 0:
		position_repeated = 0
		walk_pixels = 0
		last_position_x = 0
		
		if initial_position_x != global_position.x:
			initial_position_x = global_position.x
	
	if walk_pixels < 0:
		target_speed += -1
		
		if not siding_left:
			siding_left = true
		
	if walk_pixels > 0:
		target_speed += 1
		
		if siding_left:
			siding_left = false

func play_anim(anim_name):
	$sprite.scale.x = global.SIDE[siding_left] * SPRITE_SCALE
	
	anim.play(anim_name)

func wall_direction():
	var is_near_left = left_wall_raycast.is_colliding()
	var is_near_right = right_wall_raycast.is_colliding()
	
	return -int(is_near_left) + int(is_near_right)
