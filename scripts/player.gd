
extends RigidBody2D

# Character Demo, written by Juan Linietsky and Digo Freitas.

var dust = null

# Member variables
var anim = ""
var siding_left = false
var jumping = false
var move_control = false
var wall_touching = false
var wall_touching_left = false
var wall_touching_right = false
var wall_jumping = false
var jump_released = true
var stopping_jump = false
var shooting = false

var ACCELERATION = 20.0
var MAX_SPEED = 300.0
var JUMP_VELOCITY = 400

var MAX_FLOOR_AIRBORNE_TIME = 0.15
var MAX_SHOOT_POSE_TIME = 0.75
var MAX_WALL_TOUCH_POSE_TIME = 3.0
var MAX_WALL_JUMP_POSE_TIME = 0.8

var airborne_time = 0
var shoot_time = 0
var wall_touch_time = 0
var wall_jump_time = 0
var grounded = true
var found_floor = false

var bullet = preload("res://scenes/bullet.tscn")
var enemy_class = preload("res://scripts/enemy.gd")

var floor_h_velocity = 0.0
var enemy

var shooted = 1

var imgs_health = {}
var imgs_bullets = {}

var disable_damage = false

func update_health(value):
	if (disable_damage): return
	
	global.health += value
	
	if (global.health < 0):
		global.health = 0
	elif (global.health > 10):
		global.health = 10
	
	if (global.health > 0):
		get_node("screen/hud/health").set_hidden(false)
		get_node("screen/hud/health").set_texture(imgs_health[global.health])
	else:
		get_node("screen/hud/health").set_hidden(true)

func update_bullets(value):
	global.bullets += value
	
	if (global.bullets < 0):
		global.bullets = 0
	elif (global.bullets > 10):
		global.bullets = 10	
	
	if (global.bullets > 0):
		get_node("screen/hud/bullets").set_hidden(false)
		get_node("screen/hud/bullets").set_texture(imgs_bullets[global.bullets])
	else:
		get_node("screen/hud/bullets").set_hidden(true)

func update_bullet_type(type):
	global.bullet_type = type
	
	if (global.bullet_type == global.BULLET_NORMAL):
		get_node("screen/hud/spray").set_hidden(true)
	elif (global.bullet_type == global.BULLET_TRIPLE):
		get_node("screen/hud/spray").set_hidden(false)

func got_damage(value):
	update_health(value)
	disable_damage = true
	get_node("sound").play("damage")
	get_node("anim").play("got_damage")
	
	get_node("timer_damage").start()

func enable_dust(amount, autostop=false):
	dust.set_amount(amount)
	
	if (not dust.is_emitting()):
		dust.set_emitting(true)
	
	if (autostop):
		get_node("timer_dust").start()

func shoot_spray_normal():
	var bi = bullet.instance()
	var ss
	if (siding_left):
		ss = -1.0
	else:
		ss = 1.0
	
	if (not found_floor and wall_touching):
		ss = -ss
	
	var pos = get_pos() + get_node("bullet_shoot").get_pos()*Vector2(ss, 1.0)
	
	bi.set_pos(pos)
	get_parent().add_child(bi)
	
	bi.set_linear_velocity(Vector2(1000.0*ss, -80))
	
	if (shooted % 2 == 0):
		get_node("sound").play("spray2")
	else:
		get_node("sound").play("spray1")
	
	update_bullets(-1)
	
	shooted += 1
	
	PS2D.body_add_collision_exception(bi.get_rid(), get_rid())

