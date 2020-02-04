extends RigidBody2D

func _ready():
	$anim.play("loop")

func _on_Area2D_body_entered(body):
	if global.is_player(body):
		global.get_player().got_damage(-1,true)

func _on_Area2D_body_exited(body):
	if global.is_player(body):
		global.get_player().got_damage(-1,true)
