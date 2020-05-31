extends KinematicBody2D

const ENEMY_TYPES = {
	"arara": 1, 
	"bode": 2, 
	"cachorro": 2, 
	"crocodilo": 4, 
	"pato": 3, 
	"rato": 2, 
	"rinoceronte": 4, 
	"tigre": 3
}

export (String, "arara", "bode", "cachorro", "crocodilo", "pato", "rato", "rinoceronte", "tigre") var type = "pato" setget setType, getType

const FLOOR_NORMAL = Vector2(0, -2)

const WALK_SPEED = 70
const JUMP_SPEED = 250
const STATE_WALKING = 0
const STATE_KILLED = 1
const SPRITE_SCALE = 2
const DAMAGE = 1

var initial_resistance = 1
var linear_velocity = Vector2()
var direction = 2 if randi() % 2 == 0 else -2
var anim_name=""

var state = STATE_WALKING
var resistance = initial_resistance
var last_position_x = 0
var position_repeated = 0
var chasing = false
var current_speed = WALK_SPEED

onready var GRAVITY_VEC = Vector2(0, global.GRAVITY)

onready var anim = $anim
onready var sprite = $sprite
onready var timer_chasing = $timer_chasing
onready var timer_damage = $timer_damage
onready var timer_flashing = $timer_flashing
onready var detect_floor_left = $detect_floor_left
onready var detect_floor_right = $detect_floor_right
onready var detect_wall_left = $detect_wall_left
onready var detect_wall_right = $detect_wall_right

func _ready():
	reset()
	
func reset():
	initial_resistance = ENEMY_TYPES[type]
	resistance = initial_resistance
	global.update_enemies(1)
	sprite.modulate = Color(1,1,1,1)
	sprite.set_visible(true)

func getType():
	return type

func setType(new_type):
	if new_type:
		$sprite.set_texture(load("res://sprites/enemy_%s.png" % new_type))

func _physics_process(delta):
	if not global.allow_movement: return
	
	var new_anim = "idle"

	if state == STATE_WALKING:
		set_direction(delta)
		new_anim = "walk"
	else:
		new_anim = "explode"

	if anim_name != new_anim:
		anim_name = new_anim
		anim.play(anim_name)
	
	if direction < 0 and not detect_floor_left.is_colliding() and detect_floor_right.is_colliding():
		direction = -direction
	elif direction > 0 and detect_floor_left.is_colliding() and not detect_floor_right.is_colliding():
		direction = -direction
	else:
		if last_position_x == round(global_position.x):
			position_repeated += 1
		
		if position_repeated > 10:
			position_repeated = 0
			last_position_x = 0
			
			if not chasing:
				direction = -direction
				
			current_speed = WALK_SPEED/2
		
		last_position_x = round(global_position.x)

func set_direction(delta=0):
	linear_velocity += GRAVITY_VEC * delta
	linear_velocity.x = direction * current_speed
	linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL, false, 4, PI/4, false)
	sprite.scale = Vector2(-direction, SPRITE_SCALE)

func hit_by_bullet():
	if timer_damage.is_stopped():
		resistance -= 1
		
		if resistance <= 0:
			die()
		else:
			$sound.stream = global.sound_hit
			$sound.play(0)
			timer_damage.start()
			timer_flashing.start()
			linear_velocity.x = -direction * current_speed
			linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL)
			
			chase(global.get_player())

func die():
	state = STATE_KILLED
	linear_velocity.x = 0
	linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL)
	anim.play("explode")
	yield(anim, "animation_finished")
	global.update_enemies(-1)
	global.drop_random_item(self, initial_resistance)
	queue_free()

func _on_damage_area_body_entered(body):
	if ("enemy" in body.get_name()): return
	
	if ("bullet" in body.get_name()):
		hit_by_bullet()
	elif ("player" in body.get_name()):
		var on_left = global_position.x > body.global_position.x
		
		global.get_player().got_damage(DAMAGE, on_left)

func chase(body):
	chasing = true
	timer_chasing.start()
	current_speed = WALK_SPEED
	
	if global_position.x > body.global_position.x:
		direction = -SPRITE_SCALE
	else:
		direction = SPRITE_SCALE
	
	set_direction()

func check_body_chase(body):
	if global.is_player(body):
		if (direction > 0 and global_position.x > body.global_position.x) or (direction < 0 and global_position.x < body.global_position.x):
			return
		
		chase(body)

func _on_timer_chasing_timeout():
	chasing = false

func _on_timer_flashing_timeout():
	if sprite.modulate == Color(1,1,1,1):
		sprite.modulate = Color(1,1,1,0)
	else:
		sprite.modulate = Color(1,1,1,1)

func _on_timer_damage_timeout():
	timer_flashing.stop()
	sprite.modulate = Color(1,1,1,1)
