extends KinematicBody2D

export var ID = 0

const SPRITE_SCALE = 2
const FLOOR_NORMAL = Vector2(0, -1)
const SLOPE_SLIDE_STOP = 25.0
const MIN_ONAIR_TIME = 0.1
const WALK_SPEED = 100 # pixels/sec

var linear_velocity = Vector2()
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
signal contact_player

func _ready():
	reset()

func reset():
	if ID == 0:
		self.set_visible(false)
		$CollisionShape2D.set_disabled(true)
		global.set_player_control(true)
		return
		
	arthur_talks()

func _apply_gravity(delta):
	linear_velocity.y += delta * global.GRAVITY

func _apply_movement(_delta):
	linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL, SLOPE_SLIDE_STOP)
	
	if is_on_floor():
		onair_time = 0

	on_floor = onair_time < MIN_ONAIR_TIME
	target_speed *= WALK_SPEED
	linear_velocity.x = lerp(linear_velocity.x, target_speed, 0.1)
	$sprite.scale = Vector2(global.SIDE[siding_left] * SPRITE_SCALE, SPRITE_SCALE)
	
	if abs(initial_position_x - global_position.x) > abs(walk_pixels):
		walk_pixels = 0
		last_position_x = 0
		emit_signal("walked")
	elif last_position_x == global_position.x:
		position_repeated += 1
		
		if position_repeated > 10:
			position_repeated = 0
			walk_pixels = 0
			last_position_x = 0
			emit_signal("walked")
	
	last_position_x = global_position.x

func _handle_move_input():
	target_speed = 0
	
	if walk_pixels == 0:
		position_repeated = 0
		walk_pixels = 0
		last_position_x = 0
		
		if initial_position_x != global_position.x:
			initial_position_x = global_position.x
	
	if walk_pixels < 0:
		target_speed += -1
		
		if not siding_left:
			siding_left = true
		
	if walk_pixels > 0:
		target_speed += 1
		
		if siding_left:
			siding_left = false

func play_anim(anim_name):
	$sprite.scale.x = global.SIDE[siding_left] * SPRITE_SCALE
	
	anim.play(anim_name)

func wall_direction():
	var is_near_left = left_wall_raycast.is_colliding()
	var is_near_right = right_wall_raycast.is_colliding()
	
	return -int(is_near_left) + int(is_near_right)

func _on_Area2D_body_entered(body):
	if global.is_player(body):
		walk_pixels = 0
		
		siding_left = body.global_position.x < global_position.x
		
		emit_signal("contact_player")
		
		if ID == 2:
			arthur_talks()

func call_body_entered():
	_on_Area2D_body_entered($sprite)

func arthur_talks():
	if ID == 1:
