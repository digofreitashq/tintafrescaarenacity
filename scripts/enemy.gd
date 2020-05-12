extends KinematicBody2D

export var sprite_texture = "cachorro" setget setSpriteTexture, getSpriteTexture
export var resistance = 2

const FLOOR_NORMAL = Vector2(0, -2)

const WALK_SPEED = 70
const STATE_WALKING = 0
const STATE_KILLED = 1

const DAMAGE = 1

var linear_velocity = Vector2()
var direction = 2 if randi() % 2 == 0 else -2
var anim=""

var state = STATE_WALKING
var health = resistance

onready var GRAVITY_VEC = Vector2(0, global.GRAVITY)
onready var detect_floor_left = $detect_floor_left
onready var detect_floor_right = $detect_floor_right
onready var detect_wall_left = $detect_wall_left
onready var detect_wall_right = $detect_wall_right

func _ready():
	reset()
	
func reset():
	health = resistance
	global.update_enemies(1)
	$sprite.modulate = Color(1,1,1,1)
	$sprite.set_visible(true)

func die():
	global.update_enemies(-1)
	global.drop_item(self, resistance)
	queue_free()

func _physics_process(delta):
	if not global.allow_movement: return
	
	var new_anim = "idle"

	if state == STATE_WALKING:
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
		$sprite.set_texture(load("res://sprites/enemy_%s.png" % newSpriteTexture))

func hit_by_bullet():
	state = STATE_KILLED
	linear_velocity.x = 0
	linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL)
	$anim.play("explode")
	yield($anim, "animation_finished")
	die()

func _on_damage_area_body_entered(body):
	if ("enemy" in body.get_name()): return
	
	if ("bullet" in body.get_name()):
		hit_by_bullet()
	elif ("player" in body.get_name()):
		var on_left = self.global_position.x > body.global_position.x
		
		global.get_player().got_damage(DAMAGE, on_left)

func _on_chase_area_body_entered(body):
	if ("player" in body.get_name()):
		if self.global_position.x > body.global_position.x:
			direction = -2
		else:
			direction = 2
		
		set_direction()
		
