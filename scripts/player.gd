extends KinematicBody2D

const PLAYER_SCALE = 2
const FLOOR_NORMAL = Vector2(0, -1)
const SLOPE_SLIDE_STOP = false
const MIN_ONAIR_TIME = 0.1
const MAX_ONAIR_TIME = 0.2
const WALK_SPEED = 250
const JUMP_SPEED = 450
const WALLJUMP_SPEED = 350
const BULLET_VELOCITY = 400
const PUSH = 100

const WALL_LEFT = -1
const WALL_RIGHT = 1

var linear_velocity = Vector2()
var direction = 0
var onair_time = 0
var on_floor_before = false
var on_floor = false
var shoot_time = 99999 #time since last shot

var shooted = 1

var siding_left = false
var damage_enabled = true
var skip_dialog = false
var knows_walljump = true
var knows_pull = true
var jump_released = true
var can_reload = false
var can_fall = false
var last_pull_body = null
var wall_touching = 0

onready var sprite = $sprite
onready var dark_light = $dark_light
onready var dust = $dust
onready var state_label = $state_label
onready var anim = $anim
onready var anim_screen = $anim_screen
onready var spray_particles = $spray_particles
onready var player_sm = $player_sm
onready var player_asm = $player_asm
onready var timer_shoot = $timer_shoot
onready var timer_wallslide = $timer_wallslide
onready var timer_wallslide_cooldown = $timer_wallslide_cooldown
onready var timer_idle = $timer_idle

onready var bullet = preload("res://scenes/bullet.tscn")

signal grounded

func _ready():
	reset()

func reset():
	if last_pull_body: 
		last_pull_body.follow_player = false
		last_pull_body = null
	
	sprite.set_visible(true)
	dark_light.self_modulate = Color(1,1,1,0)
	sprite.position.x = 0
	sprite.position.y = 0
	player_sm.set_state(player_sm.states.alive)
	player_sm.set_state(player_sm.states.idle)
	anim.play("idle_right")

func _apply_gravity(delta):
	if !global.allow_movement: 
		linear_velocity.y = 0
	else: 
		linear_velocity.y += delta * global.GRAVITY
	
func _apply_movement(_delta):
	if !global.allow_movement: return
	
	linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL, SLOPE_SLIDE_STOP, 4, PI/4, false)
	is_on_floor()
	
	if player_sm.is_on(player_sm.states.push):
		for index in get_slide_count():
			var collision = get_slide_collision(index)
			
			if collision.collider.is_in_group("bodies"):
				collision.collider.apply_central_impulse(Vector2((-collision.normal * 1000).x,0))
	
	on_floor_before = on_floor
	on_floor = onair_time < MIN_ONAIR_TIME
	
	if on_floor and !on_floor_before:
		emit_signal("grounded")
	
	if on_floor:
		if player_sm.is_on([player_sm.states.push, player_sm.states.pull]):
			linear_velocity.x = lerp(linear_velocity.x, direction * WALK_SPEED/2, 0.5)
		else:
			linear_velocity.x = lerp(linear_velocity.x, direction * WALK_SPEED, 0.5)
	else:
		linear_velocity.x = lerp(linear_velocity.x, direction * WALK_SPEED, 0.1)
		check_wall_touching()

func _gravity_wall_slide():
	if !global.allow_movement: return
	
	var max_vel = 96 if !Input.is_action_pressed("move_down") else 96 * 6
	linear_velocity.y = min(linear_velocity.y, max_vel)

func is_opposite_wall():
	return (wall_touching == WALL_RIGHT and Input.is_action_pressed("move_left")) or (wall_touching == WALL_LEFT and Input.is_action_pressed("move_right"))

func is_same_wall():
	return (wall_touching == WALL_LEFT and Input.is_action_pressed("move_left")) or (wall_touching == WALL_RIGHT and Input.is_action_pressed("move_right"))

func is_pushing():
	return round(linear_velocity.x) != 0 and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"))

func is_pulling():
	if knows_pull and last_pull_body and last_pull_body.follow_player:
		return true
	else:
		return false

