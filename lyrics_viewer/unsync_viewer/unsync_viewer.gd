extends I_LyricsViewer

const View := preload("res://lyrics_viewer/unsync_viewer/view/unsync_view.tscn")
const Settings := preload("res://lyrics_viewer/unsync_viewer/settings/settings.tscn")

var view : Control
var settings : Control

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
	if config.get_value("Unsync","is_system_font",true):
		var font := SystemFont.new()
		font.font_names = [config.get_value("Unsync","system_font","sans-serif")]
		view.font = font
	else:
		view.font = load(config.get_value("Unsync","font_file",""))
	
	view.font_size = config.get_value("Unsync","font_size",32)
	view.font_ruby_size = config.get_value("Unsync","font_ruby_size",16)
	view.font_outline_width = config.get_value("Unsync","font_outline_width",0)
	view.font_ruby_outline_width = config.get_value("Unsync","font_ruby_outline_width",0)
	
	view.font_color = config.get_value("Unsync","font_color",Color.GRAY)
	view.font_outline_color = config.get_value("Unsync","font_outline_color",Color.BLACK)

	view.alignment_ruby = config.get_value("Unsync","alignment_ruby",0)
	view.alignment_parent = config.get_value("Unsync","alignment_parent",0)
	view.left_padding = config.get_value("Unsync","left_padding",16)
	view.right_padding = config.get_value("Unsync","right_padding",16)
	view.line_height = config.get_value("Unsync","line_height",0)
	view.ruby_distance = config.get_value("Unsync","ruby_distance",0)
	view.no_ruby_space = config.get_value("Unsync","no_ruby_space",0)
	
	view.horizontal_alignment = config.get_value("Unsync","horizontal_alignment",0)
	view.unsync_auto_scroll = config.get_value("Unsync","auto_scroll",true)

