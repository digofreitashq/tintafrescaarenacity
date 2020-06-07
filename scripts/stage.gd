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

onready var dialog = global.get_dialog()

var undergrounded = false
var arthur_falou = 0
var first_enemy_seen = false

func _ready():
	for body in $enemies.get_children():
		body.connect("seen", self, "enemy_seen_signal", [body])
	
	reset()

func reset():
	undergrounded = false
	
	for node in $collisions.get_children(): node.set_visible(false)
	for node in $graffitis.get_children(): node.set_visible(false)
	
	$music.pause_mode = true
	global.get_player().can_reload = false

func enemy_seen_signal(body):
	if arthur_falou == 1 and not first_enemy_seen:
		first_enemy_seen = true
		
		body.direction = global.SIDE_LEFT if body.global_position.x > player.global_position.x else global.SIDE_RIGHT
		body.set_direction()
		
		global.set_player_control(false)
		dialog.display([
			["Ícaro","Mas você é muito feio!"],
			["Mutante","Pagou quanto pra ver minha beleza?"],
			])
		yield(dialog, "finished")
		global.set_player_control(true)

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
	if global.is_enemy(body):
		body.linear_velocity = Vector2(-body.JUMP_SPEED, -body.JUMP_SPEED)

func _on_area_parallax_1_body_exited(body):
	if not global.is_player(body): return
	undergrounded = $triggers/area_parallax_1/CollisionShape2D.global_position.y < player.global_position.y
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

func _on_area_dark_light_off_body_exited(body):
	if not global.is_player(body): return
	var hide = $triggers/area_dark_light_off/CollisionShape2D.global_position.x < player.global_position.x
	yield(player, "grounded")
	
	
	player.show_dark_light(hide)
	
	find_node("grid2").close()
	yield(find_node("grid2"), "finished")
	find_node("grid1").close()
	yield(find_node("grid1"), "finished")