func _handle_move_input():
	if Input.is_action_pressed("skip") and !skip_dialog:
		skip_dialog = true
	
	if Input.is_action_pressed("shoot") and can_reload:
		global.allow_movement = false
		global.reload_stage()
		return
	
	if !global.allow_movement: return
	
	direction = 0
	
	if Input.is_action_pressed("move_left"):
		direction += -1
		
		if not siding_left:
			if not Input.is_action_pressed("jump") and player_sm.is_on([player_sm.states.wall_slide, player_sm.states.wall_jump]):
				player_sm.set_state(player_sm.states.fall)
			elif not Input.is_action_pressed("move_right") and not player_sm.is_on([player_sm.states.wall_slide, player_sm.states.grab, player_sm.states.pull, player_sm.states.push]):
				siding_left = true
			
			if player_sm.is_on(player_sm.states.push):
				player_sm.set_state(player_sm.states.run)
			
			play_anim()
		
	if Input.is_action_pressed("move_right"):
		direction += 1
		
		if siding_left:
			if not Input.is_action_pressed("jump") and player_sm.is_on([player_sm.states.wall_slide, player_sm.states.wall_jump]):
				player_sm.set_state(player_sm.states.fall)
			
			if not Input.is_action_pressed("move_left") and not player_sm.is_on([player_sm.states.wall_slide, player_sm.states.grab, player_sm.states.pull, player_sm.states.push]):
				siding_left = false
			
			if player_sm.is_on(player_sm.states.push):
				player_sm.set_state(player_sm.states.run)
			
			play_anim()
	
	if Input.is_action_pressed("move_down") and knows_pull:
		if not last_pull_body:
			last_pull_body = get_pull_body()
			
			if last_pull_body:
				last_pull_body.follow_player = true
	else:
		if last_pull_body:
			last_pull_body.follow_player = false
			last_pull_body = null
	
	if Input.is_action_pressed("shoot"):
		shoot()
	
	if player_sm.is_on([player_sm.states.idle, player_sm.states.run, player_sm.states.push, player_sm.states.pull]):
		if Input.is_action_pressed("jump") and jump_released:
			jump()
		elif not Input.is_action_pressed("jump") and not jump_released:
			jump_released = true
	elif knows_walljump and player_sm.is_on([player_sm.states.fall, player_sm.states.wall_slide]):
		if Input.is_action_pressed("jump") and is_opposite_wall() and jump_released:
			wall_jump()
		elif not Input.is_action_pressed("jump") and not jump_released:
			jump_released = true

func play_anim(anim_name=""):
	if player_sm.is_on(player_sm.states.dead): return
	
	var clean_anim_name = anim.current_animation.replace('_left','').replace('_right','')
	
	if anim_name == clean_anim_name and global.allow_movement:
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

func check_wall_touching():
	var previous_wall_touchng = wall_touching
	
	wall_touching = 0
	
	if $raycast_left.is_colliding():
		if global.is_walljump_collision($raycast_left.get_collider()):
			wall_touching += WALL_LEFT
	
	if $raycast_right.is_colliding():
		if global.is_walljump_collision($raycast_right.get_collider()):
			wall_touching += WALL_RIGHT
			
	if previous_wall_touchng != wall_touching and not timer_wallslide.is_stopped():
		print('stop!')
		timer_wallslide.stop()

func jump():
	play_anim("jump")
	player_sm.set_state(player_sm.states.jump)
	
	linear_velocity.y = -JUMP_SPEED
	jump_released = false
	
	play_sound(global.sound_jump)

func wall_jump():
	play_anim("wall_jump")
	player_sm.set_state(player_sm.states.wall_jump)
	
	linear_velocity.y = -WALLJUMP_SPEED
	
	if siding_left:
		linear_velocity.x = WALLJUMP_SPEED
	else:
		linear_velocity.x = -WALLJUMP_SPEED
	
	jump_released = false
	play_sound(global.sound_walljump)

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
		result = WALL_LEFT
	elif is_near_right:
		result = WALL_RIGHT
	
	return result

func get_pull_body():
	if siding_left:
		for body in $left_wall.get_overlapping_bodies():
			if body.is_in_group("bodies") and not global.is_player(body):
				return body
	else:
		for body in $right_wall.get_overlapping_bodies():
			if body.is_in_group("bodies") and not global.is_player(body):
				return body
	
	return null

func shoot():
	if not timer_shoot.is_stopped():
		return
	
	timer_shoot.start()
	
	if (global.bullets):
		var direction = PLAYER_SCALE if not siding_left else -PLAYER_SCALE
		
		if player_sm.is_on(player_sm.states.wall_slide): direction *= -1
		
		$spray_particles.set_emitting(true)
		$spray_particles.position.x = 10 * direction
		$spray_particles.scale.x = direction
		
		player_asm.set_state(player_asm.states.shoot)
		
		if shooted % 2 == 0:
			play_sound(global.sound_spray1)
		else:
			play_sound(global.sound_spray2)
		
		if (global.bullet_type == global.BULLET_NORMAL):
			shoot_spray_normal()
		elif (global.bullet_type == global.BULLET_TRIPLE):
			shoot_spray_triple()
	else:
		player_asm.set_state(player_asm.states.shoot)
		play_sound(global.sound_shake)

