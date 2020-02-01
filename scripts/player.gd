extends KinematicBody2D

const PLAYER_SCALE = 2
const GRAVITY = 900
const FLOOR_NORMAL = Vector2(0, -2)
const SLOPE_SLIDE_STOP = 25.0
const MIN_ONAIR_TIME = 0.1
const WALK_SPEED = 250 # pixels/sec
const JUMP_SPEED = 480
const WALLJUMP_SPEED = 600
const BULLET_VELOCITY = 800

var linear_vel = Vector2()
var target_speed = 0
var onair_time = 0
var on_floor = false
var shoot_time = 99999 #time since last shot

var shooted = 1

var imgs_health = {}
var imgs_bullets = {}

var siding_left = false
var disable_damage = false

onready var sprite = $sprite
onready var dust = $dust
onready var state_label = $state_label
onready var anim = $anim
onready var left_wall_raycast = $left_wall_raycast
onready var right_wall_raycast = $right_wall_raycast
onready var player_sm = $player_sm
onready var player_asm = $player_asm
onready var timer_shoot = $timer_shoot
onready var timer_wallslide_cooldown = $timer_wallslide_cooldown

onready var sound_damage = preload("res://sfx/sound_damage.wav")
onready var sound_jump = preload("res://sfx/sound_jump.wav")
onready var sound_grounded = preload("res://sfx/sound_grounded.wav")
onready var sound_shake = preload("res://sfx/sound_shake.wav")
onready var sound_spray1 = preload("res://sfx/sound_spray1.wav")
onready var sound_spray2 = preload("res://sfx/sound_spray2.wav")

onready var bullet = preload("res://scenes/bullet.tscn")

func _ready():
	for i in range(11):
		imgs_health[i] = load("res://sprites/hud_health_%02d.png"%(i))
		imgs_bullets[i] = load("res://sprites/hud_bullets_%02d.png"%(i))

func _apply_gravity(delta):
	if !global.allow_movement: return
	
	linear_vel.y += delta * GRAVITY

func _apply_movement(delta):
	if !global.allow_movement: return
	
	linear_vel = move_and_slide(linear_vel, FLOOR_NORMAL, SLOPE_SLIDE_STOP)
	
	if is_on_floor():
		onair_time = 0

	on_floor = onair_time < MIN_ONAIR_TIME
	target_speed *= WALK_SPEED
	linear_vel.x = lerp(linear_vel.x, target_speed, 0.1)

func _gravity_wall_slide():
	if !global.allow_movement: return
	
	var max_vel = 96 if !Input.is_action_pressed("move_down") else 96 * 6
	linear_vel.y = min(linear_vel.y, max_vel)

func _handle_move_input():
	if !global.allow_movement: return
	
	target_speed = 0
	
	if Input.is_action_pressed("move_left"):
		target_speed += -1
		
		if not siding_left: 
			if player_sm.state == player_sm.states.wall_slide:
				player_sm.set_state(player_sm.states.fall)
				
			siding_left = true
			play_anim(anim.current_animation.replace('_right',''))
		
	if Input.is_action_pressed("move_right"):
		target_speed += 1
		
		if siding_left:
			if player_sm.state == player_sm.states.wall_slide:
				player_sm.set_state(player_sm.states.fall)
			
			siding_left = false
			play_anim(anim.current_animation.replace('_left',''))
	
	if [player_sm.states.idle, player_sm.states.run].has(player_sm.state):
		if Input.is_action_pressed("jump"):
			linear_vel.y = -JUMP_SPEED
	elif [player_sm.states.wall_slide].has(player_sm.state):
		if Input.is_action_pressed("jump"):
			player_sm.set_state(player_sm.states.wall_jump)
			
			linear_vel.y = -WALLJUMP_SPEED
			
			if siding_left:
				linear_vel.x += WALLJUMP_SPEED
			else:
				linear_vel.x -= WALLJUMP_SPEED

func play_anim(anim_name):
	if siding_left:
		anim_name += "_left"
	else:
		anim_name += "_right"
	
	anim.play(anim_name)

func play_sound(stream):
	if not $timer_sound.is_stopped():
		return
	
	$timer_sound.start()
	$sound.stream = stream
	$sound.play()

func is_shooting():
	return player_asm.state == player_asm.states.shoot

func check_is_valid_wall(some_wall_raycasts):
	if not some_wall_raycasts: return false
	
	for raycast in some_wall_raycasts.get_children():
		if raycast.is_colliding():
			var dot = acos(Vector2.UP.dot(raycast.get_colision_normal()))
			
			if dot > PI * 0.35 and dot > PI * 0.55:
				return true
	
	return false
	
func wall_direction():
	var is_near_left = left_wall_raycast.is_colliding()
	var is_near_right = right_wall_raycast.is_colliding()
	
	return -int(is_near_left) + int(is_near_right)

func shoot():
	if timer_shoot.is_stopped():
		timer_shoot.start()
		
		if (global.bullets):
			if shooted % 2 == 0:
				play_sound(sound_spray1)
			else:
				play_sound(sound_spray2)
			
			if (global.bullet_type == global.BULLET_NORMAL):
				shoot_spray_normal()
			elif (global.bullet_type == global.BULLET_TRIPLE):
				shoot_spray_triple()
		else:
			play_sound(sound_shake)

