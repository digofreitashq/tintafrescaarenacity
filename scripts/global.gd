extends Node

const GRAVITY = 900

const SIDE_LEFT = -1
const SIDE_RIGHT = 1
const SIDE = {true: SIDE_LEFT, false: SIDE_RIGHT}

var health = 10
var sprays = 0
var bullets = 0
var enemies = 0
var graffitis = 0
var allow_movement = true

var imgs_health = {}
var imgs_bullets = {}

var boxes = []
var trampolines = []

onready var sound_fill = preload("res://sfx/sound_fill.wav")
onready var sound_damage = preload("res://sfx/sound_damage.wav")
onready var sound_enemy = preload("res://sfx/sound_enemy.wav")
onready var sound_hit = preload("res://sfx/sound_hit.wav")
onready var sound_jump = preload("res://sfx/sound_jump.wav")
onready var sound_walljump = preload("res://sfx/sound_walljump.wav")
onready var sound_wallslide = preload("res://sfx/sound_wallslide.wav")
onready var sound_grounded = preload("res://sfx/sound_grounded.wav")
onready var sound_shake = preload("res://sfx/sound_shake.wav")
onready var sound_spray1 = preload("res://sfx/sound_spray1.wav")
onready var sound_spray2 = preload("res://sfx/sound_spray2.wav")
onready var sound_spray3 = preload("res://sfx/sound_spray3.wav")
onready var sound_graffiti = preload("res://sfx/sound_graffiti.wav")
onready var sound_success = preload("res://sfx/sound_success.wav")
onready var sound_dead = preload("res://sfx/sound_dead.wav")
onready var sound_beep = preload("res://sfx/sound_beep.wav")
onready var sound_coin = preload("res://sfx/sound_coin.wav")
onready var sound_letter = preload("res://sfx/sound_letter.wav")
onready var sound_next = preload("res://sfx/sound_next.wav")
onready var sound_push = preload("res://sfx/sound_push.wav")
onready var sound_splash = preload("res://sfx/sound_splash.wav")
onready var sound_charge = preload("res://sfx/sound_charge.wav")
onready var sound_charged = preload("res://sfx/sound_charged.wav")
onready var sound_flashing = preload("res://sfx/sound_flashing.wav")

onready var spray_normal = preload("res://scenes/spray_normal.tscn")

signal waited

func _ready():
	VisualServer.set_default_clear_color(Color("#3e2137"))
	
	for i in range(11):
		imgs_health[i] = load("res://sprites/hud_health_%02d.png"%(i))
		imgs_bullets[i] = load("res://sprites/hud_bullets_%02d.png"%(i))
	
	reset_stage()

func get_player():
	return get_tree().get_current_scene().get_node("chars/player")

func get_stage():
	return get_tree().get_current_scene()

func get_dialog():
	return get_tree().get_current_scene().find_node("dialog")

func get_hud():
	return get_tree().get_current_scene().find_node("hud")

func get_ui():
	var hud = get_hud()
	if hud: return hud.find_node("ui")
	return null

func get_overall():
	return get_tree().get_current_scene().find_node("overall")

func pause_bgm():
	get_tree().get_current_scene().get_node("music").stream_paused = true

func play_bgm():
	get_tree().get_current_scene().get_node("music").stream_paused = false

func is_player(body):
	return "player" in body.get_name()

func is_enemy(body):
	if body is KinematicBody2D:
		return "enemies" in body.get_parent().get_name()
	
func is_bullet(body):
	return "bullet" in body.get_name()

func is_sewer(body):
	return "sewer" in body.get_name()
	
func is_box(body):
	return "box" in body.get_name()

func is_tilemap(body):	
	return "tilemap" in body.get_name()

func is_walljump_collision(body):
	return body is TileMap and "tilemapcollision" in body.get_name()

func is_push_collision(body):
	return not is_player(body) and body.is_in_group("bodies")

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
		player.linear_velocity =  Vector2(0,0)
		player.play_anim("idle")
		yield(player.anim, "animation_finished")

func do_timer_signal():
	emit_signal("waited")

