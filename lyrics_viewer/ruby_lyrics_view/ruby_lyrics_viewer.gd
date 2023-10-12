extends I_LyricsViewer

const View := preload("res://lyrics_viewer/ruby_lyrics_view/view/ruby_lyrics_view.tscn")
const Settings := preload("res://lyrics_viewer/ruby_lyrics_view/settings/settings.tscn")

var view : RubyLyricsView
var settings : RubyLyricsViewSettings

func _set_lyrics(lyrics : LyricsContainer) -> bool:
	view.lyrics = lyrics
	view.build()
	return true

func _set_time(time : float) -> void:
	view.set_time_and_target_y(time)
	return


func _set_song_duration(duration : float) -> void:
	view.song_duration = duration

func _set_user_offset(offset : float) -> void:
	view.user_y_offset = int(offset)

func _get_view_size() -> float:
	return view.layout_height

func _initialize(view_parent : Control,settings_parent : Control,config : ConfigFile) -> bool:
	view = View.instantiate()
	view_parent.add_child(view)
	settings = Settings.instantiate()
	settings_parent.add_child(settings)
	initialize_settings(config)
	settings.initialize(config,view)
	return true

func _terminalize() -> void:
	if view:
		view.get_parent().remove_child(view)
		view.queue_free()
		view = null
	if settings:
		settings.get_parent().remove_child(settings)
		settings.queue_free()
		settings = null




func initialize_settings(config : ConfigFile):
	if config.get_value("Font","is_system",true):
		var font := SystemFont.new()
		font.font_names = [config.get_value("Font","system_font","sans-serif")]
		view.font = font
	else:
		view.font = load(config.get_value("Font","font_file",""))
	
	view.font_size = config.get_value("Font","size",32)
	view.font_ruby_size = config.get_value("Font","ruby_size",16)
	view.font_outline_width = config.get_value("Font","outline_width",0)
	view.font_ruby_outline_width = config.get_value("Font","ruby_outline_width",0)
	
	view.font_sleep_color = config.get_value("Font","sleep_color",Color.GRAY)
	view.font_sleep_outline_color = config.get_value("Font","sleep_outline_color",Color.BLACK)
	view.font_active_color = config.get_value("Font","active_color",Color.WHITE)
	view.font_active_outline_color = config.get_value("Font","active_outline_color",Color.RED)
	view.font_standby_color = config.get_value("Font","standby_color",Color.LIGHT_GRAY)
	view.font_standby_outline_color = config.get_value("Font","standby_outline_color",Color.BLUE)
	

	view.alignment_ruby = config.get_value("Adjust","alignment_ruby",0)
	view.alignment_parent = config.get_value("Adjust","alignment_parent",0)
	view.left_padding = config.get_value("Adjust","left_padding",16)
	view.right_padding = config.get_value("Adjust","right_padding",16)
	view.line_height = config.get_value("Adjust","line_height",0)
	view.ruby_distance = config.get_value("Adjust","ruby_distance",0)
	view.no_ruby_space = config.get_value("Adjust","no_ruby_space",0)
	
	view.horizontal_alignment = config.get_value("Display","horizontal_alignment",0)
	view.active_back_color = config.get_value("Display","active_back_color",Color(0,0.25,0,0.25))

	view.fade_in_time = config.get_value("Scroll","fade_in_time",0.5)
	view.fade_out_time = config.get_value("Scroll","fade_out_time",0.5)
	view.scroll_center = config.get_value("Scroll","scroll_center",true)
	view.scrolling = config.get_value("Scroll","scrolling",false)
	
	view.font_unsync_color = config.get_value("Unsync","font_color",Color.WHITE)
	view.font_unsync_outline_color = config.get_value("Unsync","outline_color",Color.BLACK)
	view.font_unsync_outline_enable = config.get_value("Unsync","outline_enable",false)
	view.unsync_auto_scroll = config.get_value("Unsync","auto_scroll",true)
