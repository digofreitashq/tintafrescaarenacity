extends Node2D

export (String, "box", "trampoline") var object = "box"
export (int,1,9,1) var initial_force = 1

onready var drawing = $drawing
onready var counter = $counter
onready var frame_step  = $drawing.hframes

const number_frames = [14,0,1,2,3,4,10,11,12,13]
const object_frames = {
	"box": 20, 
	"trampoline": 21
	}
const object_classes = {
	"box": preload("res://scenes/box.tscn"),
	"trampoline": preload("res://scenes/trampoline.tscn")
	}
const object_nodes = {
	"box": "props/boxes",
	"trampoline": "props/trampolines"
	}

var frame_changed = false
var force = null

func _ready():
	reset()

func reset():
	force = initial_force
	drawing.frame = object_frames[object]
	update_sprite()

func update_sprite():
	counter.frame = number_frames[force]

func _on_timer_frame_timeout():
	if frame_changed:
		drawing.frame = object_frames[object]
		counter.frame = number_frames[force]
	else:
		drawing.frame = object_frames[object] + frame_step
		counter.frame = number_frames[force] + frame_step
	
	frame_changed = !frame_changed

func _on_Area2D_body_entered(body):
	if global.is_bullet(body):
		call_deferred("create_object")

func create_object():
	if force <= 0: return
	
	force -= 1
	
	var new_object = object_classes[object].instance()
	new_object.global_position = global_position
	global.get_stage().get_node(object_nodes[object]).add_child(new_object)
	new_object._ready()
	$sound.stream = global.sound_beep
	$sound.play(0)
	
	update_sprite()
