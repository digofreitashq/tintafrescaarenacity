
extends RigidBody2D

export(ImageTexture) var sprite setget setSprite, getSprite

# Member variables
const STATE_WALKING = 0
const STATE_DYING = 1

var state = STATE_WALKING

var direction = -2
var anim = ""

var rc_left = null
var rc_right = null
var WALK_SPEED = 80

var bullet_class = preload("res://scripts/bullet.gd")

func getSprite():
	return sprite

func setSprite(newSprite):
	sprite = newSprite
	if (sprite):
		get_node("sprite").set_texture(sprite)

func _die():
	get_tree().get_current_scene().get_node("player").update_enemies(-1)
	clear_shapes()
	queue_free()

func _integrate_forces(s):
	if (state == STATE_DYING):
		return
	
	var lv = s.get_linear_velocity()
	
	if (state == STATE_WALKING):
		var wall_side = 0.0
		
		for i in range(s.get_contact_count()):
			var cc = s.get_contact_collider_object(i)
			var dp = s.get_contact_local_normal(i)
			
			if (cc):
				if (cc extends bullet_class and not cc.disabled):
					set_mode(MODE_STATIC)
					state = STATE_DYING
					s.set_angular_velocity(0)
					set_friction(1)
					s.set_linear_velocity(Vector2(0,0))
					get_node("anim").play("explode")
					return
			
			if (dp.x > 0.9):
				wall_side = 2.0
			elif (dp.x < -0.9):
				wall_side = -2.0
		
		if (wall_side != 0 and wall_side != direction):
			direction = -direction
			get_node("sprite").set_scale(Vector2(-direction, 2))
		
		if (direction < 0 and not rc_left.is_colliding() and rc_right.is_colliding()):
			direction = -direction
			get_node("sprite").set_scale(Vector2(-direction, 2))
		elif (direction > 0 and not rc_right.is_colliding() and rc_left.is_colliding()):
			direction = -direction
			get_node("sprite").set_scale(Vector2(-direction, 2))
		
		lv.x += direction*WALK_SPEED
		
		if (direction < 0 and lv.x < WALK_SPEED):
			lv.x = -WALK_SPEED
		elif (direction > 0 and lv.x > WALK_SPEED):
			lv.x = WALK_SPEED
	
	s.set_linear_velocity(lv)

func _ready():
	get_node("anim").play("walk")
	
	rc_left = get_node("raycast_left")
	rc_right = get_node("raycast_right")
	
	get_tree().get_current_scene().get_node("player").update_enemies(1)
