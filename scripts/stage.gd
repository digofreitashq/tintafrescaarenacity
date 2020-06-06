extends Node

onready var player = $chars/player

onready var sound_siren_police = preload("res://sfx/sound_siren_police.wav")
onready var sound_siren_ambulance = preload("res://sfx/sound_siren_ambulance.wav")
onready var sound_horn_1 = preload("res://sfx/sound_horn_1.wav")
onready var sound_horn_2 = preload("res://sfx/sound_horn_2.wav")
onready var sound_horn_3 = preload("res://sfx/sound_horn_3.wav")
onready var sound_horn_4 = preload("res://sfx/sound_horn_4.wav")
onready var sound_water_dripping_1 = preload("res://sfx/sound_water_dripping_1.wav")
onready var sound_water_dripping_2 = preload("res://sfx/sound_water_dripping_2.wav")
onready var sound_water_dripping_3 = preload("res://sfx/sound_water_dripping_3.wav")
onready var sound_water_dripping_4 = preload("res://sfx/sound_water_dripping_4.wav")
onready var sound_water_dripping_5 = preload("res://sfx/sound_water_dripping_5.wav")
onready var sound_water_dripping_6 = preload("res://sfx/sound_water_dripping_6.wav")

var undergrounded = false

func _ready():
	reset()

func reset():
	undergrounded = false
	
	for node in $collisions.get_children(): node.set_visible(false)
	for node in $graffitis.get_children(): node.set_visible(false)
	
	$music.pause_mode = true
	global.get_player().can_reload = false

func random_sound():
	if not undergrounded:
		match global.random(1,6):
			1: $sfx.stream = sound_horn_1
			2: $sfx.stream = sound_horn_2
			3: $sfx.stream = sound_horn_3
			4: $sfx.stream = sound_horn_4
			5: $sfx.stream = sound_siren_police
			6: $sfx.stream = sound_siren_ambulance
		
		$timer_sfx.wait_time = global.random(5,10)
	else:
		match global.random(1,6):
			1: $sfx.stream = sound_water_dripping_1
			2: $sfx.stream = sound_water_dripping_2
			3: $sfx.stream = sound_water_dripping_3
			4: $sfx.stream = sound_water_dripping_4
			5: $sfx.stream = sound_water_dripping_5
			6: $sfx.stream = sound_water_dripping_6
		
		$timer_sfx.wait_time = global.random(1,3)
	
	$sfx.play()

func _on_sfx_finished():
	$timer_sfx.start()

func _on_area_parallax_1_body_entered(body):
	if not global.is_player(body): return
	undergrounded = $triggers/area_parallax_1.position.y < player.position.y
	$parallax_bg.show(!undergrounded)
	player.show_dark_light(undergrounded)
	
	var playback_position = $music.get_playback_position()
	
	if undergrounded:
		$music.stream = load("res://bgm/TintaFrescaStage1Underground.ogg")
		$bg.stop()
	else:
		$music.stream = load("res://bgm/TintaFrescaStage1.ogg")
		$bg.play()
	
	$music.play(playback_position)

func _on_area_close_gate_body_entered(body):
	if not global.is_player(body): return
	find_node("grid").open()

func _on_area_close_gate_body_exited(body):
	if not global.is_player(body): return
	find_node("grid").close()

func _on_area_dark_light_off_body_entered(body):
	if not global.is_player(body): return
	var hide = $triggers/area_dark_light_off.position.x < player.position.x
	player.shake_camera()
	player.show_dark_light(hide)
