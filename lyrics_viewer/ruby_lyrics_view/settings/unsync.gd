extends Control


var ruby_lyrics_view : RubyLyricsView
var config : ConfigFile

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func initialize(config_ : ConfigFile,view : RubyLyricsView):
	config = config_
	ruby_lyrics_view = view
	
	%CheckButtonVisble.button_pressed = view.font_unsync_outline_enable
	%ColorPickerUnsyncFill.color = view.font_unsync_color
	%ColorPickerUnsyncStroke.color = view.font_unsync_outline_color
	%CheckButtonAutoScroll.button_pressed = view.unsync_auto_scroll

func _on_check_button_visble_toggled(button_pressed):
	ruby_lyrics_view.font_unsync_outline_enable = button_pressed
	config.set_value("Unsync","outline_enable",button_pressed)

func _on_color_picker_unsync_fill_color_changed(color):
	ruby_lyrics_view.font_unsync_color = color
	config.set_value("Unsync","font_color",color)
	
	pass # Replace with function body.

func _on_color_picker_unsync_stroke_color_changed(color):
	ruby_lyrics_view.font_unsync_outline_color = color
	config.set_value("Unsync","outline_color",color)
	
func _on_check_button_auto_scroll_toggled(button_pressed):
	ruby_lyrics_view.unsync_auto_scroll = button_pressed
	config.set_value("Unsync","auto_scroll",button_pressed)


