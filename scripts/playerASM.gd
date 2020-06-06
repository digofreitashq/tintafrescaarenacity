extends "res://scripts/StateMachine.gd"

func _ready():
	add_state("none")
	add_state("between")
	add_state("charge")
	add_state("flash")
	add_state("shoot")
	call_deferred("set_state", states.none)

func _enter_state(new_state, _old_state):
	if not global.allow_movement: return
	
	match new_state:
		states.between:
			if global.bullets == 10 or global.sprays >= 1:
				if parent.anim_charging.current_animation != "between":
					parent.anim_charging.play("between")
					return
			else:
				parent.anim_charging.play("stop")
		states.charge:
			if global.bullets == 10 or global.sprays >= 1:
				if parent.anim_charging.current_animation != "charge":
					parent.anim_charging.play("charge")
					return
			else:
				parent.anim_charging.play("stop")
		states.flash:
			if parent.anim_charging.current_animation != "flash":
				parent.anim_charging.play("flash")
				return
		states.shoot:
			parent.timer_shoot.start()
			parent.anim_charging.play("stop")
		states.none:
			parent.anim_charging.play("stop")
			if not parent.player_sm.is_on([parent.player_sm.states.run, parent.player_sm.states.wall_slide]):
				parent.player_sm._enter_state(parent.player_sm.state,parent.player_sm.state)
			return
	
	match parent.player_sm.state:
		parent.player_sm.states.idle:
			parent.play_anim("idle_weapon")
		parent.player_sm.states.run:
			parent.play_anim("run_weapon")
		parent.player_sm.states.grounded_idle:
			parent.play_anim("idle_weapon")
		parent.player_sm.states.grounded_run:
			parent.play_anim("run_weapon")
		parent.player_sm.states.jump:
			parent.play_anim("jump_weapon")
		parent.player_sm.states.fall:
			parent.play_anim("fall_weapon")
		parent.player_sm.states.wall_slide:
			parent.play_anim("wall_slide_weapon")
		parent.player_sm.states.wall_jump:
			parent.play_anim("fall_weapon")
