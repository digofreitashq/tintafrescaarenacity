extends KinematicBody2D

const SPRITE_SCALE = 2
const FLOOR_NORMAL = Vector2(0, -1)
const SLOPE_SLIDE_STOP = false
const MIN_ONAIR_TIME = 0.1
const WALK_SPEED = 400
const JUMP_SPEED = 450
const WALLJUMP_SPEED = 200
const BULLET_VELOCITY = 400
const PUSH = 100

var linear_velocity = Vector2()
var direction = 0
var onair_time = 0
var onair_counter = 0
var on_floor_before = false
var on_floor = false

var shooted = 1

var siding_left = false
var damage_enabled = true
var skip_dialog = false
var jump_released = true
var can_reload = false
var can_fall = false
var last_pull_body = null
var wall_touching = 0
var wall_touched = 0

var pressed_left = false
var pressed_right = false
var pressed_down = false
var pressed_jump = false
var pressed_shoot = false
var pressed_skip = false

onready var sprite = $sprite
onready var dark_light = $dark_light
onready var dust = $dust
onready var state_label = $state_label
onready var anim = $anim
onready var anim_screen = $anim_screen
onready var anim_charging = $anim_charging
onready var spray_particles = $spray_particles
onready var player_sm = $player_sm
onready var player_asm = $player_asm
onready var timer_wallslide = $timer_wallslide
onready var timer_wallslide_cooldown = $timer_wallslide_cooldown
onready var timer_idle = $timer_idle
onready var timer_shoot = $timer_shoot
onready var sound_charging = $sound_charging
onready var sound_flashing = $sound_flashing

onready var white_shader = preload("res://shaders/white_shader.tres")
onready var bullet = preload("res://scenes/bullet.tscn")
onready var impact_dust = preload("res://scenes/impact_dust.tscn")

signal grounded

func _ready():
	reset()

func reset():
	if last_pull_body: 
		last_pull_body.follow_player = false
		last_pull_body = null
	
	sprite.set_visible(true)
	sprite.material = null
	dark_light.self_modulate = Color(1,1,1,0)
	sprite.position.x = 0
	sprite.position.y = 0
	player_sm.set_state(player_sm.states.alive)
	player_sm.set_state(player_sm.states.idle)
	anim.play("idle_right")
	anim_charging.play("stop")

func _apply_gravity(delta):
	if !global.allow_movement: 
		linear_velocity.y = 0
	else: 
		linear_velocity.y += delta * global.GRAVITY
	
func _apply_movement(_delta):
	if !global.allow_movement: return
	
	linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL, SLOPE_SLIDE_STOP, 4, PI/4, false)
	
	for index in get_slide_count():
		var collision = get_slide_collision(index)
		
		if collision.collider.is_in_group("bodies"):
			collision.collider.apply_central_impulse(Vector2((-collision.normal * 100).x,0))
	
	on_floor_before = on_floor
	on_floor = onair_time < MIN_ONAIR_TIME
	
	if on_floor and !on_floor_before and linear_velocity.y >= 0:
		if onair_counter > 0.3:
			var new_impact_dust = impact_dust.instance()
			new_impact_dust.position = Vector2(global_position.x, global_position.y+24)
			new_impact_dust.z_index = z_index + 1
			global.get_stage().add_child(new_impact_dust)
			new_impact_dust._ready()
		
		onair_counter = 0
		emit_signal("grounded")
	
	var local_direction = 0
	
	if direction > 0: local_direction = 1
	elif direction < 0: local_direction = -1
	
	if on_floor:
		if player_sm.is_on([player_sm.states.push, player_sm.states.pull]):
			linear_velocity.x = lerp(linear_velocity.x, local_direction * WALK_SPEED/2, 0.5)
		else:
			linear_velocity.x = lerp(linear_velocity.x, local_direction * WALK_SPEED, 0.5)
	else:
		linear_velocity.x = lerp(linear_velocity.x, local_direction * WALK_SPEED, 0.1)
		check_wall_touching()

func _gravity_wall_slide():
	if !global.allow_movement: return
	
	var max_vel = 96 if !pressed_down else 96 * 6
	linear_velocity.y = min(linear_velocity.y, max_vel)

func is_opposite_wall():
	return (wall_touching == global.SIDE_RIGHT and pressed_left) or (wall_touching == global.SIDE_LEFT and pressed_right)

func is_same_wall():
	return (wall_touching == global.SIDE_LEFT and pressed_left) or (wall_touching == global.SIDE_RIGHT and pressed_right)

