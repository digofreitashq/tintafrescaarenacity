extends "res://scripts/StateMachine.gd"

func _ready():
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("fall")
	add_state("push")
	add_state("wall_slide")
	add_state("wall_jump")
	add_state("damage")
	call_deferred("set_state", states.idle)

func _state_logic(delta):
	if !parent.is_on_floor():
		parent.onair_time += delta
	else:
		parent.onair_time = 0
	
	parent.shoot_time += delta
	
	parent._handle_move_input()
	parent._apply_gravity(delta)
	parent._apply_movement(delta)
	
	if state == states.wall_slide:
		parent._gravity_wall_slide()
	
	parent.update_state_label()

func _get_transition(delta):
	var wall_direction = parent.wall_direction()
	var valid_wall_direction = (wall_direction == -1 and Input.is_action_pressed("move_left")) or (wall_direction == 1 and Input.is_action_pressed("move_right"))
	var wall_slide_conditions = parent.knows_walljump and parent.linear_vel.y >= 0 and valid_wall_direction
	var push_conditions = round(parent.linear_vel.x) != 0 and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"))
	
	match state:
		states.idle:
			if not parent.on_floor:
				if parent.linear_vel.y < 0:
					return states.jump
				elif round(parent.linear_vel.y) > 0:
					return states.fall
			elif push_conditions:
				var push_direction = parent.push_direction()
				if (parent.siding_left and push_direction == -1) or (not parent.siding_left and push_direction == 1):
					return states.push
				
				return states.run
		states.run:
			if not parent.on_floor:
				if parent.linear_vel.y < 0:
					return states.jump
				elif round(parent.linear_vel.y) > 0:
					return states.fall
			elif push_conditions:
				var push_direction = parent.push_direction()
				if (parent.siding_left and push_direction == -1) or (not parent.siding_left and push_direction == 1):
					return states.push
			elif not push_conditions:
				return states.idle
			elif parent.linear_vel.x != 0 and wall_direction != 0:
				if (parent.siding_left and wall_direction == -1) or (not parent.siding_left and wall_direction == 1):
					return states.idle
		states.jump:
			if parent.on_floor:
				return states.idle
			elif parent.linear_vel.y >= 0:
				return states.fall
		states.fall:
			if parent.on_floor:
				if push_conditions:
					var push_direction = parent.push_direction()
					if (parent.siding_left and push_direction == -1) or (not parent.siding_left and push_direction == 1):
						return states.push
					
					return states.run
				
				return states.idle
			elif wall_slide_conditions:
				parent.siding_left = wall_direction == -1
				return states.wall_slide
			elif parent.linear_vel.y < 0:
				return states.jump
		states.push:
			if not parent.on_floor:
				if parent.linear_vel.y < 0:
					return states.jump
				elif round(parent.linear_vel.y) > 0:
					return states.fall
			
			if round(parent.linear_vel.x) == 0:
				return states.idle
		states.wall_slide:
			if parent.on_floor:
				return states.idle
			elif parent.linear_vel.y >= 0 and wall_direction == 0:
				return states.fall
		states.wall_jump:
			if parent.on_floor:
				return states.idle
			elif wall_slide_conditions:
				parent.siding_left = wall_direction == -1
				return states.wall_slide
			elif parent.linear_vel.y >= 0:
				return states.fall
		states.damage:
			if parent.on_floor:
				return states.idle
			elif wall_slide_conditions:
				parent.siding_left = wall_direction == -1
				return states.wall_slide
	
	return null

func _enter_state(new_state, old_state):
	match new_state:
		states.idle:
			parent.disable_dust()
			if old_state in [states.fall, states.wall_jump, states.wall_slide]:
				parent.play_anim("grounded")
			else:
				parent.play_anim("idle")
		states.run:
			parent.disable_dust()
			parent.play_anim("run")
		states.jump:
			if old_state == states.damage: return
			parent.on_floor = false
			parent.disable_dust()
			#parent.play_anim("jump")
		states.fall:
			if old_state == states.damage: return
			parent.disable_dust()
			parent.play_anim("fall")
		states.push:
			parent.disable_dust()
			parent.play_sound(parent.sound_grounded)
			parent.play_anim("push")
		states.wall_slide:
			parent.on_floor = false
			parent.enable_dust(Vector2(parent.wall_direction()*20,0))
			parent.play_sound(parent.sound_grounded)
			parent.play_anim("wall_slide")
		states.wall_jump:
			parent.on_floor = false
			parent.disable_dust()
			parent.play_sound(parent.sound_jump)
			parent.play_anim("wall_jump")
		states.damage:
			parent.on_floor = false
			parent.disable_dust()
			parent.play_sound(parent.sound_damage)
			parent.play_anim("damage")

func _exit_state(old_state, new_state):
	match old_state:
		states.wall_slide:
			if [states.idle, states.fall].has(new_state):
				parent.siding_left = !parent.siding_left