func shoot_spray_normal():
	var bi = bullet.instance()
	bi._ready()
	
	var local_direction = PLAYER_SCALE if not siding_left else -PLAYER_SCALE
	
	if player_sm.is_on(player_sm.states.wall_slide): local_direction *= -1
	
	$bullet_shoot.position.x = 8 * local_direction
	
	bi.sprite.scale.x = -local_direction
	bi.position = $bullet_shoot.global_position
	bi.linear_velocity = Vector2(local_direction * BULLET_VELOCITY, 0)
	bi.add_collision_exception_with(self)
	global.get_stage().add_child(bi)
	shoot_time = 0
	
	global.update_bullets(-1)
	shooted += 1

func shoot_spray_triple():
	var bi1 = bullet.instance()
	var bi2 = bullet.instance()
	var bi3 = bullet.instance()
	
	bi1._ready()
	bi2._ready()
	bi3._ready()
	
	var local_direction = PLAYER_SCALE if not siding_left else -PLAYER_SCALE
	
	if player_sm.is_on(player_sm.states.wall_slide): local_direction *= -1
	
	$bullet_shoot.position.x = 8 * local_direction
	
	bi1.sprite.scale.x = -local_direction
	bi2.sprite.scale.x = -local_direction
	bi3.sprite.scale.x = -local_direction
	
	bi1.particles.scale.x = -local_direction
	bi2.particles.scale.x = -local_direction
	bi3.particles.scale.x = -local_direction
	
	bi1.position = $bullet_shoot.global_position
	bi2.position = $bullet_shoot.global_position
	bi3.position = $bullet_shoot.global_position
	
	bi1.linear_velocity = Vector2(local_direction * BULLET_VELOCITY, -160)
	bi2.linear_velocity = Vector2(local_direction * BULLET_VELOCITY, 0)
	bi3.linear_velocity = Vector2(local_direction * BULLET_VELOCITY, 160)
	
	bi1.add_collision_exception_with(self)
	bi2.add_collision_exception_with(self)
	bi3.add_collision_exception_with(self)
	
	global.get_stage().add_child(bi1)
	global.get_stage().add_child(bi2)
	global.get_stage().add_child(bi3)
	
	shoot_time = 0
	
	global.update_bullets(-1)
	shooted += 1

func update_state_label():
	state_label.set('text', player_sm.get_state_desc())

func got_damage(value, on_top=false, on_left=null):
	if player_sm.is_on(player_sm.states.dead): return
	
	if damage_enabled:
		global.update_health(-value)
		
		damage_enabled = false
		player_sm.set_state(player_sm.states.damage)
		
		if on_left == null: on_left = siding_left
		
		linear_velocity = Vector2(0, -JUMP_SPEED/2)
		
		$timer_damage.start()
		$timer_flashing.start()
		$anim_screen.play("damage")

func die():
	stop_sound()
	play_sound(global.sound_dead)
	abort_flashing()
	player_sm.set_state(player_sm.states.dead)
	anim.play("die")
	yield(anim, "animation_finished")
	can_reload = true
	global.get_overall().rodou()

func enable_dust(position=Vector2(0,10)):
	if (not dust.is_emitting()):
		dust.set_emitting(true)
	
	if position:
		dust.set_position($sprite.get_position()+position)
	
	$timer_dust.start()

func disable_dust():
	if (dust.is_emitting()):
		dust.set_emitting(false)

func show_dark_light(value):
	if value:
		anim_screen.play("show_dark_light")
	else:
		anim_screen.play("hide_dark_light")

func abort_flashing():
	damage_enabled = true
	sprite.modulate = Color(1,1,1,1)
	$timer_flashing.stop()

func shake_camera():
	$anim_screen.play("shake")

func _on_timer_flashing_timeout():
	if sprite.modulate == Color(1,1,1,1):
		sprite.modulate = Color(1,1,1,0)
	else:
		sprite.modulate = Color(1,1,1,1)

func _on_timer_shoot_timeout():
	player_asm.set_state(player_asm.states.none)

func _on_timer_idle_timeout():
	play_anim('start_cross_arms')

func _on_timer_wallslide_cooldown_timeout():
	can_fall = true

func _on_timer_wallslide_timeout():
	player_sm.state = player_sm.states.wall_slide
