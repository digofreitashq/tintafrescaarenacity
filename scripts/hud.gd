extends Node2D

var health = 0
var bullets = 0
var filled = false

onready var parent = get_parent().get_parent()

func _ready():
	$spray.set_texture(parent.sprite_spray_1)
	$health.set_texture(parent.imgs_health[0])
	$bullets.set_texture(parent.imgs_bullets[0])
	
func start_fill():
	$timer_fill.start()

func fill():
	if health > global.health:
		if bullets > global.bullets:
			$timer_fill.stop()
			filled = true
		else:
			if bullets == 1:
				parent.play_sound(parent.sound_fill)
			
			$bullets.set_texture(parent.imgs_bullets[bullets])
			$bullets.update()
			bullets += 1
	else:
		if health == 1:
			parent.play_sound(parent.sound_fill)
		
		$health.set_texture(parent.imgs_health[health])
		$health.update()
		health += 1

func _on_button_pressed():
	self.self_modulate = Color(1,1,1,1)

func _on_button_released():
	self.self_modulate = Color(1,1,1,0.5)
