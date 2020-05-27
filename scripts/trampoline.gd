extends RigidBody2D

const MAX_BOUNCE_FORCE = 600

var on_floor = false
var can_play_sound = true
var follow_player = false
var is_bouncing = false

onready var anim = $anim
onready var player = global.get_player()
onready var distance_from_player = $CollisionShape2D.shape.extents.x + player.get_node("CollisionShape2D").shape.extents.x*2

func _ready():
	reset()

func reset():
	global.boxes.append(self)
	add_to_group("bodies")
	anim.play("idle")
	is_bouncing = false
	follow_player = false

func _physics_process(_delta):
	rotation_degrees = 0
	
	if follow_player:
		linear_velocity.x = player.linear_velocity.x
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
	
	if in_sewer:
		#derreter com fumaça e sumir
		queue_free()

func play_sound(stream, force=false):
	if not force and not can_play_sound: return
	
	can_play_sound = false
	$sound.stream = stream
	$sound.play()

func _on_sound_finished():
	can_play_sound = true

func _on_Area2D_top_body_entered(body):
	if body != self and body.is_in_group("bodies"):
		var body_linear_velocity
		
		if body.linear_velocity.y < 100:
			body_linear_velocity = Vector2(0,100)
		else:
			body_linear_velocity = body.linear_velocity
		
		$sound.play(0)
		anim.play("bounce_start")
		
		if global.is_player(body):
			body.linear_velocity = Vector2(-body_linear_velocity.x,max(-body_linear_velocity.y*2, -MAX_BOUNCE_FORCE))
			body.jump_released = false
		else:
			body.apply_central_impulse(Vector2(-body_linear_velocity.x,max(-body_linear_velocity.y*10, -MAX_BOUNCE_FORCE)))
		
		yield(anim, "animation_finished")
		anim.play("bounce_end")
		

func _on_Area2D_bottom_body_entered(_body):
	check_surface()

func _on_Area2D_bottom_body_exited(_body):
	check_surface()