func is_pushing():
	return round(linear_velocity.x) != 0 and (pressed_left or pressed_right)

func is_pulling():
	if last_pull_body and last_pull_body.follow_player:
		return true
	else:
		return false

func _handle_move_input():
	pressed_left = Input.is_action_pressed("move_left")
	pressed_right = Input.is_action_pressed("move_right")
	pressed_down = Input.is_action_pressed("move_down")
	pressed_jump = Input.is_action_pressed("jump")
	pressed_shoot = Input.is_action_pressed("shoot")
	pressed_skip = Input.is_action_pressed("skip")
	
	if pressed_skip and !skip_dialog:
		skip_dialog = true
	
	if pressed_shoot and can_reload:
		global.allow_movement = false
		global.reload_stage()
		return
	
	if !global.allow_movement: return
	
	direction = 0
	
	if pressed_left:
		direction += -1
		
		if not siding_left:
			if not pressed_jump and player_sm.is_on(player_sm.wall_states):
				player_sm.set_state(player_sm.states.fall)
			
			elif not pressed_right:
				if not player_sm.is_on(player_sm.direction_locked_states) and not player_sm.is_on(player_sm.wall_states):
					siding_left = true
			
			if player_sm.is_on(player_sm.states.push):
				player_sm.set_state(player_sm.states.run)
			
			play_anim()
		
	if pressed_right:
		direction += 1
		
		if siding_left:
			if not pressed_jump and player_sm.is_on(player_sm.wall_states):
				player_sm.set_state(player_sm.states.fall)
			
			elif not pressed_left:
				if not player_sm.is_on(player_sm.direction_locked_states) and not player_sm.is_on(player_sm.wall_states):
					siding_left = false
			
			if player_sm.is_on(player_sm.states.push):
				player_sm.set_state(player_sm.states.run)
			
			play_anim()
	
	if pressed_down:
		if not last_pull_body:
			last_pull_body = get_pull_body()
			
			if last_pull_body:
				last_pull_body.follow_player = true
	else:
		if last_pull_body:
			last_pull_body.follow_player = false
			last_pull_body = null
	
	if pressed_shoot and player_asm.is_on(player_asm.states.none):
		start_shoot()
	elif Input.is_action_just_released("shoot") and not player_asm.is_on(player_asm.states.none):
		shoot()
	
	if player_sm.is_on([player_sm.states.idle, player_sm.states.run, player_sm.states.grounded_idle, player_sm.states.grounded_run, player_sm.states.push, player_sm.states.pull]):
		if pressed_jump and jump_released:
			jump()
		elif not pressed_jump and not jump_released and on_floor:
			jump_released = true
	elif player_sm.is_on([player_sm.states.fall, player_sm.states.wall_slide]):
		if pressed_jump and is_opposite_wall() and jump_released:
			wall_jump()
		elif not pressed_jump and not jump_released:
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
			wall_touching += global.SIDE_LEFT
	
	if $raycast_right.is_colliding():
		if global.is_walljump_collision($raycast_right.get_collider()):
			wall_touching += global.SIDE_RIGHT
	
	if wall_touching != 0:
		wall_touched = wall_touching
	
	if previous_wall_touchng != wall_touching and not timer_wallslide.is_stopped():
		timer_wallslide.stop()

func jump():
	play_anim("jump")
	player_sm.set_state(player_sm.states.jump)
	
	linear_velocity.y = -JUMP_SPEED
	jump_released = false
	
	play_sound(global.sound_jump)

func wall_jump():
	siding_left = wall_touched == global.SIDE_RIGHT
	
	play_anim("wall_jump")
	player_sm.set_state(player_sm.states.wall_jump)
	
	linear_velocity.y = -JUMP_SPEED
	linear_velocity.x = global.SIDE[siding_left] * WALLJUMP_SPEED
	
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
		result = global.SIDE_LEFT
	elif is_near_right:
		result = global.SIDE_RIGHT
	
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

func start_shoot():
	if not player_asm.is_on(player_asm.states.none):
		return
	
	if global.bullets == 0:
		if not player_asm.is_on(player_asm.states.shoot):
			player_asm.set_state(player_asm.states.shoot)
			play_sound(global.sound_shake)
	elif global.bullets >= 0:
		if not player_asm.is_on(player_asm.states.between):
			player_asm.set_state(player_asm.states.between)

