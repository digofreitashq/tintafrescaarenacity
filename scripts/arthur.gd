extends KinematicBody2D

export var  ID = 0

const PLAYER_SCALE = 2
const FLOOR_NORMAL = Vector2(0, -1)
const SLOPE_SLIDE_STOP = 25.0
const MIN_ONAIR_TIME = 0.1
const WALK_SPEED = 100 # pixels/sec

var linear_vel = Vector2()
var target_speed = 0
var onair_time = 0
var on_floor = false

var times_talked = 0
var walk_pixels = 0
var initial_position_x = 0
var last_position_x = 0
var position_repeated = 0

var siding_left = false

onready var sprite = $sprite
onready var anim = $anim
onready var left_wall_raycast = $left_wall_raycast
onready var right_wall_raycast = $right_wall_raycast
onready var arthur_sm = $arthur_sm
onready var dialog = global.get_dialog()
onready var player = global.get_player()

signal walked

func _ready():
	if ID == 0:
		self.set_visible(false)
		$CollisionShape2D.set_disabled(true)
		return
		
	arthur_talks()

func _apply_gravity(delta):
	linear_vel.y += delta * global.GRAVITY

func _apply_movement(delta):
	linear_vel = move_and_slide(linear_vel, FLOOR_NORMAL, SLOPE_SLIDE_STOP)
	
	if is_on_floor():
		onair_time = 0

	on_floor = onair_time < MIN_ONAIR_TIME
	target_speed *= WALK_SPEED
	linear_vel.x = lerp(linear_vel.x, target_speed, 0.1)
	$sprite.scale = Vector2(-PLAYER_SCALE if siding_left else PLAYER_SCALE, 2.0)
	
	if abs(initial_position_x - $sprite.global_position.x) > abs(walk_pixels):
		walk_pixels = 0
		last_position_x = 0
		emit_signal("walked")
	elif last_position_x == $sprite.global_position.x:
		position_repeated += 1
		
		if position_repeated > 10:
			position_repeated = 0
			walk_pixels = 0
			last_position_x = 0
			emit_signal("walked")
	
	last_position_x = $sprite.global_position.x

func _handle_move_input():
	target_speed = 0
	
	if walk_pixels == 0:
		position_repeated = 0
		walk_pixels = 0
		last_position_x = 0
		
		if initial_position_x != $sprite.global_position.x:
			initial_position_x = $sprite.global_position.x
	
	if walk_pixels < 0:
		target_speed += -1
		
		if not siding_left:
			siding_left = true
		
	if walk_pixels > 0:
		target_speed += 1
		
		if siding_left:
			siding_left = false

func play_anim(anim_name):
	if siding_left:
		$sprite.scale.x = -PLAYER_SCALE
	else:
		$sprite.scale.x = PLAYER_SCALE
	
	anim.play(anim_name)

func wall_direction():
	var is_near_left = left_wall_raycast.is_colliding()
	var is_near_right = right_wall_raycast.is_colliding()
	
	return -int(is_near_left) + int(is_near_right)

func _on_Area2D_body_entered(body):
	if global.is_player(body):
		walk_pixels = 0
		
		siding_left = body.global_position.x < global_position.x
		
		var player = global.get_player()
		
		if body.global_position.x > global_position.x:
			player.siding_left = true
		else:
			player.siding_left = false
		
		if !player.on_floor:
			yield(player, "grounded")
		
		return

func call_body_entered():
	_on_Area2D_body_entered($sprite)

func arthur_talks():
	if ID == 1:
		global.set_player_control(false)
		player.player_sm.set_state(player.player_sm.states.idle)
		
		global.wait_until_signal(2)
		yield(global, "waited")
		
		dialog.show([
			["Ícaro","Eu já cheguei faz quinze minutos e nada daquele velho..."],
			])
		yield(dialog, "finished")
		
		walk_pixels = -1000
		yield(self, "walked")
		
		dialog.show([
			["Ícaro","E aí, velhote! Tá atrasado..."],
			["Arthur","Mais respeito, por favor, rapaz."],
			["Ícaro","Tá bom! Boa tarde..."],
			["Ícaro","Velhote!"],
			])
		yield(dialog, "finished")
		
		arthur_sm.set_state(arthur_sm.states.eating)
		
		global.wait_until_signal(1)
		yield(global, "waited")
		
		dialog.show([
			["Arthur","Hunf!"],
			["Arthur","Hoje seu treino será em campo."],
			["Arthur","Como deve ter percebido, a cidade está infestada desses tais Podres."],
			["Ícaro","Podres...?"],
			["Arthur","É o nome da gangue que está atacando a cidade. São bandidos mutantes."],
			["Ícaro","Eita. E eu vou ter que fazer o quê? Pintura facial neles...?"],
			["Arthur","Você vai usar seus poderes de transformar os desenhos em realidade para vencê-los."],
			["Ícaro","Então vamos lá..."],
			["Arthur","Ahm... Eu disse você! Sozinho."],
			["Arthur","Mas fique tranquilo que vou ficar olhando de longe."],
			["Arthur","E de vez em quando vou dar uns palpites."],
			["Ícaro","Ótimo... Se eu morrer, tudo bem, né?"],
			["Arthur","Eu... Confio em você!"],
			])
		yield(dialog, "finished")
		$Area2D/CollisionShape2D.scale.x = 0.5
		
		walk_pixels = 300
		yield(self, "walked")
		self.set_visible(false)
		$CollisionShape2D.set_disabled(true)
		
		dialog.show([
			["Ícaro","Vamos lá, né? Afinal, o que pode acontecer de ruim?"],
			])
		yield(dialog, "finished")
		
		times_talked += 1
		
		global.set_player_control(true)
