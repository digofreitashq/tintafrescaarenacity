extends Node2D

var health = 0
var bullets = 0
var filled = false

onready var player = global.get_player()

func _ready():
	reset()

func reset():
	health = 0
	bullets = 0
	filled = false
	
	self.set_visible(true)
	
	$bullets.set_texture(global.imgs_bullets[0])
	$health.set_texture(global.imgs_health[0])

func start_fill():
	$timer_fill.start()

func fill():
	if health > global.health:
		if bullets > global.bullets:
			$timer_fill.stop()
			filled = true
		else:
			if bullets == 1:
				player.play_sound(global.sound_fill)
			
			$bullets.set_texture(global.imgs_bullets[bullets])
			$bullets.update()
			bullets += 1
	else:
		if health == 1:
			player.play_sound(global.sound_fill)
		
		$health.set_texture(global.imgs_health[health])
		$health.update()
		health += 1

func _on_button_pressed():
	self.self_modulate = Color(1,1,1,1)

func _on_button_released():
	self.self_modulate = Color(1,1,1,0.5)
