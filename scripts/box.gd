extends RigidBody2D

const FLOAT_SPEED = 50
const MAX_DISTANCE_FROM_PLAYER = 64

var on_floor = false
var can_play_sound = true
var follow_player = false
var float_direction = 0
var last_position_x = 0
var position_repeated = 0

onready var box_sm = $box_sm
onready var anim = $anim
onready var player = global.get_player()

func _ready():
	reset()

func reset():
	anim.play("idle")
	follow_player = false
	global.boxes.append(self)
	add_to_group("bodies")

func _physics_process(_delta):
	rotation_degrees = 0
	angular_velocity = 0
	
	if box_sm.is_on(box_sm.states.idle):
		float_direction = -1 if linear_velocity.x < 0 else 1
	
		if follow_player:
			linear_velocity.x = player.linear_velocity.x
			var direction = (player.global_position - global_position)
			if abs(direction.x) > MAX_DISTANCE_FROM_PLAYER:
				if player.siding_left:
					global_position.x = player.global_position.x - MAX_DISTANCE_FROM_PLAYER
				else:
					global_position.x = player.global_position.x + MAX_DISTANCE_FROM_PLAYER
	
	elif box_sm.is_on(box_sm.states.floating):
		linear_velocity.x = FLOAT_SPEED * float_direction

func check_surface():
	var in_sewer = false
	
	for body in $Area2D_bottom.get_overlapping_bodies():
		if body == self: continue
		if global.is_sewer(body):
			in_sewer = true
	
	if box_sm.is_on(box_sm.states.idle):
		if in_sewer:
			box_sm.set_state(box_sm.states.floating)
			play_sound(global.sound_splash)
			
	elif box_sm.is_on(box_sm.states.floating):
		if not in_sewer:
			box_sm.set_state(box_sm.states.idle)

func play_sound(stream, force=false):
	if not force and not can_play_sound: return
	
	can_play_sound = false
	$sound.stream = stream
	$sound.play()

func _on_sound_finished():
	can_play_sound = true

func _on_Area2D_top_body_entered(body):
	if global.is_box(body):
		global.set_all_zindex()

func _on_Area2D_bottom_body_entered(body):
	check_surface()
	
	if global.is_player(body):
		bounce = 1

func _on_Area2D_bottom_body_exited(body):
	check_surface()
	
	if global.is_player(body):
		bounce = 0

func _on_Area2D_left_body_entered(body):
	if box_sm.is_on(box_sm.states.floating):
		float_direction *= -1 

func _on_Area2D_right_body_entered(body):
	if box_sm.is_on(box_sm.states.floating):
		float_direction *= -1 
