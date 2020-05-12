extends Node2D

func _ready():
	reset()

func reset():
	self.set_visible(true)
	
	$anim.play("reset")

func rodou():
	$anim.play("rodou")
	yield($anim, "animation_finished")
