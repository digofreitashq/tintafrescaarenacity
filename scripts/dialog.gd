extends Node

var MAX_PHRASE_LENGTH = 120

var text = null
var timer_letter = null
var timer_interaction = null
var waiting_next = false

var phrases = ""
var current_phrase_index = 0
var current_pos = 0

var sound_letter = preload("res://sfx/sound_letter.wav")
var sound_next = preload("res://sfx/sound_next.wav")

func _ready():
	clear()

func clear():
	get_node("dialog_bg").visible = !(true)
	get_node("dialog_brace_left").visible = !(true)
	get_node("dialog_brace_right").visible = !(true)
	get_node("dialog_next").visible = !(true)
	
	text = get_node("text")
	timer_letter = get_node("timer_letter")
	timer_interaction = get_node("timer_interaction")
	
	text.set_text("")

func chunk_message(message):
	var result = []
	var phrase = ""
	var new_phrase = ""
	var words = message.split(" ")
	
	for word in words:
		new_phrase = "%s %s" % [phrase, word]
		
		if (new_phrase.length() < MAX_PHRASE_LENGTH):
			phrase = new_phrase
		else:
			result.append(new_phrase.strip_edges())
			phrase = ""
	
	if (phrase.length()):
		result.append(phrase.strip_edges())
	
	return result

func show(message):
	get_tree().set_pause(true)
	clear()
	
	if (typeof(message) == TYPE_STRING):
		phrases = chunk_message(message)
	else:
		phrases = message
	
	current_phrase_index = 0
	current_pos = 0
	
	get_node("anim").play("open")
	
	timer_interaction.disconnect("timeout",self,"wait_button")
	timer_interaction.connect("timeout",self,"wait_button")
	timer_interaction.set_wait_time(0.3)
	timer_interaction.start()
	
	timer_letter.disconnect("timeout",self,"update_text")
	timer_letter.connect("timeout",self,"update_text")
	timer_letter.set_wait_time(0.1)
	timer_letter.start()

func update_text():
	if (current_phrase_index >= phrases.size()):
		get_node("anim").play("close")
		get_tree().set_pause(false)
		timer_interaction.stop()
		return
	elif (current_pos <= phrases[current_phrase_index].length()):
		current_pos += 1
	elif (current_phrase_index < phrases.size()):
		current_pos = 0
		current_phrase_index += 1
		waiting_next = true
		get_node("anim").play("show_next")
		return
	
	get_node("text").set_text(phrases[current_phrase_index].substr(0,current_pos))
	get_node("sound").stream = sound_letter
	get_node("sound").play(0)
	timer_letter.disconnect("timeout",self,"update_text")
	timer_letter.connect("timeout",self,"update_text")
	timer_letter.set_wait_time(0.05)
	timer_letter.start()

func wait_button():
	var press_start = Input.is_action_pressed("shoot")
	timer_interaction.set_wait_time(0.01)
	
	if (press_start):
		if (waiting_next):
			waiting_next = false
			current_pos = 0
			
			get_node("anim").play("hide_next")
			get_node("sound").stream = sound_next
			get_node("sound").play(0)
			
			timer_interaction.stop()
			timer_interaction.set_wait_time(0.5)
			timer_interaction.start()
			
			timer_letter.disconnect("timeout",self,"update_text")
			timer_letter.connect("timeout",self,"update_text")
			timer_letter.set_wait_time(0.5)
			timer_letter.start()
		else:
			current_pos = phrases[current_phrase_index].length()-1
			get_node("sound").stream = sound_next
			get_node("sound").play(0)
			update_text()