func shoot_spray_triple():
	var bi1 = bullet.instance()
	var bi2 = bullet.instance()
	var bi3 = bullet.instance()
	
	var ss
	if (siding_left):
		ss = -1.0
	else:
		ss = 1.0
	
	if (not found_floor and wall_touching):
		ss = -ss
	
	var pos = get_pos() + get_node("bullet_shoot").get_pos()*Vector2(ss, 1.0)
	
	bi1.set_pos(pos+Vector2(0,-5))
	bi2.set_pos(pos)
	bi3.set_pos(pos+Vector2(0,5))
	
	bi1.set_linear_velocity(Vector2(1000.0*ss, -160))
	bi2.set_linear_velocity(Vector2(1000.0*ss, 0))
	bi3.set_linear_velocity(Vector2(1000.0*ss, 160))
	
	get_parent().add_child(bi1)
	get_parent().add_child(bi2)
	get_parent().add_child(bi3)
	
	if (shooted % 2 == 0):
		get_node("sound").play("spray2")
	else:
		get_node("sound").play("spray1")
	
	update_bullets(-1)
	
	shooted += 1
	
	PS2D.body_add_collision_exception(bi1.get_rid(), get_rid())
	PS2D.body_add_collision_exception(bi2.get_rid(), get_rid())
	PS2D.body_add_collision_exception(bi3.get_rid(), get_rid())
	PS2D.body_add_collision_exception(bi1.get_rid(), bi2.get_rid())
	PS2D.body_add_collision_exception(bi1.get_rid(), bi3.get_rid())
	PS2D.body_add_collision_exception(bi2.get_rid(), bi1.get_rid())
	PS2D.body_add_collision_exception(bi2.get_rid(), bi3.get_rid())

func _integrate_forces(s):
	var lv = s.get_linear_velocity()
	var step = s.get_step()
	
	var new_anim = anim
	var new_siding_left = siding_left
	var force_sprite_direction = false
	
	# Get the controls
	var move_left = Input.is_action_pressed("move_left")
	var move_right = Input.is_action_pressed("move_right")
	var jump = Input.is_action_pressed("jump")
	var shoot = Input.is_action_pressed("shoot")
	var spawn = Input.is_action_pressed("spawn")
	
	var can_wall_jump_left = get_node("wall_check_left").get_overlapping_bodies().size() > 1
	var can_wall_jump_right = get_node("wall_check_right").get_overlapping_bodies().size() > 1
