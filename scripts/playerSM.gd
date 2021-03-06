extends "res://scripts/StateMachine.gd"

var direction_locked_states = []
var wall_states = []

func _ready():
	add_state("idle")
	add_state("grounded_idle")
	add_state("run")
	add_state("grounded_run")
	add_state("jump")
	add_state("fall")
	add_state("push")
	add_state("grab")
	add_state("pull")
	add_state("wall_slide")
	add_state("wall_jump")
	add_state("damage")
	add_state("dead")
	add_state("alive")
	call_deferred("set_state", states.idle)
	
	direction_locked_states = [states.wall_slide, states.wall_jump, states.grab, states.pull, states.push]
	wall_states = [states.wall_slide, states.wall_jump]

func _state_logic(delta):
	if parent.is_on_floor():
		parent.onair_time = 0
	else:
		parent.onair_time += delta
	
	parent._handle_move_input()
	
	if state == states.dead: return
	
	parent._apply_gravity(delta)
	parent._apply_movement(delta)
	
	if state == states.wall_slide:
		parent._gravity_wall_slide()
	
	if state == states.fall:
		parent.onair_counter += delta
	
	#parent.update_state_label()

func _get_transition(_delta):
	if not global.allow_movement: return
	
	var going_up = round(parent.linear_velocity.y) < 0
	var moving = round(parent.linear_velocity.x) != 0
	
	if state in [states.idle, states.run, states.grounded_idle, states.grounded_run, states.fall]:
		if parent.is_pulling():
			var push_direction = parent.push_direction()
			if push_direction == global.SIDE[parent.siding_left]:
				if not moving:
					return states.grab
				else:
					return states.pull
		elif parent.is_pushing():
			var push_direction = parent.push_direction()
			if push_direction == global.SIDE[parent.siding_left]:
				return states.push
	
	if state in [states.idle, states.run, states.grounded_idle, states.grounded_run, states.fall, states.jump, states.push, states.grab, states.pull]:
		if not parent.on_floor:
			if parent.is_same_wall():
				if parent.timer_wallslide.is_stopped():
					parent.timer_wallslide.start()
			if going_up:
				return states.jump
			else:
				return states.fall
	
	match state:
		states.idle:
			if parent.on_floor and moving:
				return states.run
		states.run:
			if parent.on_floor and not moving:
				return states.idle
		states.jump:
			if parent.on_floor:
				if moving:
					return states.grounded_run
				else:
					return states.grounded_idle
			elif not going_up:
				return states.fall
		states.fall:
			if parent.on_floor:
				if moving:
					return states.grounded_run
				else:
					return states.grounded_idle
		states.push:
			if not moving:
				return states.idle
		states.grab:
			if parent.is_pulling():
				if moving:
					return states.pull
			elif not moving:
				return states.idle
		states.pull:
			if parent.is_pulling():
				if not moving:
					return states.grab
			else:
				if moving:
					return states.run
				else:
					return states.idle
		states.wall_slide:
			if parent.on_floor:
				if moving:
					return states.grounded_run
				else:
					return states.grounded_idle
				
			elif not parent.is_same_wall():
				if not parent.can_fall:
					if parent.timer_wallslide_cooldown.is_stopped():
						parent.timer_wallslide_cooldown.start()
				else:
					return states.fall
		states.wall_jump:
			if parent.on_floor:
				if moving:
					return states.grounded_run
				else:
					return states.grounded_idle
			elif not going_up:
				return states.fall
		states.damage:
			if parent.on_floor:
				if moving:
					return states.grounded_run
				else:
					return states.grounded_idle
			elif parent.is_same_wall():
				if parent.timer_wallslide.is_stopped():
					parent.timer_wallslide.start()
	
	return null

func _enter_state(new_state, old_state):
	if old_state == states.dead and new_state != states.alive:
		state = states.dead
		return
	
	if old_state in [states.push, states.pull]:
		if parent.last_pull_body: 
			parent.last_pull_body.follow_player = false
			parent.last_pull_body = null
	
	match new_state:
		states.idle:
			parent.timer_idle.start()
			parent.disable_dust()
			parent.play_anim("idle")
		states.run:
			parent.disable_dust()
			parent.play_anim("run")
		states.grounded_idle:
			parent.disable_dust()
			parent.play_anim("grounded_idle")
		states.grounded_run:
			parent.disable_dust()
			parent.play_anim("grounded_run")
		states.jump:
			if old_state == states.damage: return
			parent.on_floor = false
			parent.disable_dust()
			parent.play_anim("jump")
		states.fall:
			if old_state == states.damage: return
			parent.disable_dust()
			parent.play_anim("fall")
		states.push:
			parent.enable_dust(Vector2(0,16))
			parent.play_sound(global.sound_wallslide)
			parent.play_anim("push")
		states.grab:
			parent.disable_dust()
			parent.play_sound(global.sound_wallslide)
			parent.play_anim("grab")
		states.pull:
			parent.enable_dust(Vector2(global.SIDE[parent.siding_left] * 32,32))
			
			parent.play_anim("pull")
		states.wall_slide:
			parent.can_fall = false
			parent.on_floor = false
			parent.enable_dust(Vector2(parent.wall_touching*10,10))
			parent.play_sound(global.sound_wallslide)
			parent.play_anim("wall_slide")
		states.wall_jump:
			parent.on_floor = false
			parent.enable_dust(Vector2(parent.wall_touching*10,10))
			parent.play_anim("wall_jump")
		states.damage:
			parent.on_floor = false
			parent.disable_dust()
			parent.play_sound(global.sound_damage)
			parent.play_anim("got_damage")

func _exit_state(old_state, new_state):
	match old_state:
		states.wall_slide:
			if [states.idle, states.fall].has(new_state):
				parent.siding_left = !parent.siding_left
		states.idle:
			parent.timer_idle.stop()
		states.push:
			if parent.last_pull_body:
				parent.last_pull_body.follow_player = false
