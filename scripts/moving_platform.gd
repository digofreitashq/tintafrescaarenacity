extends Node2D

export var motion = Vector2()
export var cycle = 1.0

var original_position = Vector2(0,0)
var accum = 0.0

func _ready():
	reset()

func reset():
	original_position = position

func _physics_process(delta):
	accum += delta * (1.0 / cycle) * TAU
	accum = fmod(accum, TAU)
	
	var d = sin(accum)
	var xf = Transform2D()
	
	xf[2]= motion * d 
	($KinematicBody2D as RigidBody2D).transform = xf
