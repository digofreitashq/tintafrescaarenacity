extends KinematicBody2D

const PLAYER_SCALE = 2
const FLOOR_NORMAL = Vector2(0, -1)
const SLOPE_SLIDE_STOP = 25.0
const MIN_ONAIR_TIME = 0.1
const MAX_ONAIR_TIME = 0.2
const WALK_SPEED = 250 # pixels/sec
const JUMP_SPEED = 350
const WALLJUMP_SPEED = 350
const BULLET_VELOCITY = 800

var linear_vel = Vector2()
var direction = 0
var onair_time = 0
var on_floor_before = false
var on_floor = false
var shoot_time = 99999 #time since last shot

var shooted = 1

var imgs_health = {}
var imgs_bullets = {}

var siding_left = false
var damage_enabled = true
var skip_dialog = false
var knows_walljump = true
var jump_released = true
var can_reload = false

onready var sprite = $sprite
onready var dust = $dust
onready var state_label = $state_label
onready var anim = $anim
onready var front_anim = $front_anim
onready var player_sm = $player_sm
onready var player_asm = $player_asm
onready var timer_shoot = $timer_shoot
onready var timer_idle = $timer_idle

onready var sound_fill = preload("res://sfx/sound_fill.wav")
onready var sound_damage = preload("res://sfx/sound_damage.wav")
onready var sound_jump = preload("res://sfx/sound_jump.wav")
onready var sound_walljump = preload("res://sfx/sound_walljump.wav")
onready var sound_wallslide = preload("res://sfx/sound_wallslide.wav")
onready var sound_grounded = preload("res://sfx/sound_grounded.wav")
onready var sound_shake = preload("res://sfx/sound_shake.wav")
onready var sound_spray1 = preload("res://sfx/sound_spray1.wav")
onready var sound_spray2 = preload("res://sfx/sound_spray2.wav")
onready var sound_dead = preload("res://sfx/sound_dead.wav")

onready var sprite_spray_1 = preload("res://sprites/spray_1.png")
onready var sprite_spray_2 = preload("res://sprites/spray_2.png")

onready var bullet = preload("res://scenes/bullet.tscn")

signal grounded

func _init():
	for i in range(11):
		imgs_health[i] = load("res://sprites/hud_health_%02d.png"%(i))
		imgs_bullets[i] = load("res://sprites/hud_bullets_%02d.png"%(i))

func _ready():
	anim.play("reset")
	front_anim.play("reset")
	yield(anim, "animation_finished")
	$screen/hud.set_visible(true)
	$screen/dialog.set_visible(true)

func _apply_gravity(delta):
	if !global.allow_movement: 
		linear_vel.y = 0
	else: 
		linear_vel.y += delta * global.GRAVITY
	
func _apply_movement(delta):
	if !global.allow_movement: return
	
	linear_vel = move_and_slide(linear_vel, FLOOR_NORMAL, SLOPE_SLIDE_STOP)
	is_on_floor()
	
	on_floor_before = on_floor
	on_floor = onair_time < MIN_ONAIR_TIME
	
	if on_floor and !on_floor_before:
		emit_signal("grounded")
	
	if on_floor:
		linear_vel.x = lerp(linear_vel.x, direction * WALK_SPEED, 0.5)
	else:
		linear_vel.x = lerp(linear_vel.x, direction * WALK_SPEED, 0.1)

func _gravity_wall_slide():
	if !global.allow_movement: return
	
	var max_vel = 96 if !Input.is_action_pressed("move_down") else 96 * 6
	linear_vel.y = min(linear_vel.y, max_vel)

func is_opposite_wall():
	return (wall_direction() == 1 and Input.is_action_pressed("move_left")) or (wall_direction() == -1 and Input.is_action_pressed("move_right"))

func is_same_wall():
	return (wall_direction() == -1 and Input.is_action_pressed("move_left")) or (wall_direction() == 1 and Input.is_action_pressed("move_right"))

func is_pushing():
	return round(linear_vel.x) != 0 and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"))

