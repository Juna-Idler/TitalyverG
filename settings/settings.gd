
class_name Settings

const CONFIG_FILE_PATH := "user://settings.cfg"

var config : ConfigFile = ConfigFile.new()


func load_settings() -> bool:
	if config.load(CONFIG_FILE_PATH) != OK:
		return false
	return true

func save_settings():
	config.save(CONFIG_FILE_PATH)
	
func initialize_ruby_lyrics_view_settings(rlv : RubyLyricsView):
	if config.get_value("Font","is_system",true):
		var font := SystemFont.new()
		font.font_names = [config.get_value("Font","system_font","sans-serif")]
		rlv.font = font
	else:
		rlv.font = load(config.get_value("Font","font_file",""))
	
	rlv.font_size = config.get_value("Font","size",32)
	rlv.font_ruby_size = config.get_value("Font","ruby_size",16)
	rlv.font_outline_width = config.get_value("Font","outline_width",0)
	rlv.font_ruby_outline_width = config.get_value("Font","ruby_outline_width",0)
	
	rlv.font_sleep_color = config.get_value("Font","sleep_color",Color.GRAY)
	rlv.font_sleep_outline_color = config.get_value("Font","sleep_outline_color",Color.BLACK)
	rlv.font_active_color = config.get_value("Font","active_color",Color.WHITE)
	rlv.font_active_outline_color = config.get_value("Font","active_outline_color",Color.RED)
	rlv.font_standby_color = config.get_value("Font","standby_color",Color.LIGHT_GRAY)
	rlv.font_standby_outline_color = config.get_value("Font","standby_outline_color",Color.BLUE)
	
	rlv.alignment_ruby = config.get_value("Adjust","alignment_ruby",0)
	rlv.alignment_parent = config.get_value("Adjust","alignment_parent",0)
	rlv.left_padding = config.get_value("Adjust","left_padding",16)
	rlv.right_padding = config.get_value("Adjust","right_padding",16)
	rlv.line_height = config.get_value("Adjust","line_height",0)
	rlv.ruby_distance = config.get_value("Adjust","ruby_distance",0)
	rlv.no_ruby_space = config.get_value("Adjust","no_ruby_space",0)
	
	rlv.horizontal_alignment = config.get_value("Display","horizontal_alignment",0)
	rlv.active_back_color = config.get_value("Display","active_back_color",Color(0,0.25,0,0.25))

	rlv.fade_in_time = config.get_value("Scroll","fade_in_time",0.5)
	rlv.fade_out_time = config.get_value("Scroll","fade_out_time",0.5)
	rlv.scroll_center = config.get_value("Scroll","scroll_center",true)
	rlv.scrolling = config.get_value("Scroll","scrolling",false)
	

func get_background_color() -> Color:
	return config.get_value("Window","background_color",Color(0,0,0,0.8))





