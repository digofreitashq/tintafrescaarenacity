extends Node2D

func _ready():
	reset()

func reset():
	$anim.play("reset")

func rodou():
	$anim.play("rodou")
	yield($anim, "animation_finished")
