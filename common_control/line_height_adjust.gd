extends HBoxContainer

class_name LineHeightAdjust

signal line_height_changed(value : float)
signal ruby_distance_changed(value : float)
signal no_ruby_space_changed(value : float)

@export var line_height : float :
	set(v):
		line_height = v
		if is_node_ready():
			%SpinBoxLineHeight.set_value_no_signal(v)

@export var ruby_distance : float :
	set(v):
		ruby_distance = v
		if is_node_ready():
			%SpinBoxRubyDistance.set_value_no_signal(v)

@export var no_ruby_space : float :
	set(v):
		no_ruby_space = v
		if is_node_ready():
			%SpinBoxNoRubySpace.set_value_no_signal(v)

func _ready():
	%SpinBoxLineHeight.set_value_no_signal(line_height)
	%SpinBoxRubyDistance.set_value_no_signal(ruby_distance)
	%SpinBoxNoRubySpace.set_value_no_signal(no_ruby_space)


func _on_spin_box_line_height_value_changed(value):
	line_height_changed.emit(value)

func _on_spin_box_ruby_distance_value_changed(value):
	ruby_distance_changed.emit(value)

func _on_spin_box_no_ruby_space_value_changed(value):
	no_ruby_space_changed.emit(value)

