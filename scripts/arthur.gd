extends KinematicBody2D

const PLAYER_SCALE = 2
const GRAVITY = 900
const FLOOR_NORMAL = Vector2(0, -2)
const SLOPE_SLIDE_STOP = 25.0
const MIN_ONAIR_TIME = 0.1
const WALK_SPEED = 250 # pixels/sec

var linear_vel = Vector2()
var target_speed = 0
var onair_time = 0
var on_floor = false
var the_body = null

var siding_left = false

onready var sprite = $sprite
onready var anim = $anim
onready var left_wall_raycast = $left_wall_raycast
onready var right_wall_raycast = $right_wall_raycast
onready var arthur_sm = $arthur_sm

func _apply_gravity(delta):
	linear_vel.y += delta * GRAVITY

func _apply_movement(delta):
	linear_vel = move_and_slide(linear_vel, FLOOR_NORMAL, SLOPE_SLIDE_STOP)
	
	if is_on_floor():
		onair_time = 0

	on_floor = onair_time < MIN_ONAIR_TIME
	target_speed *= WALK_SPEED
	linear_vel.x = lerp(linear_vel.x, target_speed, 0.1)

func _handle_move_input():
	target_speed = 0
	
	if 1==0:
		target_speed += -1
		
		if not siding_left:
			siding_left = true
			play_anim(anim.current_animation)
		
	if 1==0:
		target_speed += 1
		
		if siding_left:
			siding_left = false
			play_anim(anim.current_animation)

func play_anim(anim_name):
	if siding_left:
		$sprite.scale.x = -PLAYER_SCALE
	else:
		$sprite.scale.x = PLAYER_SCALE
	
	anim.play(anim_name)

func wall_direction():
	var is_near_left = left_wall_raycast.is_colliding()
	var is_near_right = right_wall_raycast.is_colliding()
	
	return -int(is_near_left) + int(is_near_right)

func _on_anim_animation_finished(anim_name):
	pass

func _on_anim_animation_started(anim_name):
	pass

func _on_Area2D_body_entered(body):
	the_body = body
	
	if "player" in body.get_name():
		siding_left = body.global_position.x < global_position.x
		play_anim("eating")
		
		var player = get_tree().get_current_scene().get_node("player")
		
		if body.global_position.x > global_position.x:
			player.siding_left = true
			player.anim.play("idle_left")
		else:
			player.siding_left = false
			player.anim.play("idle_right")
		
		if !get_tree().get_current_scene().get_node("player").on_floor:
			var t = $timer
			t.connect("timeout", self, "call_body_entered")
			t.set_wait_time(0.5)
			t.set_one_shot(true)
			t.start()
		else:
			arthur_talks_1(body)

func call_body_entered():
	_on_Area2D_body_entered(the_body)

func arthur_talks_1(body):
	global.disable_player_control()
	var dialog = get_tree().get_current_scene().get_node("player").get_node("screen").get_node("dialog")
	dialog.show([
		["Ícaro","E aí, velhote!"],
		["Arthur","Mais respeito aí, moleque."],
		["Ícaro","Boa tarde..."],
		["Ícaro","Velhote!"],
		["Arthur","Hunf! Como deve ter percebido, a cidade está infestada de Podres."],
		["Ícaro","Podres...?"],
		["Arthur","É o nome da gangue que está atacando a cidade. São bandidos mutantes."],
		["Ícaro","Eita. E eu vou ter que impedí-los?"],
		["Arthur","Mais respeito aí, moleque."],
		])
	yield(dialog, "finished")
	
	global.enable_player_control()

func arthur_moves():
	linear_vel.x = 10000


func _physics_process(delta):
    move_and_collide(linear_vel * delta)