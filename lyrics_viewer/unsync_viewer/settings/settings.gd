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

	%HorizontalLayout.horizontal_alignment = unsync_view.horizontal_alignment as HorizontalLayoutSettings.Alignment
	%HorizontalLayout.left_padding = unsync_view.left_padding
	%HorizontalLayout.right_padding = unsync_view.right_padding
	
	%LineHeightAdjust.line_height = unsync_view.line_height
	%LineHeightAdjust.ruby_distance = unsync_view.ruby_distance
	%LineHeightAdjust.no_ruby_space = unsync_view.no_ruby_space


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



func _on_horizontal_layout_horizontal_alignment_changed(alignment):
	var enum_number : int = alignment
	unsync_view.horizontal_alignment = enum_number as UnsyncView.HorizontalAlignment
	config.set_value("Unsync","horizontal_alignment",enum_number)

func _on_horizontal_layout_left_padding_changed(value):
	unsync_view.left_padding = value
	config.set_value("Unsync","left_padding",value)

func _on_horizontal_layout_right_padding_changed(value):
	unsync_view.right_padding = value
	config.set_value("Unsync","right_padding",value)


func _on_line_height_adjust_line_height_changed(value):
	unsync_view.line_height = value
	config.set_value("Unsync","line_height",value)

func _on_line_height_adjust_ruby_distance_changed(value):
	unsync_view.ruby_distance = value
	config.set_value("Unsync","ruby_distance",value)
	
func _on_line_height_adjust_no_ruby_space_changed(value):
	unsync_view.no_ruby_space = value
	config.set_value("Unsync","no_ruby_space",value)
