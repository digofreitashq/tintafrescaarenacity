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
const JUMP_SPEED = 400
const STATE_WALKING = 0
const STATE_KILLED = 1
const SPRITE_SCALE = 2
const DAMAGE = 1
const MIN_ONAIR_TIME= 0.1

var initial_resistance = 1
var linear_velocity = Vector2()
var direction = global.SIDE_LEFT if randi() % 2 == 0 else global.SIDE_RIGHT
var anim_name=""

var state = STATE_WALKING
var resistance = initial_resistance
var last_position_x = 0
var position_repeated = 0
var chasing = false
var current_speed = WALK_SPEED
var onair_time = 0
var onair_counter = 0
var on_floor = false

onready var GRAVITY_VEC = Vector2(0, global.GRAVITY)

onready var anim = $anim
onready var sprite = $sprite
onready var timer_chasing = $timer_chasing
onready var timer_changed_side = $timer_changed_side
onready var timer_damage = $timer_damage
onready var timer_flashing = $timer_flashing
onready var detect_floor_left = $detect_floor_left
onready var detect_floor_right = $detect_floor_right
onready var detect_wall_left = $detect_wall_left
onready var detect_wall_right = $detect_wall_right

onready var impact_dust = preload("res://scenes/impact_dust.tscn")

func _ready():
	reset()
	
func reset():
	initial_resistance = ENEMY_TYPES[type]
	resistance = initial_resistance
	global.update_enemies(1)
	sprite.modulate = Color(1,1,1,1)
	sprite.set_visible(true)
	$name_label.set("text", get_name())

func getType():
	return type

func setType(new_type):
	if new_type:
		$sprite.set_texture(load("res://sprites/enemy_%s.png" % new_type))

func _physics_process(delta):
	if not global.allow_movement: return
	
	onair_time += delta
	onair_counter += delta
	
	if linear_velocity.y == 0 and not on_floor:
		on_floor = true
		
		if onair_counter > 0.2:
			var new_impact_dust = impact_dust.instance()
			new_impact_dust.position = Vector2(global_position.x, global_position.y+42)
			new_impact_dust.z_index = z_index + 1
			global.get_stage().add_child(new_impact_dust)
			new_impact_dust._ready()
		
		onair_counter = 0
	else:
		on_floor = false
	
	var new_anim = "idle"

	if state == STATE_WALKING:
		new_anim = "walk"
	else:
		new_anim = "explode"

	if anim_name != new_anim:
		anim_name = new_anim
		anim.play(anim_name)
	
	if not chasing and direction == global.SIDE_LEFT and not detect_floor_left.is_colliding() and detect_floor_right.is_colliding():
		print(get_name(),' ','changed1')
		if timer_changed_side.is_stopped():
			direction = global.SIDE_RIGHT
			timer_changed_side.wait_time = get_random_time()
			timer_changed_side.start()
		else:
			direction == 0
		
	elif not chasing and direction == global.SIDE_RIGHT and detect_floor_left.is_colliding() and not detect_floor_right.is_colliding():
		print(get_name(),' ','changed2')
		if timer_changed_side.is_stopped():
			direction = global.SIDE_LEFT
			timer_changed_side.wait_time = get_random_time()
			timer_changed_side.start()
		else:
			direction == 0

	elif last_position_x == round(global_position.x):
		position_repeated += 1
	
		if position_repeated > 10:
			position_repeated = 0
			last_position_x = 0
			
			if not chasing:
				if timer_changed_side.is_stopped():
					timer_changed_side.wait_time = get_random_time()
					timer_changed_side.start()
					
					if detect_floor_left.is_colliding() or detect_floor_right.is_colliding():
						if direction:
							print(get_name(),' ','changed3')
							direction *= -1
						else:
							print(get_name(),' ','changed4')
							direction = global.SIDE_LEFT if randi() % 2 == 0 else global.SIDE_RIGHT
				
				current_speed = WALK_SPEED
			else:
				if timer_changed_side.is_stopped():
					timer_changed_side.wait_time = get_random_time()
					timer_changed_side.start()
					linear_velocity.y = -JUMP_SPEED
		
		last_position_x = round(global_position.x)
	
	set_direction()

func set_direction(delta=0):
	linear_velocity += GRAVITY_VEC * delta
	linear_velocity.x = direction * current_speed
	linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL, false, 4, PI/4, false)
	
	if direction:
		sprite.scale = Vector2(-direction * SPRITE_SCALE, SPRITE_SCALE)

func get_random_time():
	var value = randi() % 3
	
	if value < 1:
		value = 1
	
	return value

func got_damage(value, on_top=false, on_left=null):
	resistance -= value
	
	if resistance <= 0:
		die()
	else:
		$sound.stream = global.sound_hit
		$sound.play(0)
		timer_damage.start()
		timer_flashing.start()
		
		if on_top:
			linear_velocity.y = -JUMP_SPEED
		
		if on_left != null:
			linear_velocity.x = (global.SIDE_LEFT if on_left else global.SIDE_RIGHT) * current_speed
		else:
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
	global.drop_random_item(self, initial_resistance, Vector2(-8,0))
	global.drop_random_item(self, initial_resistance, Vector2(-8,0))
	queue_free()

func _on_damage_area_body_entered(body):
	if ("enemy" in body.get_name()): return
	
	if ("bullet" in body.get_name()):
		body.disable()
		got_damage(1)
	elif ("player" in body.get_name()):
		var on_left = global_position.x > body.global_position.x
		
		global.get_player().got_damage(DAMAGE, on_left)

func chase(body):
	if not chasing:
		linear_velocity.y = -JUMP_SPEED/2
		$sound.stream = global.sound_hit
		$sound.play(0)
	
	chasing = true
	timer_chasing.start()
	current_speed = WALK_SPEED * 2
	
	if body.on_floor:
		if timer_changed_side.is_stopped():
			timer_changed_side.wait_time = get_random_time()
			timer_changed_side.start()
			
			if global_position.x > body.global_position.x:
				direction = global.SIDE_LEFT
			else:
				direction = global.SIDE_RIGHT

func check_body_chase(body):
	if global.is_player(body):
		if not chasing:
			if (direction == global.SIDE_RIGHT and global_position.x > body.global_position.x) or (direction == global.SIDE_LEFT and global_position.x < body.global_position.x):
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

func check_kinematic_below(body):
	if body == self: return
	
	if global.is_player(body) or global.is_enemy(body):
		linear_velocity.y = -JUMP_SPEED
		
		if global.is_player(body):
			body.got_damage(DAMAGE)

func _on_timer_check_side_area_timeout():
	for body in $side_area.get_overlapping_bodies():
		if global.is_enemy(body):
			if timer_changed_side.is_stopped():
				timer_changed_side.wait_time = get_random_time()
				timer_changed_side.start()
				
				if direction:
					direction *= -1
				else:
					direction = global.SIDE_LEFT if randi() % 2 == 0 else global.SIDE_RIGHT
