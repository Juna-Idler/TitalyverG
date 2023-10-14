extends Control


var ruby_lyrics_view : RubyLyricsView
var config : ConfigFile

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func initialize(config_ : ConfigFile,view : RubyLyricsView):
	config = config_
	ruby_lyrics_view = view
	
	%FontSelector.system_font_name = config.get_value("Font","system_font","sans-serif")
	%FontSelector.font_file_path = config.get_value("Font","font_file","")
	%FontSelector.is_system = config.get_value("Font","is_system",false)

	
	%SpinBoxRubySize.value = view.font_ruby_size
	%SpinBoxRubyOutline.value = view.font_ruby_outline_width
	%SpinBoxBaseSize.value = view.font_size
	%SpinBoxBaseOutline.value = view.font_outline_width
	
	
	%ColorPickerActiveFill.color = view.font_active_color
	%ColorPickerStandbyFill.color = view.font_standby_color
	%ColorPickerSleepFill.color = view.font_sleep_color
	
	%ColorPickerActiveStroke.color = view.font_active_outline_color
	%ColorPickerStandbyStroke.color = view.font_standby_outline_color
	%ColorPickerSleepStroke.color = view.font_sleep_outline_color
	
	%ColorPickerActiveBack.color = view.active_back_color
	
	%ColorPickerBackground.color = config.get_value("Window","background_color",Color(0,0,0,0.8))
	
	match view.horizontal_alignment:
		RubyLyricsView.HorizontalAlignment.LEFT:
			%ButtonLeft.button_pressed = true
		RubyLyricsView.HorizontalAlignment.CENTER:
			%ButtonCenter.button_pressed = true
		RubyLyricsView.HorizontalAlignment.RIGHT:
			%ButtonRight.button_pressed = true

	%SpinBoxLeft.value = view.left_padding
	%SpinBoxRight.value = view.right_padding

	%SpinBoxLineHeight.value = view.line_height
	%SpinBoxRubyDistance.value = view.ruby_distance
	%SpinBoxNoRubySpace.value = view.no_ruby_space

	%CheckButtonScrollCenter.button_pressed = view.scroll_center
	%CheckButtonScrollContinuous.button_pressed = view.scrolling
	
	%SpinBoxFadeIn.value = view.fade_in_time
	%SpinBoxFadeOut.value = view.fade_out_time




func _on_spin_box_ruby_size_value_changed(value):
	ruby_lyrics_view.font_ruby_size = value
	config.set_value("Font","ruby_size",value)

func _on_spin_box_base_size_value_changed(value):
	ruby_lyrics_view.font_size = value
	config.set_value("Font","size",value)

func _on_spin_box_ruby_outline_value_changed(value):
	ruby_lyrics_view.font_ruby_outline_width = value
	config.set_value("Font","ruby_outline_width",value)

func _on_spin_box_base_outline_value_changed(value):
	ruby_lyrics_view.font_outline_width = value
	config.set_value("Font","outline_width",value)


func _on_color_picker_active_fill_color_changed(color):
	ruby_lyrics_view.font_active_color = color
	config.set_value("Font","active_color",color)

func _on_color_picker_standby_fill_color_changed(color):
	ruby_lyrics_view.font_standby_color = color
	config.set_value("Font","standby_color",color)

func _on_color_picker_sleep_fill_color_changed(color):
	ruby_lyrics_view.font_sleep_color = color
	config.set_value("Font","sleep_color",color)

func _on_color_picker_active_stroke_color_changed(color):
	ruby_lyrics_view.font_active_outline_color = color
	config.set_value("Font","active_outline_color",color)

func _on_color_picker_standby_stroke_color_changed(color):
	ruby_lyrics_view.font_standby_outline_color = color
	config.set_value("Font","standby_outline_color",color)

func _on_color_picker_sleep_stroke_color_changed(color):
	ruby_lyrics_view.font_sleep_outline_color = color
	config.set_value("Font","sleep_outline_color",color)

func _on_color_picker_active_back_color_changed(color):
	ruby_lyrics_view.active_back_color = color
	config.set_value("Display","active_back_color",color)

func _on_color_picker_background_color_changed(color):
	config.set_value("Window","background_color",color)
	ruby_lyrics_view
#	background_color_changed.emit(color)


func _on_button_left_toggled(button_pressed):
	if button_pressed:
		ruby_lyrics_view.horizontal_alignment = RubyLyricsView.HorizontalAlignment.LEFT
		config.set_value("Display","horizontal_alignment",int(RubyLyricsView.HorizontalAlignment.LEFT))

func _on_button_center_toggled(button_pressed):
	if button_pressed:
		ruby_lyrics_view.horizontal_alignment = RubyLyricsView.HorizontalAlignment.CENTER
		config.set_value("Display","horizontal_alignment",int(RubyLyricsView.HorizontalAlignment.CENTER))

func _on_button_right_toggled(button_pressed):
	if button_pressed:
		ruby_lyrics_view.horizontal_alignment = RubyLyricsView.HorizontalAlignment.RIGHT
		config.set_value("Display","horizontal_alignment",int(RubyLyricsView.HorizontalAlignment.RIGHT))


func _on_spin_box_left_value_changed(value):
	ruby_lyrics_view.left_padding = value
	config.set_value("Adjust","left_padding",value)

func _on_spin_box_right_value_changed(value):
	ruby_lyrics_view.right_padding = value
	config.get_value("Adjust","right_padding",value)


func _on_spin_box_line_height_value_changed(value):
	ruby_lyrics_view.line_height = value
	config.set_value("Adjust","line_height",value)

func _on_spin_box_ruby_distance_value_changed(value):
	ruby_lyrics_view.ruby_distance = value
	config.set_value("Adjust","ruby_distance",value)

func _on_spin_box_no_ruby_space_value_changed(value):
	ruby_lyrics_view.no_ruby_space = value
	config.set_value("Adjust","no_ruby_space",value)


func _on_check_button_scroll_center_toggled(button_pressed):
	ruby_lyrics_view.scroll_center = button_pressed
	config.set_value("Scroll","scroll_center",button_pressed)

func _on_check_button_scroll_continuous_toggled(button_pressed):
	ruby_lyrics_view.scrolling = button_pressed
	config.get_value("Scroll","scrolling",button_pressed)

func _on_spin_box_fade_in_value_changed(value):
	ruby_lyrics_view.fade_in_time = value
	config.set_value("Scroll","fade_in_time",value)

func _on_spin_box_fade_out_value_changed(value):
	ruby_lyrics_view.fade_out_time = value
	config.set_value("Scroll","fade_out_time",value)




func _on_font_selector_font_changed(font : Font):
	ruby_lyrics_view.font = font


func _on_font_selector_font_switched(system : bool):
	config.set_value("Font","is_system",system)

func _on_font_selector_system_font_changed(font_names):
	config.set_value("Font","system_font",font_names[0])

func _on_font_selector_file_font_changed(font_path):
	config.set_value("Font","font_file",font_path)


