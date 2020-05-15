extends RigidBody2D

var on_floor = false
var can_play_sound = true
var follow_player = false

onready var box_sm = $box_sm
onready var anim = $anim
onready var player = global.get_player()
onready var distance_from_player = $CollisionShape2D.shape.extents.x + player.get_node("CollisionShape2D").shape.extents.x*2

func _ready():
	reset()

func reset():
	follow_player = false
	global.boxes.append(self)

func _physics_process(delta):
	rotation_degrees = 0
	
	if linear_velocity.y < 0: linear_velocity.y = 0
	
	if follow_player:
		linear_velocity.x = player.linear_vel.x
		var direction = (player.global_position - global_position)
		if abs(direction.x) > distance_from_player:
			if player.siding_left:
				global_position.x = player.global_position.x - distance_from_player
			else:
				global_position.x = player.global_position.x + distance_from_player

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

func _on_Area2D_bottom_body_exited(body):
	check_surface()
