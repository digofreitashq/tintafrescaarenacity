extends Node

var BULLET_NORMAL = 0
var BULLET_TRIPLE = 1

var health = 10
var bullets = 0
var bullet_type = BULLET_NORMAL
var sprays = 0
var enemies = 0

func _ready():
	pass

func show_message(message):
	get_tree().get_current_scene().get_node("player/screen/dialog").show(message)