func _handle_move_input():
	if Input.is_action_pressed("skip") and !skip_dialog:
		skip_dialog = true
	
	if Input.is_action_pressed("shoot") and can_reload:
		global.reload_stage()
		return
	
	if !global.allow_movement: return
	
	direction = 0
	
	if Input.is_action_pressed("move_left"):
		direction += -1
		
		if not siding_left:
			if player_sm.is_on(player_sm.states.wall_jump):
				player_sm.set_state(player_sm.states.fall)
				
			elif not player_sm.is_on([player_sm.states.wall_slide, player_sm.states.wall_jump]):
				if player_sm.is_on(player_sm.states.push):
					player_sm.set_state(player_sm.states.idle)
			
			if not Input.is_action_pressed("move_right"):
				siding_left = true
			
			play_anim()
		
	if Input.is_action_pressed("move_right"):
		direction += 1
		
		if siding_left:
			if player_sm.is_on(player_sm.states.wall_jump):
				player_sm.set_state(player_sm.states.fall)
				
			elif player_sm.is_on([player_sm.states.wall_slide, player_sm.states.wall_jump]):
				if player_sm.is_on(player_sm.states.push):
					player_sm.set_state(player_sm.states.idle)
				
			if not Input.is_action_pressed("move_left"):
				siding_left = false
			
			play_anim()
	
	if Input.is_action_pressed("shoot"):
		shoot()
	
	if player_sm.is_on([player_sm.states.idle, player_sm.states.run, player_sm.states.push]):
		if Input.is_action_pressed("jump") and jump_released:
			play_anim("jump")
			jump()
		elif not Input.is_action_pressed("jump") and not jump_released:
			jump_released = true
	elif player_sm.is_on(player_sm.states.fall):
		if Input.is_action_pressed("jump") and is_opposite_wall():
			wall_jump()
		elif not Input.is_action_pressed("jump") and not jump_released:
			jump_released = true
	elif player_sm.is_on([player_sm.states.jump, player_sm.states.wall_jump]) and onair_time < MAX_ONAIR_TIME:
		if Input.is_action_pressed("jump") and is_opposite_wall():
			wall_jump()
		elif Input.is_action_pressed("jump"):
			jump()
	elif knows_walljump and player_sm.is_on([player_sm.states.wall_slide]):
		if is_opposite_wall():
			if Input.is_action_pressed("jump"):
				wall_jump()
		elif not is_same_wall():
			player_sm.set_state(player_sm.states.fall)

func play_anim(anim_name=""):
	if player_sm.is_on(player_sm.states.dead): return
	
	var clean_anim_name = anim.current_animation.replace('_left','').replace('_right','')
	
	if anim_name == clean_anim_name: 
		return
	elif anim_name == "start_cross_arms" and clean_anim_name == "cross_arms": 
		return	
	elif anim_name == "":
		if anim.current_animation == "": return
		anim_name = clean_anim_name
	
	if siding_left:
		anim_name += "_left"
	else:
		anim_name += "_right"
	
	anim.play(anim_name)

func stop_sound():
	$sound.stop()
	$sound_bonus.stop()

func play_sound(stream):
	if not $sound.playing:
		$sound.stream = stream
		$sound.play()
	else:
		$sound_bonus.stream = stream
		$sound_bonus.play()

func wall_direction():
	var is_near_left = false
	var is_near_right = false
	var left_body = null
	var right_body = null
	
	for body in $left_wall.get_overlapping_bodies():
		if global.is_walljump_collision(body):
			is_near_left = true
			left_body = body
			break
	
	for body in $right_wall.get_overlapping_bodies():
		if global.is_walljump_collision(body):
			is_near_right = true
			right_body = body
			break
	
	var result = -int(is_near_left) + int(is_near_right)
	
	return result

func jump():
	linear_vel.y = -JUMP_SPEED
	jump_released = false
	
	if not player_sm.is_on(player_sm.states.jump):
		play_sound(sound_jump)

func wall_jump():
	if Input.is_action_pressed("jump") and jump_released:
		player_sm.set_state(player_sm.states.wall_jump)
		jump_released = false
		play_sound(sound_walljump)
		
		linear_vel.y = -WALLJUMP_SPEED
		
		if siding_left:
			linear_vel.x = WALLJUMP_SPEED
			siding_left = true
		else:
			linear_vel.x = -WALLJUMP_SPEED
			siding_left = false
	elif not Input.is_action_pressed("jump") and not jump_released:
		jump_released = true

