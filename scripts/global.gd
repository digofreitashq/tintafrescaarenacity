extends Node

var BULLET_NORMAL = 0
var BULLET_TRIPLE = 1

var health = 10
var bullets = 0
var bullet_type = BULLET_NORMAL
var sprays = 0
var enemies = 0
var allow_movement = true

signal waited

func _ready():
	pass

func get_player():
	return get_tree().get_current_scene().get_node("player")

func get_dialog():
	return get_player().get_node("screen/dialog")

func is_player(body):
	return "player" in body.get_name()

func is_sewer(body):
	return "sewer" in body.get_name()

func is_tilemap(body):
	return "TileMap" in body.get_name()

func is_walljump_collision(body):
	return "extra_collisions" in body.get_name() or "walljump_collisions" in body.get_name()

func enable_player_control():
	allow_movement = true

func disable_player_control():
	allow_movement = false
	var player = get_player()
	player.linear_vel =  Vector2(0,0)
	player.play_anim("idle")
	yield(player.anim, "animation_finished")

func do_timer_signal():
	print('DONE!')
	emit_signal("waited")

func wait_until_signal(seconds):
	var timer = get_tree().get_current_scene().get_node("stage_timer")
	timer.set_wait_time(seconds)
	timer.connect("timeout", self, "do_timer_signal")
	timer.start()
