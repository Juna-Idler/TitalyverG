extends VBoxContainer

class_name HorizontalLayoutSettings

enum Alignment {LEFT = 0,CENTER = 1,RIGHT = 2}
signal horizontal_alignment_changed(alignment : Alignment)

signal left_padding_changed(value : float)
signal right_padding_changed(value : float)

@export var horizontal_alignment : Alignment = Alignment.LEFT :
	set(v):
		horizontal_alignment = v
		if is_node_ready():
			%ButtonLeft.set_pressed_no_signal(false)
			%ButtonCenter.set_pressed_no_signal(false)
			%ButtonRight.set_pressed_no_signal(false)
			match horizontal_alignment:
				Alignment.LEFT:
					%ButtonLeft.set_pressed_no_signal(true)
				Alignment.CENTER:
					%ButtonCenter.set_pressed_no_signal(true)
				Alignment.RIGHT:
					%ButtonRight.set_pressed_no_signal(true)

@export var left_padding : float = 0 :
	set(v):
		left_padding = v
		if is_node_ready():
			%SpinBoxLeft.set_value_no_signal(left_padding)

@export var right_padding : float = 0 :
	set(v):
		right_padding = v
		if is_node_ready():
			%SpinBoxRight.set_value_no_signal(right_padding)


# Called when the node enters the scene tree for the first time.
func _ready():
	%ButtonLeft.set_pressed_no_signal(false)
	%ButtonCenter.set_pressed_no_signal(false)
	%ButtonRight.set_pressed_no_signal(false)
	match horizontal_alignment:
		Alignment.LEFT:
			%ButtonLeft.set_pressed_no_signal(true)
		Alignment.CENTER:
			%ButtonCenter.set_pressed_no_signal(true)
		Alignment.RIGHT:
			%ButtonRight.set_pressed_no_signal(true)
	
	%SpinBoxLeft.set_value_no_signal(left_padding)
	%SpinBoxRight.set_value_no_signal(right_padding)



func _on_button_left_toggled(button_pressed):
	if button_pressed:
		horizontal_alignment = Alignment.LEFT
		horizontal_alignment_changed.emit(Alignment.LEFT)

func _on_button_center_toggled(button_pressed):
	if button_pressed:
		horizontal_alignment_changed.emit(Alignment.CENTER)

func _on_button_right_toggled(button_pressed):
	if button_pressed:
		horizontal_alignment_changed.emit(Alignment.RIGHT)

func _on_spin_box_left_value_changed(value : float):
	left_padding_changed.emit(value)

func _on_spin_box_right_value_changed(value : float):
	right_padding_changed.emit(value)
