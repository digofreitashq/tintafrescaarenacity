extends KinematicBody2D

export var sprite_texture = "res://sprites/enemy_tigre.png" setget setSpriteTexture, getSpriteTexture

const FLOOR_NORMAL = Vector2(0, -2)

const WALK_SPEED = 70
const STATE_WALKING = 0
const STATE_KILLED = 1

var linear_velocity = Vector2()
var direction = 2 if randi() % 2 == 0 else -2
var anim=""

var state = STATE_WALKING

onready var GRAVITY_VEC = Vector2(0, global.GRAVITY)
onready var detect_floor_left = $detect_floor_left
onready var detect_floor_right = $detect_floor_right
onready var detect_wall_left = $detect_wall_left
onready var detect_wall_right = $detect_wall_right
onready var detect_player_left = $detect_player_left
onready var detect_player_right = $detect_player_right

onready var sound_hit = preload("res://sfx/sound_hit.wav")

func _ready():
	global.get_player().update_enemies(1)

func _die():
	global.get_player().update_enemies(-1)
	queue_free()

func _physics_process(delta):
	var new_anim = "idle"

	if state == STATE_WALKING:
		"""
		if direction == -2.0 and (not detect_floor_left.is_colliding() or detect_wall_left.is_colliding()):
			direction = 2.0
		
		if direction == 2.0 and (not detect_floor_right.is_colliding() or detect_wall_right.is_colliding()):
			direction = -2.0
		"""
		set_direction(delta)
		new_anim = "walk"
	else:
		new_anim = "explode"

	if anim != new_anim:
		anim = new_anim
		$anim.play(anim)

func set_direction(delta=0):
	linear_velocity += GRAVITY_VEC * delta
	linear_velocity.x = direction * WALK_SPEED
	linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL)
	$sprite.scale = Vector2(-direction, 2.0)

func getSpriteTexture():
	return sprite_texture

func setSpriteTexture(newSpriteTexture):
	sprite_texture = newSpriteTexture
	if newSpriteTexture:
		$sprite.set_texture(load(newSpriteTexture))

func hit_by_bullet():
	state = STATE_KILLED
	linear_velocity.x = 0
	linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL)
	$sound.stream = sound_hit
	$sound.play()
	$anim.play("explode")

func _on_damage_area_body_entered(body):
	if ("enemy" in body.get_name()): return
	
	if ("bullet" in body.get_name()):
		hit_by_bullet()
	elif ("player" in body.get_name()):
		var on_left = self.global_position.x > body.global_position.x
		
		global.get_player().got_damage(-1, on_left)

func _on_chase_area_body_entered(body):
	if ("player" in body.get_name()):
		if self.global_position.x > body.global_position.x:
			direction = -2
		else:
			direction = 2
		
		set_direction()
		
