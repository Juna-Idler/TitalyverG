extends I_LyricsViewer

const View := preload("res://lyrics_viewer/karaoke_wipe_viewer/view/karaoke_wipe_view.tscn")
const Settings := preload("res://lyrics_viewer/karaoke_wipe_viewer/settings/settings.tscn")

var view : KaraokeWipeView = null
var settings : Control = null

func _set_lyrics(lyrics : LyricsContainer) -> bool:
	view.set_lyrics(lyrics)
	return true

func _set_time(time : float) -> void:
	view.set_time(time)

func _set_song_duration(_duration : float) -> void:
	return

func _set_user_offset(offset : float) -> void:
	view.set_user_offset(offset)
	return

func _get_view_size() -> float:
	return view.layout_height

func _set_view_visible(visible : bool):
	view.visible = visible

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
		view.set_font(font)
	else:
		view.set_font(load(config.get_value("Font","font_file","")))
	
	view.parameter.font_size = config.get_value("Font","size",32)
	view.parameter.font_ruby_size = config.get_value("Font","ruby_size",16)
	view.parameter.font_outline_width = config.get_value("Font","outline_width",0)
	view.parameter.font_ruby_outline_width = config.get_value("Font","ruby_outline_width",0)
	
#	view.font_sleep_color = config.get_value("Font","sleep_color",Color.GRAY)
#	view.font_sleep_outline_color = config.get_value("Font","sleep_outline_color",Color.BLACK)
#	view.font_active_color = config.get_value("Font","active_color",Color.WHITE)
#	view.font_active_outline_color = config.get_value("Font","active_outline_color",Color.RED)
#	view.font_standby_color = config.get_value("Font","standby_color",Color.LIGHT_GRAY)
#	view.font_standby_outline_color = config.get_value("Font","standby_outline_color",Color.BLUE)
	

	view.parameter.alignment_ruby = config.get_value("Adjust","alignment_ruby",0)
	view.parameter.alignment_parent = config.get_value("Adjust","alignment_parent",0)
	view.parameter.left_padding = config.get_value("Adjust","left_padding",16)
	view.parameter.right_padding = config.get_value("Adjust","right_padding",16)
	view.parameter.line_height = config.get_value("Adjust","line_height",0)
	view.parameter.ruby_distance = config.get_value("Adjust","ruby_distance",0)
	view.parameter.no_ruby_space = config.get_value("Adjust","no_ruby_space",0)
	
	view.parameter.horizontal_alignment = config.get_value("Display","horizontal_alignment",0)

	view.fade_in_time = config.get_value("Scroll","fade_in_time",0.5)
	view.fade_out_time = config.get_value("Scroll","fade_out_time",0.5)
	view.scroll_center = config.get_value("Scroll","scroll_center",true)
	view.scrolling = config.get_value("Scroll","scrolling",false)
