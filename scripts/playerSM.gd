extends "res://scripts/StateMachine.gd"

func _ready():
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("fall")
	add_state("wall_slide")
	add_state("wall_jump")
	call_deferred("set_state", states.idle)
	
func _input(event):
	if [states.idle, states.run].has(state):
		if event.is_action_pressed("jump"):
			parent.linear_vel.y = -parent.JUMP_SPEED
	elif [states.wall_slide].has(state):
		if event.is_action_pressed("jump"):
			set_state(states.wall_jump)
			
			parent.linear_vel.y = -parent.WALLJUMP_SPEED
			
			if parent.siding_left:
				parent.linear_vel.x += parent.WALLJUMP_SPEED
			else:
				parent.linear_vel.x -= parent.WALLJUMP_SPEED
			

func _state_logic(delta):
	parent.onair_time += delta
	parent.shoot_time += delta
	
	parent._handle_move_input()
	parent._apply_gravity(delta)
	parent._apply_movement(delta)
	
	if state == states.wall_slide:
		parent._gravity_wall_slide()
	
	parent.update_state_label()

func _get_transition(delta):
	match state:
		states.idle:
			if !parent.is_on_floor():
				if parent.linear_vel.y < 0:
					return states.jump
				elif parent.linear_vel.y > 0:
					return states.fall
			elif round(parent.linear_vel.x) != 0 and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")):
				parent.enable_dust()
				return states.run
		states.run:
			if !parent.is_on_floor():
				if parent.linear_vel.y < 0:
					return states.jump
				elif parent.linear_vel.y > 0:
					return states.fall
			elif round(parent.linear_vel.x) == 0:
				return states.idle
		states.jump:
			if parent.is_on_floor():
				return states.idle
			elif parent.linear_vel.y >= 0:
				return states.fall
		states.fall:
			if parent.is_on_floor():
				return states.idle
			elif parent.linear_vel.y >= 0 and parent.wall_direction() != 0 and parent.timer_wallslide_cooldown.is_stopped():
				parent.siding_left = parent.wall_direction() == -1
				return states.wall_slide
			elif parent.linear_vel.y < 0:
				return states.jump
		states.wall_slide:
			if parent.is_on_floor():
				return states.idle
			elif parent.linear_vel.y >= 0 and parent.wall_direction() == 0:
				return states.fall
		states.wall_jump:
			if parent.is_on_floor():
				return states.idle
			elif parent.linear_vel.y >= 0 and parent.wall_direction() != 0 and parent.timer_wallslide_cooldown.is_stopped():
				parent.siding_left = parent.wall_direction() == -1
				return states.wall_slide
			elif parent.linear_vel.y >= 0:
				return states.fall
	
	return null

func _enter_state(new_state, old_state):
	match new_state:
		states.idle:
			parent.disable_dust()
			parent.play_anim("idle")
		states.run:
			parent.enable_dust()
			parent.play_anim("run")
		states.jump:
			parent.disable_dust()
			parent.play_sound(parent.sound_jump)
			parent.play_anim("jump")
		states.fall:
			parent.disable_dust()
			parent.play_anim("fall")
		states.wall_slide:
			parent.enable_dust(Vector2(parent.wall_direction()*20,0))
			parent.play_sound(parent.sound_grounded)
			parent.play_anim("wall_slide")
		states.wall_jump:
			parent.disable_dust()
			parent.play_sound(parent.sound_jump)
			parent.play_anim("wall_jump")

func _exit_state(old_state, new_state):
	match old_state:
		states.wall_slide:
			if [states.idle, states.fall].has(new_state):
				parent.siding_left = !parent.siding_left
			
			parent.timer_wallslide_cooldown.start()
		states.wall_jump:
			if [states.idle, states.fall].has(new_state):
				parent.siding_left = !parent.siding_left