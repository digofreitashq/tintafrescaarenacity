extends Node2D

var MAX_PHRASE_LENGTH = 120

var text = null
var speaker = null
var timer_letter = null
var timer_interaction = null
var waiting_next = false

var phrases = ""
var current_phrase_index = 0
var current_pos = 0

signal finished

func _ready():
	reset()

func reset():
	self.set_visible(true)
	$dialog_bg.visible = false
	$dialog_brace_left.visible = false
	$dialog_brace_right.visible = false
	$dialog_next.visible = false
	$fire.visible = false
	$skip.visible = false
	
	text = $text
	speaker = $speaker
	timer_letter = $timer_letter
	timer_interaction = $timer_interaction

	text.set_text("")
	speaker.set_text("")

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

func display(messages):
	phrases = messages

	current_phrase_index = 0
	current_pos = 0
	
	global.get_player().skip_dialog = false
	
	global.show_player_ui(false)

	$anim.play("open")
	yield($anim, "animation_finished")

	timer_interaction.set_wait_time(0.3)
	timer_interaction.start()

	timer_letter.set_wait_time(0.1)
	timer_letter.start()

func finish():
	global.get_player().skip_dialog = false
	$anim.play("close")
	yield($anim, "animation_finished")
	timer_interaction.stop()
	$speaker.set_text("")
	$text.set_text("")
	reset()
	emit_signal("finished")
	
	global.show_player_ui()

func update_text():
	if global.get_player().skip_dialog or (current_phrase_index >= phrases.size()):
		finish()
		return
	elif (current_pos <= phrases[current_phrase_index][1].length()):
		current_pos += 1
	elif (current_phrase_index < phrases.size()):
		current_pos = 0
		current_phrase_index += 1
		waiting_next = true
		$anim.play("show_next")
		return
	
	if current_phrase_index < phrases.size():
		speaker.set_text(phrases[current_phrase_index][0])
	
	if phrases[current_phrase_index][1].substr(current_pos,1) == "~":
		timer_letter.set_wait_time(0.5)
	else:
		timer_letter.set_wait_time(0.01)
		$sound.stream = global.sound_letter
		$sound.play()
	
	$text.set_text(phrases[current_phrase_index][1].substr(0,current_pos).replace("~",""))
	
	timer_letter.start()

func wait_button():
	timer_interaction.set_wait_time(0.01)
	
	if Input.is_action_pressed("skip"):
		update_text()
		return

	if Input.is_action_pressed("shoot"):
		if (waiting_next):
			waiting_next = false
			current_pos = 0

			$anim.play("hide_next")
			$sound.stream = global.sound_beep
			$sound.play(0)

			timer_interaction.set_wait_time(0.5)
			timer_interaction.start()

			timer_letter.set_wait_time(0.5)
			timer_letter.start()
		else:
			current_pos = phrases[current_phrase_index][1].length()-1
			$sound.stream = global.sound_next
			$sound.play(0)
			update_text()

func _on_timer_interaction_timeout():
	wait_button()

func _on_timer_letter_timeout():
	update_text()

func _on_button_pressed():
	self.self_modulate = Color(1,1,1,1)

func _on_button_released():
	self.self_modulate = Color(1,1,1,0.5)