func wait_until_signal(seconds):
	var timer = get_tree().get_current_scene().get_node("stage_timer")
	timer.set_wait_time(seconds)
	
	if not timer.is_connected("timeout", self, "do_timer_signal"):
		timer.connect("timeout", self, "do_timer_signal")
	
	timer.start()

func show_graffiti(id):
	var graffiti = get_tree().get_current_scene().find_node("tilemapgraffiti_%s" % id)
	graffiti.set_visible(true)

func show_player_ui(show = true):
	var ui = get_ui()
	if ui: ui.set_visible(show)

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

func update_sprays(value):
	if bullets == 0 and value > 0:
		update_bullets(10)
		value -= 1
	
	sprays += value
	
	if (sprays < 0):
		sprays = 0
	
	get_hud().get_node("label_sprays").set('text', "%0*d" % [3, sprays])

func update_bullets(value):
	if value < 0:
		if (bullets + sprays * 10) + value < 0:
			return false
		
		if bullets + value > 0:
			bullets += value
		elif bullets + value <= 0:
			var result = -value / 10
			var mod = -value % 10
			
			if mod == 0:
				result -= 1
				mod = 10
			
			if bullets - mod <= 0:
				result += 1
				bullets = bullets + 10 - mod
			else:
				bullets -= mod
			
			update_sprays(-result)
	else:
		bullets += value
	
	if (bullets > 10):
		bullets = 10
	elif (bullets <= 0):
		bullets = 0
	
	get_hud().get_node("bullets").set_texture(imgs_bullets[bullets])
	return true

func update_enemies(value):
	enemies += value
	
	if (enemies < 0):
		enemies = 0

func update_graffiti(value):
	graffitis += value

func drop_item(body, obj_class=load("res://scenes/spray_normal.tscn"), offset=Vector2(0,0)):
	var obj = obj_class.instance()
	obj._ready()
	
	obj.position = body.position + offset
	
	get_stage().get_node("props/suplies").add_child(obj)

func drop_random_item(body, resistance, offset=Vector2(0,0)):
	if (resistance - random(1, resistance)) != 0:
		return
	
	var obj_class = null
	
	if health < 5:
		obj_class = load("res://scenes/health_sandwich.tscn")
	else:
		obj_class = load("res://scenes/spray_normal.tscn")
	
	var obj = obj_class.instance()
	obj._ready()
	
	obj.position = body.position + offset
	
	get_stage().get_node("props/suplies").add_child(obj)

func random(start, end):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(start,end)

func sort_zindex(a, b):
	if a[2] != b[2]: return a[2] < b[2] # Y comparison
	elif a[1] != b[1]: return a[1] < b[1] # X comparison
	else: return a[0].get_instance_id() < b[0].get_instance_id()

func set_all_zindex():
	var info = []
	var index = 0
	
	if boxes.empty(): return
	if trampolines.empty(): return
	
	for bodies in [trampolines, boxes]:
		for body in bodies:
			info.append([body, body.global_position.x, body.global_position.y])
	
	info.sort_custom(self, "sort_zindex")
	info.invert()
	
	for body in info:
		body[0].z_index = index
		index += 1
	
	get_player().z_index = index

func shake_camera():
	get_player().shake_camera()

func reset_stage():
	health = 10
	bullets = 0
	sprays = 0
	enemies = 0
	graffitis = 0
	allow_movement = true
	
	boxes.clear()
	trampolines.clear()
	
	var stage = get_stage()
	
	if stage and stage.get_name().begins_with("stage"):
		for node in stage.get_node("graffitis").get_children():
			node.set_visible(false)
		
		for nodes in stage.get_node("props").get_children():
			for node in nodes.get_children():
				if "reset" in node: node.reset()
		
		for node in stage.get_node("enemies").get_children():
			if "reset" in node: node.reset()
		
		for node in stage.get_node("chars").get_children():
			if "reset" in node: node.reset()
		
		for node in stage.get_node("screen").get_children():
			if "reset" in node: node.reset()

func reload_stage():
	reset_stage()
	get_tree().reload_current_scene()
	global.allow_movement = true
