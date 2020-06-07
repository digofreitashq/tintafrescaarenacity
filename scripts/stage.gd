extends Node

const ARTHUR_1_ID = 1
const ARTHUR_2_ID = 2
const PORCO_ID = 3

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
var cut_scene = 0
var first_enemy_seen = false
var porco_dead_enemies = 0

func _ready():
	for body in $enemies.get_children():
		body.connect("seen", self, "enemy_seen_signal", [body])
		body.connect("dead", self, "enemy_dead_signal", [body])
	
	reset()

func reset():
	undergrounded = false
	cut_scene = 0
	first_enemy_seen = false
	porco_dead_enemies = 0
	
	for node in $collisions.get_children(): node.set_visible(false)
	for node in $graffitis.get_children(): node.set_visible(false)
	
	$music.pause_mode = true
	global.get_player().can_reload = false
	
	$collisions/porco_collision.collision_mask = 1
	$collisions/porco_collision.collision_layer = 1
	$chars/porco.siding_left = true
	$chars/porco.porco_sm.ignore_transition = true

func enemy_seen_signal(body):
	if not body: return
	
	if cut_scene == ARTHUR_1_ID and not first_enemy_seen:
		first_enemy_seen = true
		
		if not player.on_floor:
			yield(player, "grounded")
		
		body.direction = global.SIDE_LEFT if body.global_position.x > player.global_position.x else global.SIDE_RIGHT
		body.set_direction()
		
		global.set_player_control(false)
		dialog.display([
			["Ícaro","Mas você é muito feio!"],
			["Mutante","Pagou quanto pra ver minha beleza?"],
			])
		yield(dialog, "finished")
		global.set_player_control(true)

func enemy_dead_signal(body):
	if cut_scene == PORCO_ID:
		porco_dead_enemies += 1
	
	if porco_dead_enemies == 3:
		if not player.on_floor:
			yield(player, "grounded")
		
		global.set_player_control(false)
		
		find_node("grid1").open()
		yield(find_node("grid1"), "finished")
		find_node("grid2").open()
		yield(find_node("grid2"), "finished")
		
		player.play_anim("start_scratch")
		
		dialog.display([
			["Ícaro","Ufa! Achei que tinha chegado a minha hora... ~~\nO Arthur vai me pagar por essa!"],
			])
		yield(dialog, "finished")
		
		global.finished = true
		get_tree().change_scene("res://scenes/disclaimer.tscn")
		
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
	if cut_scene == PORCO_ID: return
	
	if not global.is_player(body): return
	
	var hide = $triggers/area_dark_light_off/CollisionShape2D.global_position.x < player.global_position.x
	
	if not hide: return
	
	var porco = $chars/porco
	
	$music.stop()
	$timer_sfx.stop()
	$bg.stop()
	
	if not player.on_floor:
		yield(player, "grounded")
	
	global.set_player_control(false)
	
	player.show_dark_light(!hide)
	
	find_node("grid2").close()
	yield(find_node("grid2"), "finished")
	
	player.siding_left = false
	player.play_anim("start_scratch")
	
	dialog.display([
		["Ícaro","É... Agora eu me ferrei."],
		])
	yield(dialog, "finished")
	
	$music.volume_db = 0
	$music.stream = load("res://bgm/TintaFrescaStage1Battle.ogg")
	$music.play()
	
	porco.porco_sm.set_state(porco.porco_sm.states.laugh)
	
	dialog.display([
		["Porco","Mas olha só o peixe que caiu na minha rede! ~~\nRapazes, divirtam-se!"],
		])
	yield(dialog, "finished")
	global.set_player_control(true)
	
	player.play_anim("idle")
	
	porco.siding_left = false
	porco.porco_sm.set_state(porco.porco_sm.states.run)
	global.wait_until_signal(2)
	$chars/porco/anim_porco.play("escape")
	yield($chars/porco/anim_porco, "animation_finished")
	
	global.wait_until_signal(2)
	
	find_node("grid1").close()
	yield(find_node("grid1"), "finished")
	
	var enemies = [$enemies/rato3,$enemies/rinoceronte3,$enemies/crocodilo3]
	
	for enemy in enemies:
		enemy.chasing = true
		enemy.direction = global.SIDE_LEFT
		enemy.initial_resistance *= 4
		enemy.current_speed = enemy.WALK_SPEED * 2
	
	dialog.display([
		["Rinoceronte","Peguem ele!"],
		])
	yield(dialog, "finished")
	
	for enemy in enemies:
		enemy.paused = false
	
	$collisions/porco_collision.collision_mask = 0
	$collisions/porco_collision.collision_layer = 0
	
	global.set_player_control(true)
	
	cut_scene = PORCO_ID