func push_direction():
	var result = 0
	var is_near_left = false
	var is_near_right = false
	var left_body = null
	var right_body = null
	
	for body in $left_wall.get_overlapping_bodies():
		if global.is_push_collision(body):
			is_near_left = true
			left_body = body
			break
	
	for body in $right_wall.get_overlapping_bodies():
		if global.is_push_collision(body):
			is_near_right = true
			right_body = body
			break
	
	if is_near_left and siding_left:
		is_near_left = global.is_push_collision(left_body)
		is_near_right = false
	
	elif is_near_right and !siding_left:
		is_near_left = false
		is_near_right = global.is_push_collision(right_body)
	
	if is_near_left:
		result = -1
	elif is_near_right:
		result = 1
	
	return result

func shoot():
	if timer_shoot.is_stopped():
		player_asm.set_state(player_asm.states.shoot)
		
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
	
	#bi.timer_wait.start()
	#yield(bi.timer_wait, "timeout")
	
	var direction = PLAYER_SCALE if not siding_left else -PLAYER_SCALE
	
	if player_sm.is_on(player_sm.states.wall_slide): direction *= -1
	
	$bullet_shoot.position.x = 16 * direction
	
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
	
	#bi1.timer_wait.start()
	#yield(bi1.timer_wait, "timeout")
		
	var direction = PLAYER_SCALE if not siding_left else -PLAYER_SCALE
	
	if player_sm.is_on(player_sm.states.wall_slide): direction *= -1
	
	$bullet_shoot.position.x = 16 * direction
	
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
	state_label.set('text', player_sm.get_state_desc())

func update_health(value):
	global.health += value
	
	if (global.health < 0):
		global.health = 0
	elif (global.health > 10):
		global.health = 10
	
	if (global.health >= 0):
		$screen/hud/health.set_texture(imgs_health[global.health])
	
	if global.health == 0:
		set_dead()

func update_bullets(value):
	global.bullets += value
	
	if (global.bullets < 0):
		global.bullets = 0
	elif (global.bullets > 10):
		global.bullets = 10	
	
	if (global.bullets >= 0):
		$screen/hud/bullets.set_texture(imgs_bullets[global.bullets])

func update_bullet_type(type):
	global.bullet_type = type
	
	if (global.bullet_type == global.BULLET_NORMAL):
		$screen/hud/spray.texture = sprite_spray_1
	elif (global.bullet_type == global.BULLET_TRIPLE):
		$screen/hud/spray.texture = sprite_spray_2

func update_sprays(value):
	global.sprays += value
	
	if (global.sprays < 0):
		global.sprays = 0

func update_enemies(value):
	global.enemies += value
	
	if (global.enemies < 0):
		global.enemies = 0
	
	if (global.enemies >= 0):
		$screen/hud/label_enemies.set('text', "%0*d" % [3, global.enemies])

func update_graffiti(value):
	global.graffitis += value
	
	if (global.graffitis >= 0):
		$screen/hud/label_sprays.set('text', "%0*d" % [2, global.graffitis])

func got_damage(value, on_top=false, on_left=null):
	if player_sm.is_on(player_sm.states.dead): return
	
	if damage_enabled:
		update_health(-value)
		
		damage_enabled = false
		player_sm.set_state(player_sm.states.damage)
		
		if on_left == null: on_left = siding_left
		
		if on_top:
			linear_vel = Vector2(0, -JUMP_SPEED/2)
		else:
			linear_vel = Vector2(-JUMP_SPEED if on_left else JUMP_SPEED, -JUMP_SPEED)
		
		$timer_damage.start()
		$timer_flashing.start()

func set_dead():
	global.pause_bgm()
	stop_sound()
	play_sound(sound_dead)
	abort_flashing()
	player_sm.set_state(player_sm.states.dead)
	anim.play("die")
	yield(anim, "animation_finished")
	can_reload = true

func enable_dust(position=Vector2(0,10)):
	if (not dust.is_emitting()):
		dust.set_emitting(true)
	
	if position:
		dust.set_position($sprite.get_position()+position)
	
	$timer_dust.start()

func disable_dust():
	if (dust.is_emitting()):
		dust.set_emitting(false)

func abort_flashing():
	damage_enabled = true
	sprite.modulate = Color(1,1,1,1)
	$timer_flashing.stop()

func _on_timer_flashing_timeout():
	if sprite.modulate == Color(1,1,1,1):
		sprite.modulate = Color(1,1,1,0)
	else:
		sprite.modulate = Color(1,1,1,1)

func _on_timer_shoot_timeout():
	player_asm.set_state(player_asm.states.none)

func _on_timer_idle_timeout():
	play_anim('start_cross_arms')