#		global.set_player_control(true)
#		self.queue_free()
#		return
		yield(player, "grounded")
		global.set_player_control(false)
		player.siding_left = true
		player.play_anim("idle")
		
		dialog.display([
			["Ícaro","Hmmm... Que tal se eu fizer..."],
			])
		yield(dialog, "finished")
		
		player.play_anim("idle_weapon")
		player.play_sound(global.sound_shake)
		global.wait_until_signal(1)
		yield(global, "waited")
		player.play_anim("idle_weapon")
		player.play_sound(global.sound_shake)
		yield(player.anim, "animation_finished")
		global.wait_until_signal(1)
		yield(global, "waited")
		player.play_anim("start_cross_arms")
		
		dialog.display([
			["Ícaro","A tinta já acabou e nada daquele velho miserável..."],
			])
		yield(dialog, "finished")
		
		walk_pixels = -1000
		yield(self, "walked")
		
		dialog.display([
			["Arthur","Miserável?"],
			])
		yield(dialog, "finished")
		
		player.siding_left = false
		player.play_anim("idle")
		
		dialog.display([
			["Ícaro","E aí, velhote!"],
			["Arthur","Mais respeito, por favor, garoto! Sou seu mestre."],
			["Ícaro","Tá bom! ~~Boa tarde... ~~Velhote! ~~\nQual a aula de hoje?"],
			["Ícaro","Espero que não seja ficar desenhando dicionário de novo!"],
			])
		yield(dialog, "finished")
		
		arthur_sm.set_state(arthur_sm.states.eat)
		
		global.wait_until_signal(1)
		yield(global, "waited")
		
		dialog.display([
			["Arthur","Hmm... ~~\nNão, não. ~~\nHoje seu treino será em campo."],
			["Arthur","Como deve ter percebido, a cidade está infestada desses tais~.~.~. ~~\nPodres."],
			])
		yield(dialog, "finished")
		player.play_anim("start_scratch")
		dialog.display([
			["Ícaro","Podres~.~.~.~? Acho que o Leandro comentou alguma coisa sobre isso."],
			["Arthur","É o nome da gangue que está atacando a cidade. São bandidos mutantes altamente violentos."],
			["Ícaro","E eu sou o que? O Magneto, pra enfrentar esses caras?"],
			["Arthur","Olha, não me vem com essas piadas de quadrinhos de novo. Aqui é mais pra videogame de lutinha."],
			["Ícaro","Tá. ~~\nE eu vou ter que fazer o quê? ~~\nPintura facial neles?"],
			["Arthur","Você vai usar todas as suas habilidades!"],
			["Arthur","Inclusive o Dom que eu te ensinei. Transforme seus desenhos em realidade!"],
		])
		yield(dialog, "finished")
		dialog.display([
			["Ícaro","Mas eu tô sem tinta!"],
			["Arthur","Ah~.~.~. Peraí."],
		])
		yield(dialog, "finished")
		
		global.drop_item(self, load("res://scenes/spray_normal.tscn"), Vector2(-32,-32))
		global.drop_item(self, load("res://scenes/spray_normal.tscn"), Vector2(-32,-16))
		global.drop_item(self, load("res://scenes/spray_normal.tscn"), Vector2(-48,-32))
		global.drop_item(self, load("res://scenes/spray_normal.tscn"), Vector2(-48,-16))
		
		player.play_anim("idle")
		dialog.display([
			["Arthur","Pronto. ~~\nEu trouxe esses por precaução. ~~\nVocê precisa se preparar mais!"],
		])
		yield(dialog, "finished")
		dialog.display([
			["Ícaro","E você precisa explicar melhor as coisas..."],
			["Ícaro","Mas, beleza. Bora lá."],
			["Arthur","Eu disse você! ~~\nSozinho."],
		])
		yield(dialog, "finished")
		arthur_sm.set_state(arthur_sm.states.idle)
		dialog.display([
			["Ícaro","O QUÊ?!"],
			["Arthur","Mas fique tranquilo que vou ficar olhando de longe."],
			["Arthur","E de vez em quando vou dar uns palpites."],
			["Ícaro","Ótimo! ~~\nSe eu morrer, tudo bem, né?"],
			["Arthur","Eu~.~.~. ~~\nConfio em você! ~~\nBoa sorte."],
			])
		yield(dialog, "finished")
		$Area2D/CollisionShape2D.scale.x = 0.5
		
		walk_pixels = 420
		yield(self, "walked")
		
		player.play_anim("start_scratch")
		dialog.display([
			["Ícaro","Vamos lá, né? ~~\nAfinal~.~.~. ~~O que pode dar errado?"],
			])
		yield(dialog, "finished")
		player.play_anim("idle")
		
		times_talked += 1
		
		global.set_player_control(true)
		
		global.get_stage().cut_scene = ID
		
		queue_free()
	
	elif ID == 2 and global.get_stage().cut_scene == 1 and times_talked == 0:
		yield(player, "grounded")
		global.set_player_control(false)
		player.siding_left = global_position.x < player.global_position.x
		player.play_anim("idle")
		
		dialog.display([
			["Arthur","Como estão as coisas lá em cima, garoto?"],
			])
		yield(dialog, "finished")
		
		dialog.display([
			["Ícaro","Como~.~.~.~?"],
			["Ícaro","Cara, a cidade tá cheia desses bichos bizarros! \nVocê me mandou pra um moedor de carne."],
			["Ícaro","Ficam me seguindo e pulando..."],
			["Arthur","Ah, mas não é tão difícil assim vencer esses caras. Tentou carregar o poder antes?"],
			])
		yield(dialog, "finished")
		
		player.play_anim("start_cross_arms")
		
		dialog.display([
			["Ícaro","Carregar~.~.~. ~~~\nHmm... ~~\nNão muda de assunto!"],
			])
		yield(dialog, "finished")
		
		global.drop_item(self, load("res://scenes/health_sandwich.tscn"), Vector2(-32,-72))
		global.drop_item(self, load("res://scenes/health_sandwich.tscn"), Vector2(-32,-64))
		global.drop_item(self, load("res://scenes/health_sandwich.tscn"), Vector2(-48,-72))
		global.drop_item(self, load("res://scenes/health_sandwich.tscn"), Vector2(-48,-64))
		
		dialog.display([
			["Arthur","Pronto. ~~\nCome um pouco e descansa, porque..."],
			["Arthur","Aqui embaixo no esgoto tem mais alguns Podres. ~~\nMas você vai tirar de letra!"],
			["Ícaro","E eu achando que ia aprender alguma coisa hoje. ~~\nSó se for a valorizar a vida que eu ainda tenho!"],
			["Arthur","Esse é um bom aprendizado pra qualquer pessoa, não é? ~~\nMas a lição hoje é sobre usar caixas."],
			["Ícaro","Ainda bem que eu não morri. ~~\nJá pensou se fico sem saber sobre essas caixas?!"],
			["Arthur","Onde houverem esses desenhos com números você pode usar seu spray para criar coisas."],
			["Ícaro","Bom, pelo menos isso parece legal."],
			["Arthur","Você pode empurrar elas normalmente e também pode puxá-las se estiver abaixado. E elas boiam."],
			])
		yield(dialog, "finished")
		
		dialog.display([
			["Ícaro","E se eu quiser sair daqui?"],
			["Arthur","Você pode voltar e ficar brincando de grafitar lá em cima, ou ir até o final por aqui."],
			["Ícaro","Adorei as opções. E em qual delas eu não arrisco a minha vida?"],
			])
		yield(dialog, "finished")
		
		dialog.display([
			["Arthur","Por enquanto é isso. A gente se encontra logo mais de novo."],
			["Ícaro","Espero que seja no plano terrestre ainda e não no inferno."],
			["Arthur","Tá precisando tratar essa raiva e esse sarcasmo, jovem."],
			["Ícaro","Adolescência, sabe como é."],
			])
		yield(dialog, "finished")
		
		player.play_anim("idle")
		
		times_talked += 1
		
		global.set_player_control(true)
		
		global.get_stage().cut_scene = ID
		
