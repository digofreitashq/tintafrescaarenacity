extends Node

const GRAVITY = 900

var BULLET_NORMAL = 0
var BULLET_TRIPLE = 1

var health = 1
var bullets = 0
var bullet_type = BULLET_NORMAL
var sprays = 0
var enemies = 0
var grafittis = 0
var allow_movement = true

var boxes = []

signal waited

func _ready():
	reset_stage()

func get_player():
	return get_tree().get_current_scene().get_node("player")

func get_stage():
	return get_tree().get_current_scene()

func get_dialog():
	return get_player().get_node("screen/dialog")

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
	return "TileMap" in body.get_name()

func is_walljump_collision(body):
	return "TileMapCollision" in body.get_name()

func is_push_collision(body):
	return "box" in body.get_name()

func show_player_ui(show=true):
	var player = get_player()
	if player != null: 
		var ui = player.get_node("screen/hud/ui")
		if ui != null: 
			ui.visible = show

func set_player_control(enable):
	if enable:
		allow_movement = true
	else:
		allow_movement = false
		var player = get_player()
		player.linear_vel =  Vector2(0,0)
		player.play_anim("idle")
		yield(player.anim, "animation_finished")

func do_timer_signal():
	print('DONE!')
	emit_signal("waited")

func wait_until_signal(seconds):
	var timer = get_tree().get_current_scene().get_node("stage_timer")
	timer.set_wait_time(seconds)
	timer.connect("timeout", self, "do_timer_signal")
	timer.start()

func show_grafitti(id):
	var grafitti = get_tree().get_current_scene().get_node("grafittis").get_node("TileMapGrafitti%s" % id)
	grafitti.visible = true

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
	bullets = 0
	bullet_type = BULLET_NORMAL
	sprays = 0
	enemies = 0
	grafittis = 0
	allow_movement = true
	
	boxes.clear()
	
	var player = get_player()
	
	if player:
		player.player_sm.set_state(player.player_sm.states.alive)

func reload_stage():
	reset_stage()
	get_tree().reload_current_scene()
