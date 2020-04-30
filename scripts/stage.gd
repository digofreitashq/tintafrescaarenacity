extends Node

var rng = RandomNumberGenerator.new()

onready var sound_siren_police = preload("res://sfx/sound_siren_police.wav")
onready var sound_siren_ambulance = preload("res://sfx/sound_siren_ambulance.wav")
onready var sound_horn_1 = preload("res://sfx/sound_horn_1.wav")
onready var sound_horn_2 = preload("res://sfx/sound_horn_2.wav")
onready var sound_horn_3 = preload("res://sfx/sound_horn_3.wav")
onready var sound_horn_4 = preload("res://sfx/sound_horn_4.wav")

func _ready():
	$extra_collisions/TileMapCollision.visible = false
	$wall_jump_collisions/TileMapCollision.visible = false
	$timer_sfx.start()
	$music.pause_mode = true
	global.show_player_ui()
	global.get_player().can_reload = false

func random_sound():
	rng.randomize()
	var option = rng.randi_range(1,6)
	
	match option:
		1: $sfx.stream = sound_horn_1
		2: $sfx.stream = sound_horn_2
		3: $sfx.stream = sound_horn_3
		4: $sfx.stream = sound_horn_4
		5: $sfx.stream = sound_siren_police
		6: $sfx.stream = sound_siren_ambulance
	
	$sfx.play()
	$timer_sfx.wait_time = rng.randi_range(5,10)

func _on_sfx_finished():
	$timer_sfx.start()