func shoot_spray_normal():
	var bi = bullet.instance()
	bi._ready()
	
	var direction = PLAYER_SCALE if not siding_left else -PLAYER_SCALE
	
	if player_sm.state == player_sm.states.wall_slide: direction *= -1
	
	bi.sprite.scale.x = -direction
	bi.particles.scale.x = -direction
	bi.position = $bullet_shoot.global_position #use node for shoot position
	bi.linear_velocity = Vector2(direction * BULLET_VELOCITY, 0)
	bi.add_collision_exception_with(self) # don't want player to collide with bullet
	get_parent().add_child(bi) #don't want bullet to move with me, so add it as child of parent
	shoot_time = 0
	
	update_bullets(-1)
	shooted += 1

func shoot_spray_triple():
	var bi1 = bullet.instance()
	var bi2 = bullet.instance()
	var bi3 = bullet.instance()
	
	bi1._ready()
	bi2._ready()
	bi3._ready()
	
	var direction = PLAYER_SCALE if not siding_left else -PLAYER_SCALE
	
	if player_sm.state == player_sm.states.wall_slide: direction *= -1
	
	bi1.sprite.scale.x = -direction
	bi2.sprite.scale.x = -direction
	bi3.sprite.scale.x = -direction
	
	bi1.particles.scale.x = -direction
	bi2.particles.scale.x = -direction
	bi3.particles.scale.x = -direction
	
	bi1.position = $bullet_shoot.global_position #use node for shoot position
	bi2.position = $bullet_shoot.global_position #use node for shoot position
	bi3.position = $bullet_shoot.global_position #use node for shoot position
	
	bi1.linear_velocity = Vector2(direction * BULLET_VELOCITY, -160)
	bi2.linear_velocity = Vector2(direction * BULLET_VELOCITY, 0)
	bi3.linear_velocity = Vector2(direction * BULLET_VELOCITY, 160)
	
	bi1.add_collision_exception_with(self) # don't want player to collide with bullet
	bi2.add_collision_exception_with(self) # don't want player to collide with bullet
	bi3.add_collision_exception_with(self) # don't want player to collide with bullet
	
	get_parent().add_child(bi1) #don't want bullet to move with me, so add it as child of parent
	get_parent().add_child(bi2) #don't want bullet to move with me, so add it as child of parent
	get_parent().add_child(bi3) #don't want bullet to move with me, so add it as child of parent
	
	shoot_time = 0
	
	update_bullets(-1)
	shooted += 1

func update_state_label():
	return
	if player_asm.state == player_asm.states.shoot:
		state_label.set('text', player_asm.states_description[player_asm.states.shoot])
	else:
		state_label.set('text', player_sm.states_description[player_sm.state])

func update_health(value):
	if (disable_damage): return
	
	global.health += value
	
	if (global.health < 0):
		global.health = 0
	elif (global.health > 10):
		global.health = 10
	
	if (global.health >= 0):
		get_node("screen/hud/health").set_texture(imgs_health[global.health])

func update_bullets(value):
	global.bullets += value
	
	if (global.bullets < 0):
		global.bullets = 0
	elif (global.bullets > 10):
		global.bullets = 10	
	
	if (global.bullets >= 0):
		get_node("screen/hud/bullets").set_texture(imgs_bullets[global.bullets])

func update_bullet_type(type):
	global.bullet_type = type
	
	if (global.bullet_type == global.BULLET_NORMAL):
		get_node("screen/hud/spray").visible = !(true)
	elif (global.bullet_type == global.BULLET_TRIPLE):
		get_node("screen/hud/spray").visible = !(false)

func update_sprays(value):
	global.sprays += value
	
	if (global.sprays < 0):
		global.sprays = 0
	
	if (global.sprays >= 0):
		get_node("screen/hud/label_sprays").set('text', "%0*d" % [4, global.sprays])

func update_enemies(value):
	global.enemies += value
	
	if (global.enemies < 0):
		global.enemies = 0
	
	if (global.enemies >= 0):
		get_node("screen/hud/label_enemies").set('text', "%0*d" % [4, global.enemies])

func got_damage(value, on_left=null):
	update_health(value)
	disable_damage = true
	player_sm.set_state(player_sm.states.damage)
	
	if on_left == null: on_left = siding_left
	
	linear_vel = Vector2(-JUMP_SPEED if on_left else JUMP_SPEED, -JUMP_SPEED)
	
	play_sound(sound_damage)
	$anim.play("got_damage")
	get_node("timer_damage").start()

func enable_dust(position=Vector2(0,10)):
	if (not dust.is_emitting()):
		dust.set_emitting(true)
	
	if position:
		dust.set_position($CollisionPolygon2D.get_position()+position)
	
	$timer_dust.start()

func disable_dust():
	if (dust.is_emitting()):
		dust.set_emitting(false)

func _on_anim_animation_finished(anim_name):
	pass

func _on_anim_animation_started(anim_name):
	pass

func _on_timer_damage_timeout():
	disable_damage = false
