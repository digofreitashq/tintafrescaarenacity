extends Node

var BULLET_NORMAL = 0
var BULLET_TRIPLE = 1

var health = 10
var bullets = 10
var bullet_type = BULLET_NORMAL

func _ready():
	pass

func show_message(message):
	get_tree().get_current_scene().get_node("player/screen/dialog").show(message)
