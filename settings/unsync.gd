extends Control


var ruby_lyrics_view : RubyLyricsView
var settings : Settings


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func initialize(settings_ : Settings,rlv : RubyLyricsView):
	settings = settings_
	ruby_lyrics_view = rlv
	
	%CheckButtonVisble.button_pressed = rlv.font_unsync_outline_enable
	%ColorPickerUnsyncFill.color = rlv.font_unsync_color
	%ColorPickerUnsyncStroke.color = rlv.font_unsync_outline_color
	%CheckButtonAutoScroll.button_pressed = rlv.unsync_auto_scroll

func _on_check_button_visble_toggled(button_pressed):
	ruby_lyrics_view.font_unsync_outline_enable = button_pressed
	settings.config.set_value("Unsync","outline_enable",button_pressed)

func _on_color_picker_unsync_fill_color_changed(color):
	ruby_lyrics_view.font_unsync_color = color
	settings.config.set_value("Unsync","font_color",color)
	
	pass # Replace with function body.

func _on_color_picker_unsync_stroke_color_changed(color):
	ruby_lyrics_view.font_unsync_outline_color = color
	settings.config.set_value("Unsync","outline_color",color)
	
func _on_check_button_auto_scroll_toggled(button_pressed):
	ruby_lyrics_view.unsync_auto_scroll = button_pressed
	settings.config.set_value("Unsync","auto_scroll",button_pressed)


