extends KinematicBody2D

export var sprite_texture = "res://sprites/enemy_tigre.png" setget setSpriteTexture, getSpriteTexture

const GRAVITY_VEC = Vector2(0, 900)
const FLOOR_NORMAL = Vector2(0, -2)

const WALK_SPEED = 70
const STATE_WALKING = 0
const STATE_KILLED = 1

var linear_velocity = Vector2()
var direction = -2
var anim=""

var state = STATE_WALKING

onready var detect_floor_left = $detect_floor_left
onready var detect_wall_left = $detect_wall_left
onready var detect_floor_right = $detect_floor_right
onready var detect_wall_right = $detect_wall_right

func _ready():
	get_tree().get_current_scene().get_node("player").update_enemies(1)

func _physics_process(delta):
	var new_anim = "idle"

	if state==STATE_WALKING:
		linear_velocity += GRAVITY_VEC * delta
		linear_velocity.x = direction * WALK_SPEED
		linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL)

		if not detect_floor_left.is_colliding() or detect_wall_left.is_colliding():
			direction = 2.0

		if not detect_floor_right.is_colliding() or detect_wall_right.is_colliding():
			direction = -2.0

		$sprite.scale = Vector2(direction, 2.0)
		new_anim = "walk"
	else:
		new_anim = "explode"

	if anim != new_anim:
		anim = new_anim
		$anim.play(anim)

func getSpriteTexture():
	return sprite_texture

func setSpriteTexture(newSpriteTexture):
	sprite_texture = newSpriteTexture
	if newSpriteTexture:
		get_node("sprite").set_texture(load(newSpriteTexture))

func hit_by_bullet():
	state = STATE_KILLED
	linear_velocity.x = 0
	linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL)
	get_node("anim").play("explode")
	return

	
	get_tree().get_current_scene().get_node("player").update_enemies(-1)

