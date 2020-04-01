extends Node2D

func _ready():
	$anim.play("fill")

func _on_button_pressed():
	self.self_modulate = Color(1,1,1,1)

func _on_button_released():
	self.self_modulate = Color(1,1,1,0.5)
