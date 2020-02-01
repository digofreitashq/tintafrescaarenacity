extends Node

var BULLET_NORMAL = 0
var BULLET_TRIPLE = 1

var health = 10
var bullets = 0
var bullet_type = BULLET_NORMAL
var sprays = 0
var enemies = 0
var allow_movement = true

func _ready():
	pass

func enable_player_control():
	allow_movement = true

func disable_player_control():
	allow_movement = false
	get_tree().get_current_scene().get_node("player").linear_vel =  Vector2(0,0)
	get_tree().get_current_scene().get_node("player").play_anim("idle")