#	
	if spawn:
		var e = enemy.instance()
		var p = get_pos()
		p.y = p.y - 100
		e.set_pos(p)
		get_parent().add_child(e)
	
	lv.x -= floor_h_velocity
	floor_h_velocity = 0.0
	
	# Find the floor (a contact with upwards facing collision normal)
	found_floor = false
	var floor_index = -1
	
	for x in range(s.get_contact_count()):
		var cc = s.get_contact_collider_object(x)
		var ci = s.get_contact_local_normal(x)
		
		if (ci.dot(Vector2(0, -2)) > 0.6):
			found_floor = true
			move_control = true
			floor_index = x
			
			if (not grounded):
				grounded = true
				get_node("sound").play("grounded")
			
			if (wall_touching):
				wall_touching = false
				
				if (wall_touching_right):
					new_siding_left = true
				elif (wall_touching_left):
					new_siding_left = false
				
				if (dust.is_emitting()):
					dust.set_emitting(false)
		
		# Damage
		if (cc and cc extends enemy_class):
			got_damage(-1)
			
			if (siding_left):
				lv.x -= MAX_SPEED
			else:
				lv.x = MAX_SPEED
			
			lv.y = -JUMP_VELOCITY
			grounded = false
			move_control = false
	
	if (shoot and not shooting):
		shoot_time = 0
		
		if (global.bullets):
			if (global.bullet_type == global.BULLET_NORMAL):
				shoot_spray_normal()
			elif (global.bullet_type == global.BULLET_TRIPLE):
				shoot_spray_triple()
		else:
			get_node("sound").play("shake")
	else:
		shoot_time += step
	
	if (found_floor):
		airborne_time = 0.0
	else:
		airborne_time += step # Time it spent in the air
	
	var on_floor = airborne_time < MAX_FLOOR_AIRBORNE_TIME
	
	if (not jump_released and not jump):
		jump_released = true
	
	# Process jump
	if (jumping):
		# We want the character to immediately change facing side when the player
		# tries to change direction, during air control.
		# This allows for example the player to shoot quickly left then right.
		if (not wall_touching):
			if (move_left and not move_right):
				get_node("sprite").set_scale(Vector2(-2, 2))
				new_siding_left = true
				
			elif (move_right and not move_left):
				get_node("sprite").set_scale(Vector2(2, 2))
				new_siding_left = false
		
		if (lv.y >= 0):
			# Set off the jumping flag if going down
			jumping = false
			wall_jumping = false
			grounded = false
		elif (not jump):
			stopping_jump = true
	
	if (on_floor):
		# Check jump
		if (not jumping and jump and jump_released):
			lv.y = -JUMP_VELOCITY
			jumping = true
			stopping_jump = false
			jump_released = false
			get_node("sound").play("jump")
		
		# Check siding
		if (lv.x < 0 and move_left):
			new_siding_left = true
		elif (lv.x > 0 and move_right):
			new_siding_left = false
		
		if (jumping):
			if (lv.y > 0):
				new_anim = "jumping"
			else:
				new_anim = "idle"
		elif (abs(lv.x) < 0.1):
			if (shoot_time < MAX_SHOOT_POSE_TIME):
				new_anim = "idle_weapon"
				force_sprite_direction = true
			else:
				new_anim = "idle"
		else:
			if (shoot_time < MAX_SHOOT_POSE_TIME):
				new_anim = "run_weapon"
				force_sprite_direction = true
			else:
				new_anim = "run"
	else:
		# Process logic when the character is in the air
		var was_wall_touching = wall_touching
		var was_wall_touching_left = wall_touching_left
		var was_wall_touching_right = wall_touching_right
		
		# Check Wall Jump
		if (wall_jumping and wall_jump_time > MAX_WALL_JUMP_POSE_TIME):
			wall_jumping = false
		
		if (wall_touching and wall_touch_time > MAX_WALL_TOUCH_POSE_TIME):
			wall_touching = false
		
		if (not wall_jumping and wall_touching and jump and jump_released):
			if (wall_touching_left):
				new_siding_left = false
				lv.x = MAX_SPEED/2
			elif (wall_touching_right):
				new_siding_left = true
				lv.x = -MAX_SPEED/2
			
			lv.y = -JUMP_VELOCITY
			jumping = true
			jump_released = false
			wall_touching = false
			wall_jumping = true
			wall_jump_time = 0
			move_control = false
			get_node("sound").play("jump")
		
		elif (not wall_jumping and can_wall_jump_left or can_wall_jump_right):
			if (move_left or move_right):
				if (can_wall_jump_left and move_left):
					wall_touching_left = true
					wall_touching_right = false
				elif (can_wall_jump_right and move_right):
					wall_touching_left = false
					wall_touching_right = true
				elif (wall_touching_left  and not can_wall_jump_left or wall_touching_right and not can_wall_jump_right):
					wall_touching_left = false
					wall_touching_right = false
				
				if (wall_touching_left or wall_touching_right):
					if (wall_touching_left):
						dust.set_pos(get_node("CollisionPolygon2D").get_pos()+Vector2(-20,0))
					else:
						dust.set_pos(get_node("CollisionPolygon2D").get_pos()+Vector2(20,0))
					
					if (not dust.is_emitting()):
						enable_dust(5)
					
					if (wall_touching_left):
						new_siding_left = true
					elif (wall_touching_right):
						new_siding_left = false
					
					if (not wall_touching and not wall_jumping):
						get_node("sound").play("grounded")
					
					wall_touching = true
					wall_touch_time = 0
				elif (wall_touching):
					wall_touching = false
		else:
			wall_touching = false
		
		if (was_wall_touching and not wall_touching):
			if (dust.is_emitting()):
				dust.set_emitting(false)
			
			if (move_left and not move_right):
				new_siding_left = true
			elif (move_right and not move_left):
				new_siding_left = false
			elif (was_wall_touching_left):
				new_siding_left = true
			elif (was_wall_touching_right):
				new_siding_left = false
		
		if (wall_jumping):
			if (wall_jump_time == 0):
				new_anim = "wall_jumping"
			
			wall_jump_time += step
		elif (wall_touching):
			if (shoot):
				new_anim = "wall_touching_shooting"
			else:
				new_anim = "wall_touching"
			
			wall_touch_time += step
		elif (lv.y < 0):
			if (shoot_time < MAX_SHOOT_POSE_TIME):
				new_anim = "jumping_weapon"
				force_sprite_direction = true
			else:
				new_anim = "jumping"
		else:
			if (shoot_time < MAX_SHOOT_POSE_TIME):
				new_anim = "falling_weapon"
				force_sprite_direction = true
			else:
				new_anim = "falling"
	
	# Update siding
	if (new_siding_left != siding_left):
		siding_left = new_siding_left
	
	if (wall_jumping and wall_jump_time < MAX_WALL_JUMP_POSE_TIME):
		if (wall_touching_right):
			siding_left = true
			get_node("sprite").set_scale(Vector2(-2, 2))
		elif (wall_touching_left):
			siding_left = false
			get_node("sprite").set_scale(Vector2(2, 2))
	elif (force_sprite_direction):
		get_node("sprite").set_scale(Vector2(2, 2))
		
		if (siding_left):
			new_anim = new_anim + "_left"
		else:
			new_anim = new_anim + "_right"
	else:
		if (siding_left):
			get_node("sprite").set_scale(Vector2(-2, 2))
		else:
			get_node("sprite").set_scale(Vector2(2, 2))
	
	# Change animation
	if (new_anim != anim):
		anim = new_anim
		get_node("anim").play(anim)
	
	shooting = shoot
	
	if (not wall_jumping and move_left and not move_right):
		if (not siding_left):
			if (not jumping and lv.x >= MAX_SPEED/2):
				get_node("sound").play("grounded")
				dust.set_pos(get_node("CollisionPolygon2D").get_pos()+Vector2(10,20))
				enable_dust(15,true)
		
		lv.x = max(lv.x - ACCELERATION, -MAX_SPEED)
	
	elif (not wall_jumping and move_right and not move_left):
		if (siding_left):
			if (not jumping and lv.x <= -MAX_SPEED/2):
				get_node("sound").play("grounded")
				dust.set_pos(get_node("CollisionPolygon2D").get_pos()+Vector2(-10,20))
				enable_dust(15,true)
		
		lv.x = min(lv.x + ACCELERATION, MAX_SPEED)
	
	else:
		var xv = abs(lv.x)
		xv -= ACCELERATION*0.8
		if (xv < 0):
			xv = 0
		lv.x = sign(lv.x)*xv
	
	if (found_floor):
		floor_h_velocity = s.get_contact_collider_velocity_at_pos(floor_index).x
		lv.x += floor_h_velocity
	
	# Finally, apply gravity and set back the linear velocity
	if (wall_touching and lv.y >= 0):
		lv += s.get_total_gravity()*0.1*step
	else:
		lv += s.get_total_gravity()*step
	
	s.set_linear_velocity(lv)

func _ready():
	enemy = ResourceLoader.load("res://scenes/enemy.tscn")
	
	get_node("anim").play("fadein")
	
	dust = get_node("dust")
	
	for i in range(10):
		imgs_health[i+1] = load("res://sprites/hud_health_%02d.png"%(i+1))
		imgs_bullets[i+1] = load("res://sprites/hud_bullets_%02d.png"%(i+1))

func _on_timer_damage_timeout():
	disable_damage = false
	get_node("anim").play("after_damage")

func _on_timer_dust_timeout():
	if (dust.is_emitting()):
		dust.set_emitting(false)
