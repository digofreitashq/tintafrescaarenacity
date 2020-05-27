extends ParallaxBackground

func _ready():
	show(true)

func show(value):
	if value:
		$anim.play("show")
	else:
		$anim.play("hide")
