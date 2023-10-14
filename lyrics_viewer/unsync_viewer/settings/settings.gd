extends Control


var unsync_view : UnsyncView
var config : ConfigFile

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func initialize(config_ : ConfigFile,view : UnsyncView):
	config = config_
	unsync_view = view

	%FontSelector.system_font_name = config.get_value("Unsync","system_font","sans-serif")
	%FontSelector.font_file_path = config.get_value("Unsync","font_file","")
	%FontSelector.is_system = config.get_value("Unsync","is_system_font",true)
	
	%ColorPickerUnsyncFill.color = view.font_color
	%ColorPickerUnsyncStroke.color = view.font_outline_color
	%CheckButtonAutoScroll.button_pressed = view.unsync_auto_scroll



func _on_color_picker_unsync_fill_color_changed(color):
	unsync_view.font_color = color
	config.set_value("Unsync","font_color",color)
	

func _on_color_picker_unsync_stroke_color_changed(color):
	unsync_view.font_outline_color = color
	config.set_value("Unsync","font_outline_color",color)
	
func _on_check_button_auto_scroll_toggled(button_pressed):
	unsync_view.unsync_auto_scroll = button_pressed
	config.set_value("Unsync","auto_scroll",button_pressed)




func _on_font_selector_file_font_changed(font_path):
	config.set_value("Unsync","font_file",font_path)

func _on_font_selector_font_changed(font):
	unsync_view.font = font

func _on_font_selector_font_switched(system):
	config.set_value("Unsync","is_system_font",system)

func _on_font_selector_system_font_changed(font_names):
	config.set_value("Unsync","system_font",font_names[0])
	

func _on_spin_box_ruby_size_value_changed(value):
	unsync_view.font_ruby_size = value
	config.set_value("Unsync","font_ruby_size",value)

func _on_spin_box_base_size_value_changed(value):
	unsync_view.font_size = value
	config.set_value("Unsync","font_size",value)

func _on_spin_box_ruby_outline_value_changed(value):
	unsync_view.font_ruby_outline_width = value
	config.set_value("Unsync","font_ruby_outline_width",value)

func _on_spin_box_base_outline_value_changed(value):
	unsync_view.font_outline_width = value
	config.set_value("Unsync","font_outline_width",value)