func shoot():
	var spray_direction = global.SIDE[siding_left]
	
	if global.bullets == 0 or player_asm.is_on(player_asm.states.shoot): return
	
	if player_sm.is_on(player_sm.states.wall_slide): spray_direction *= -1
	
	$spray_particles.set_emitting(true)
	$spray_particles.position.x = spray_direction * 20
	$spray_particles.scale.x = spray_direction * SPRITE_SCALE
	
	if player_asm.is_on(player_asm.states.flash) and global.update_bullets(-10):
		player_asm.set_state(player_asm.states.shoot)
		play_sound(global.sound_spray3)
		shoot_spray_special()
	elif global.update_bullets(-2):
		player_asm.set_state(player_asm.states.shoot)
		
		if shooted % 2 == 0:
			play_sound(global.sound_spray1)
		else:
			play_sound(global.sound_spray2)
		
		shoot_spray_normal()
	elif not player_asm.is_on(player_asm.states.shoot):
		player_asm.set_state(player_asm.states.shoot)
		play_sound(global.sound_shake)

func shoot_spray_normal():
	var bi = bullet.instance()
	bi._ready()
	
	var local_direction = global.SIDE[siding_left]
	
	if player_sm.is_on(player_sm.states.wall_slide): local_direction *= -1
	
	$bullet_shoot.position.x = 16 * local_direction
	
	bi.sprite.scale.x = local_direction * SPRITE_SCALE
	bi.position = $bullet_shoot.global_position
	bi.linear_velocity = Vector2(local_direction * BULLET_VELOCITY, 0)
	bi.add_collision_exception_with(self)
	global.get_stage().add_child(bi)
	
	shooted += 1

func shoot_spray_special():
	var step = 80
	var position_y_list = [-160,-80,0,80,160]
	var bi = null
	var local_direction = global.SIDE[siding_left]
	
	if player_sm.is_on(player_sm.states.wall_slide): local_direction *= -1
	
	$bullet_shoot.position.x = 16 * local_direction
	
	for position_y in position_y_list:
		bi = bullet.instance()
		bi._ready()
		bi.sprite.scale.x = local_direction * SPRITE_SCALE
		bi.position = $bullet_shoot.global_position
		bi.linear_velocity = Vector2(local_direction * BULLET_VELOCITY, position_y)
		bi.add_collision_exception_with(self)
		global.get_stage().add_child(bi)
	
	shooted += 1

func update_state_label():
	state_label.set('text', player_asm.get_state_desc())

func got_damage(value, on_top=false, on_left=null):
	if player_sm.is_on(player_sm.states.dead): return
	
	if damage_enabled:
		global.update_health(-value)
		
		damage_enabled = false
		player_sm.set_state(player_sm.states.damage)
		player_asm.set_state(player_asm.states.none)
		
		if on_left == null: on_left = siding_left
		
		linear_velocity = Vector2(-global.SIDE[on_left] * WALK_SPEED/5, -JUMP_SPEED/2)
		
		$timer_damage.start()
		$timer_flashing.start()
		$anim_screen.play("damage")

func die():
	stop_sound()
	play_sound(global.sound_dead)
	abort_flashing()
	player_sm.set_state(player_sm.states.dead)
	collision_layer = 0
	collision_mask = 0
	anim.play("die")
	yield(anim, "animation_finished")
	can_reload = true
	global.get_overall().rodou()

func set_state(new_state):
	player_sm.set_state(player_sm.states[new_state])

func set_action_state(new_state):
	player_asm.set_state(player_asm.states[new_state])

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

func set_white_shader(value, set_face=false, set_health=false, set_bullets=false):
	var hud = global.get_hud()
	var sprites = [sprite]
	
	if set_face: sprites.append(hud.find_node("base"))
	if set_health: sprites.append(hud.find_node("health"))
	if set_bullets: sprites.append(hud.find_node("bullets"))
	
	if value:
		for asprite in sprites:
			asprite.material = white_shader
			asprite.material.set_shader_param("bright_amount", 0.5)
	else:
		for asprite in sprites:
			asprite.material = null

func _on_timer_flashing_timeout():
	if sprite.modulate == Color(1,1,1,1):
		sprite.modulate = Color(1,1,1,0)
	else:
		sprite.modulate = Color(1,1,1,1)

func _on_timer_idle_timeout():
	play_anim('start_cross_arms')

func _on_timer_wallslide_cooldown_timeout():
	can_fall = true

func _on_timer_wallslide_timeout():
	if is_same_wall():
		siding_left = wall_touching == global.SIDE_LEFT
		player_sm.state = player_sm.states.wall_slide

func _on_timer_shoot_timeout():
	if player_asm.is_on(player_asm.states.shoot):
		player_asm.set_state(player_asm.states.none)
