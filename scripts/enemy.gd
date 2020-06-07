extends KinematicBody2D

const ENEMY_TYPES = {
	"arara": 1, 
	"bode": 2, 
	"cachorro": 2, 
	"crocodilo": 3, 
	"pato": 3, 
	"rato": 2, 
	"rinoceronte": 4, 
	"tigre": 3
}

export (String, "arara", "bode", "cachorro", "crocodilo", "pato", "rato", "rinoceronte", "tigre") var type = "pato" setget setType, getType
export var paused = false
export var chasing = false

const FLOOR_NORMAL = Vector2(0, -1)
const WALK_SPEED = 70
const JUMP_SPEED = 400
const STATE_WALKING = 0
const STATE_KILLED = 1
const SPRITE_SCALE = 2
const DAMAGE = 1
const MIN_ONAIR_TIME= 0.1
const MAX_INITIAL_RESISTANCE = 4

var initial_resistance = 1
var linear_velocity = Vector2()
var direction = global.SIDE[randi() % 2 == 0]
var anim_name=""

var state = STATE_WALKING
var resistance = initial_resistance
var last_position_x = 0
var position_repeated = 0
var current_speed = 0
var onair_time = 0
var onair_counter = 0
var on_floor = false

onready var GRAVITY_VEC = Vector2(0, global.GRAVITY)
onready var player = global.get_player()

onready var anim = $anim
onready var sprite = $sprite
onready var timer_chasing = $timer_chasing
onready var timer_changed_side = $timer_changed_side
onready var timer_damage = $timer_damage
onready var timer_flashing = $timer_flashing
onready var detect_floor_left = $detect_floor_left
onready var detect_floor_right = $detect_floor_right

onready var impact_dust = preload("res://scenes/impact_dust.tscn")

signal seen
signal dead

func _ready():
	reset()
	
func reset():
	initial_resistance = ENEMY_TYPES[type]
	resistance = initial_resistance
	global.update_enemies(1)
	sprite.modulate = Color(1,1,1,1)
	sprite.set_visible(true)
	$name_label.set("text", get_name())
	
	if paused:
		current_speed = 0

func getType():
	return type

func setType(new_type):
	if new_type:
		$sprite.set_texture(load("res://sprites/enemy_%s.png" % new_type))

func _physics_process(delta):
	if paused: return
	
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
		new_anim = "run"
	else:
		new_anim = "explode"

	if anim_name != new_anim:
		anim_name = new_anim
		anim.play(anim_name)
	
	var changed_direction = false
	
	if chasing:
		if player.on_floor and abs(global_position.x - player.global_position.x) > (16 * (MAX_INITIAL_RESISTANCE-initial_resistance)):
			if randi() % 3 == 0:
				direction = global.SIDE[global_position.x > player.global_position.x]
	else:
		current_speed = WALK_SPEED
		
		if not changed_direction:
			for body in $side_area.get_overlapping_bodies():
				if body == self: continue

				if global.is_enemy(body):
					if timer_changed_side.is_stopped():
						timer_changed_side.wait_time = get_random_time()
						timer_changed_side.start()

						if direction:
							direction *= -1
						else:
							direction = global.SIDE[randi() % 2 == 0]

						changed_direction = true

					break
		
		if not changed_direction:
			if direction == global.SIDE_LEFT and not detect_floor_left.is_colliding() and detect_floor_right.is_colliding():
				if timer_changed_side.is_stopped():
					timer_changed_side.wait_time = get_random_time()
					timer_changed_side.start()
					direction = global.SIDE_RIGHT
				else:
					direction = 0
				
				changed_direction = true
			elif direction == global.SIDE_RIGHT and detect_floor_left.is_colliding() and not detect_floor_right.is_colliding():
				if timer_changed_side.is_stopped():
					timer_changed_side.wait_time = get_random_time()
					timer_changed_side.start()
					direction = global.SIDE_LEFT
				else:
					direction = 0
				
				changed_direction = true
		
	if not changed_direction or chasing:
		if last_position_x == round(global_position.x):
			position_repeated += 1
		
		if position_repeated > 10:
			position_repeated = 0
			last_position_x = 0
			
			if timer_changed_side.is_stopped():
				timer_changed_side.wait_time = get_random_time()
				timer_changed_side.start()
				
				if chasing:
					linear_velocity.y = -JUMP_SPEED
				else:
					if detect_floor_left.is_colliding() or detect_floor_right.is_colliding():
						if direction:
							direction *= -1
						else:
							direction = global.SIDE[randi() % 2 == 0]
		
		last_position_x = round(global_position.x)
		
	set_direction(delta)

func set_direction(delta=0):
	if paused: return
	
	linear_velocity += GRAVITY_VEC * delta
	linear_velocity.x = direction * current_speed
	linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL, false, 4, PI/4, false)
	
	if direction:
		sprite.scale = Vector2(-direction * SPRITE_SCALE, SPRITE_SCALE)

func get_random_time():
	var value = randi() % 3
	
	value += (MAX_INITIAL_RESISTANCE-initial_resistance)/2
	
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
			linear_velocity.x = global.SIDE[on_left] * current_speed
		else:
			linear_velocity.x = -direction * current_speed
		
		linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL)
		
		chase(player)

func die():
	state = STATE_KILLED
	linear_velocity.x = 0
	linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL)
	anim.play("explode")
	yield(anim, "animation_finished")
	global.update_enemies(-1)
	global.drop_random_item(self, initial_resistance, Vector2(-8,0))
	global.drop_random_item(self, initial_resistance, Vector2(-8,0))
	emit_signal("dead")
	queue_free()

func _on_damage_area_body_entered(body):
	if paused: return
	
	if ("enemy" in body.get_name()): return
	
	if ("bullet" in body.get_name()):
		body.disable()
		got_damage(1)
	elif ("player" in body.get_name()):
		var on_left = global_position.x > body.global_position.x
		
		player.got_damage(DAMAGE, on_left)

func chase(body):
	if paused: return
	
	if not chasing:
		$sound.stream = global.sound_hit
		$sound.play(0)
		linear_velocity.y = -JUMP_SPEED/2
	
	chasing = true
	timer_chasing.start()
	current_speed = WALK_SPEED * 2
	
	set_direction()

func check_body_chase(body):
	if paused: return
	
	if global.is_player(body):
		if not chasing:
			var visible_direction = global.SIDE[global_position.x > body.global_position.x]
			
			if direction != visible_direction:
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
	if paused: return
	
	if body == self: return
	return
	if global.is_player(body) or global.is_enemy(body):
		linear_velocity.y = -JUMP_SPEED/2
		
		if global.is_player(body):
			body.got_damage(DAMAGE)

func _on_visible_area_body_entered(body):
	if paused: return
	
	if global.is_player(body):
		emit_signal("seen")
