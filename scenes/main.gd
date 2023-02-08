extends Control


@export_multiline var input : String


var settings := Settings.new()


@onready var ruby_lyrics_view : RubyLyricsView = $RubyLyricsView

var finders := LyricsFinders.new()


var source_texts : PackedStringArray
var source_text_index : int
var lyrics : LyricsContainer

var playback_data : PlaybackData = PlaybackData.new(false,0,0,0,"","",[],"",0,{})

var playing : bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().transparent_bg = true
	get_viewport().gui_embed_subwindows = false
	get_window().files_dropped.connect(on_files_dropped)
#	OS.get_executable_path().get_base_dir()

	settings.load_settings()
	$ColorRect.color = settings.get_background_color()
	settings.initialize_ruby_lyrics_view_settings(ruby_lyrics_view)
	settings.initialize_finders_settings(finders)
	
	source_texts = [input]
	set_lyrics()

	%SettingsWindow.initialize(settings,ruby_lyrics_view,finders)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if playing:
		ruby_lyrics_view.set_time_and_target_y(ruby_lyrics_view.time + delta)


func _on_button_pressed():
	get_tree().quit()


func on_files_dropped(files : PackedStringArray):
	var file_path = files[0]
	source_texts = finders._find("",[""],"",file_path,{})
	set_lyrics()

func _on_window_ui_right_clicked(position_):
	var popup = $PopupMenu
	var pos := Vector2(DisplayServer.window_get_position())
	popup.popup(Rect2(pos + position_,Vector2.ZERO))


func _on_window_ui_wheel_moved(delta):
	ruby_lyrics_view.user_y_offset += delta * 30

func _on_window_ui_scroll_pad_dragging(delta):
	ruby_lyrics_view.user_y_offset += delta * ruby_lyrics_view.layout_height / ruby_lyrics_view.size.y

func _on_window_ui_middle_clicked():
	ruby_lyrics_view.user_y_offset = 0


func _on_popup_menu_id_pressed(id):
	match id:
		0: #Settings
			%SettingsWindow.hide()
			var rect := Rect2i((size - Vector2(%SettingsWindow.size))/2,%SettingsWindow.size)
			%SettingsWindow.popup_on_parent(rect)
	pass # Replace with function body.


func _on_resized():
	pass


func _on_node_received(data : PlaybackData):
	ruby_lyrics_view.set_time_and_target_y(data.seek_time)
	if data.playback_event & PlaybackData.PlaybackEvent.PLAY_FLAG:
		playing = true
	else:
		playing = false;
#		if data.playback_event & PlaybackData.PlaybackEvent.STOP_FLAG:
#			playing = false
	if data.playback_only or playback_data.same_song(data):
		return
	playback_data = data
	
	ruby_lyrics_view.song_duration = data.duration
	source_texts = finders.find(data.title,data.artists,data.album,data.file_path,data.meta_data)
	set_lyrics()


func _on_button_prev_pressed():
	if source_texts.size() <= 1:
		return
	source_text_index -= 1
	if source_text_index < 0:
		source_text_index = source_texts.size() - 1
	lyrics = LyricsContainer.new(source_texts[source_text_index])
	ruby_lyrics_view.lyrics = lyrics
	ruby_lyrics_view.user_y_offset = 0
	ruby_lyrics_view.build()
	$LyricsCount/ButtonPrev.release_focus()
	$LyricsCount.text = "<%d/%d>" % [source_text_index + 1,source_texts.size()]

func _on_button_next_pressed():
	if source_texts.size() <= 1:
		return
	source_text_index += 1
	if source_text_index >= source_texts.size():
		source_text_index = 0
	lyrics = LyricsContainer.new(source_texts[source_text_index])
	ruby_lyrics_view.lyrics = lyrics
	ruby_lyrics_view.user_y_offset = 0
	ruby_lyrics_view.build()
	$LyricsCount/ButtonNext.release_focus()
	$LyricsCount.text = "<%d/%d>" % [source_text_index + 1,source_texts.size()]


func set_lyrics():
	ruby_lyrics_view.user_y_offset = 0
	if not source_texts.is_empty():
		source_text_index = 0
		lyrics = LyricsContainer.new(source_texts[0])
		ruby_lyrics_view.lyrics = lyrics
		ruby_lyrics_view.build()
	else:
		var text := "no data"
		source_texts = [text]
		source_text_index = 0
		lyrics = LyricsContainer.new(text)
		ruby_lyrics_view.lyrics = lyrics
		ruby_lyrics_view.build()
	if source_texts.size() <= 1:
		$LyricsCount.hide()
	else:
		$LyricsCount.show()
		$LyricsCount.text = "<%d/%d>" % [source_text_index + 1,source_texts.size()]



func _on_settings_display_background_color_changed(color):
	$ColorRect.color = color
