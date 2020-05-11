extends Node

const GRAVITY = 900

var BULLET_NORMAL = 0
var BULLET_TRIPLE = 1

var health = 1
var bullets = 0
var bullet_type = BULLET_NORMAL
var sprays = 0
var enemies = 0
var graffitis = 0
var allow_movement = true

var imgs_health = {}
var imgs_bullets = {}

var boxes = []

onready var sound_fill = preload("res://sfx/sound_fill.wav")
onready var sound_damage = preload("res://sfx/sound_damage.wav")
onready var sound_jump = preload("res://sfx/sound_jump.wav")
onready var sound_walljump = preload("res://sfx/sound_walljump.wav")
onready var sound_wallslide = preload("res://sfx/sound_wallslide.wav")
onready var sound_grounded = preload("res://sfx/sound_grounded.wav")
onready var sound_shake = preload("res://sfx/sound_shake.wav")
onready var sound_spray1 = preload("res://sfx/sound_spray1.wav")
onready var sound_spray2 = preload("res://sfx/sound_spray2.wav")
onready var sound_graffiti = preload("res://sfx/sound_graffiti.wav")
onready var sound_success = preload("res://sfx/sound_success.wav")
onready var sound_dead = preload("res://sfx/sound_dead.wav")
onready var sound_letter = preload("res://sfx/sound_letter.wav")
onready var sound_next = preload("res://sfx/sound_next.wav")
onready var sound_push = preload("res://sfx/sound_push.wav")
onready var sound_splash = preload("res://sfx/sound_splash.wav")

signal waited

func _ready():
	for i in range(11):
		imgs_health[i] = load("res://sprites/hud_health_%02d.png"%(i))
		imgs_bullets[i] = load("res://sprites/hud_bullets_%02d.png"%(i))
	
	reset_stage()

func get_player():
	return get_tree().get_current_scene().get_node("chars/player")

func get_stage():
	return get_tree().get_current_scene()

func get_dialog():
	return get_tree().get_current_scene().get_node("screen/dialog")

func get_hud():
	return get_tree().get_current_scene().get_node("screen/hud")

func get_overall():
	return get_tree().get_current_scene().get_node("screen/overall")

func pause_bgm():
	get_tree().get_current_scene().get_node("music").stream_paused = true

func play_bgm():
	get_tree().get_current_scene().get_node("music").stream_paused = false

func is_player(body):
	return "player" in body.get_name()
	
func is_bullet(body):
	return "bullet" in body.get_name()

func is_sewer(body):
	return "sewer" in body.get_name()
	
func is_box(body):
	return "box" in body.get_name()

func is_tilemap(body):
	return "tilemap" in body.get_name()

func is_walljump_collision(body):
	return "tilemapcollision" in body.get_name()

func is_push_collision(body):
	return "box" in body.get_name()

func show_player_ui(show=true):
	var stage = get_stage()
	var ui = stage.get_node("screen/hud/ui")
	if ui != null: 
		ui.visible = show

func set_player_control(enable):
	if enable:
		allow_movement = true
		
		var hud = get_stage().get_node("screen/hud")
		var filled = hud.filled
		
		if not filled:
			hud.start_fill()
	else:
		allow_movement = false
		var player = get_player()
		player.linear_vel =  Vector2(0,0)
		player.play_anim("idle")
		yield(player.anim, "animation_finished")

func do_timer_signal():
	emit_signal("waited")

func wait_until_signal(seconds):
	var timer = get_tree().get_current_scene().get_node("stage_timer")
	timer.set_wait_time(seconds)
	timer.connect("timeout", self, "do_timer_signal")
	timer.start()

func show_graffiti(id):
	var graffiti = get_tree().get_current_scene().get_node("graffitis").get_node("tilemapgraffiti_%s" % id)
	graffiti.visible = true

func update_health(value):
	health += value
	
	if (health < 0):
		health = 0
	elif (health > 10):
		health = 10
	
	if (health >= 0):
		get_hud().get_node("health").set_texture(imgs_health[health])
	
	if health == 0:
		get_player().die()

func update_bullets(value):
	bullets += value
	
	if (bullets < 0):
		bullets = 0
	elif (bullets > 10):
		bullets = 10	
	
	if (bullets >= 0):
		get_hud().get_node("bullets").set_texture(imgs_bullets[bullets])

func update_bullet_type(type):
	bullet_type = type
	
	if (bullet_type == BULLET_NORMAL):
		get_hud().get_node("spray").texture = load("res://sprites/spray_1.png")
	elif (bullet_type == BULLET_TRIPLE):
		get_hud().get_node("spray").texture = load("res://sprites/spray_2.png")

func update_sprays(value):
	sprays += value
	
	if (sprays < 0):
		sprays = 0

func update_enemies(value):
	enemies += value
	
	if (enemies < 0):
		enemies = 0
	
	if (enemies >= 0):
		get_hud().get_node("label_enemies").set('text', "%0*d" % [3, enemies])

func update_graffiti(value):
	graffitis += value
	
	if (graffitis >= 0):
		get_hud().get_node("label_sprays").set('text', "%0*d" % [2, graffitis])

func sort_boxes_zindex(a, b):
	if a[2] != b[2]: return a[2] < b[2] # Y comparison
	elif a[1] != b[1]: return a[1] < b[1] # X comparison
	else: return a[0].get_instance_id() < b[0].get_instance_id()

func set_all_zindex():
	var info = []
	var index = 0
	
	if boxes.empty(): return
	
	for box in boxes:
		info.append([box, box.position.x, box.position.y])
	
	info.sort_custom(self, "sort_boxes_zindex")
	info.invert()
	
	for box in info:
		box[0].z_index = index
		index += 1
	
	get_player().z_index = index

func reset_stage():
	health = 10
	bullets = 10
	bullet_type = BULLET_NORMAL
	sprays = 0
	enemies = 0
	graffitis = 0
	allow_movement = true
	
	boxes.clear()
	
	var stage = get_stage()
	
	if stage and stage.get_name().begins_with("stage"):
		for node in stage.get_node("graffiti").get_children():
			node.set_visible(false)
		
		for node in stage.get_node("props").get_children():
			node.reset()
		
		for node in stage.get_node("enemies").get_children():
			node.reset()
		
		for node in stage.get_node("chars").get_children():
			node.reset()
		
		for node in stage.get_node("screen").get_children():
			node.reset()

func reload_stage():
	reset_stage()
	get_tree().reload_current_scene()
