extends Control


@export_multiline var input : String :
	set(v):
		input = v
		source_texts = [input]
		source_text_index = 0
		lyrics = LyricsContainer.new(input)
		if ruby_lyrics_view:
			ruby_lyrics_view.lyrics = lyrics
			ruby_lyrics_view.build()

var finder : ILyricsFinder = LyricsFileFinder.new()
@onready var ruby_lyrics_view : RubyLyricsView = $RubyLyricsView


var source_texts : PackedStringArray
var source_text_index : int
var lyrics : LyricsContainer

var playback_data : PlaybackData = PlaybackData.new(0,0,0,"","",[],"",0,{})


# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().transparent_bg = true
	get_viewport().gui_embed_subwindows = false
	get_window().files_dropped.connect(on_files_dropped)
	OS.get_executable_path().get_base_dir()

#	var file_path = "D:/Music/高本めぐみ/02 MELODIC TALK.flac"
#
#	var ExSearcher = load("D:/Documents/test_search.gd")
#	var ex_searcher = ExSearcher.new()
#
#	var texts = searcher.search("",[""],"",file_path,"")
#
#
#	var lyrics := LyricsContainer.new(texts[0])
	
	ruby_lyrics_view.lyrics = lyrics
	ruby_lyrics_view.build()
	var max_time := lyrics.get_end_time()
	$HSlider.max_value = max_time if max_time >= 0 else 0.0
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	ruby_lyrics_view.display_time += delta
	$HSlider.set_value_no_signal(ruby_lyrics_view.display_time)
	$HSlider.queue_redraw()
	ruby_lyrics_view.queue_redraw()


func _on_button_pressed():
	get_tree().quit()


func on_files_dropped(files : PackedStringArray):
	var file_path = files[0]
	source_texts = finder._find("",[""],"",file_path,"")
	if not source_texts.is_empty():
		source_text_index = 0
		lyrics = LyricsContainer.new(source_texts[0])
		ruby_lyrics_view.lyrics = lyrics
		ruby_lyrics_view.build()
		var max_time := lyrics.get_end_time()
		$HSlider.max_value = max_time if max_time >= 0 else 0.0
	else:
		var text := "no data"
		source_texts = [text]
		source_text_index = 0
		lyrics = LyricsContainer.new(text)
		ruby_lyrics_view.lyrics = lyrics
		ruby_lyrics_view.build()
		$HSlider.max_value = 0.0
	$LyricsCount.text = "<%d/%d>" % [source_text_index + 1,source_texts.size()]


func _on_window_ui_right_clicked(position_):
	var popup = $PopupMenu
	var pos := Vector2(DisplayServer.window_get_position())
	popup.popup(Rect2(pos + position_,Vector2.ZERO))


func _on_window_ui_wheel_moved(delta):
	ruby_lyrics_view.display_y_offset += delta * 30

func _on_window_ui_scroll_pad_dragging(delta):
	ruby_lyrics_view.display_y_offset += delta * ruby_lyrics_view.layout_height / ruby_lyrics_view.size.y

func _on_window_ui_middle_clicked():
	ruby_lyrics_view.display_y_offset = 0


func _on_popup_menu_id_pressed(id):
	match id:
		0: #Settings
			%Window.hide()
			var rect := Rect2i((size - Vector2(%Window.size))/2,%Window.size)
			%Window.popup_on_parent(rect)
	pass # Replace with function body.


func _on_h_slider_value_changed(value):
	ruby_lyrics_view.display_time = value
	pass # Replace with function body.


func _on_resized():
	pass



func _on_node_received(data : PlaybackData):
	if playback_data.same_song(data):
		return

	source_texts = finder._find(data.title,data.artists,data.album,data.file_path,"")
	if source_texts.is_empty():
		var text := data.title + "\n" + ",".join(data.artists) + "\n" + data.album
		source_texts = [text]
		source_text_index = 0
		lyrics = LyricsContainer.new(text)
		ruby_lyrics_view.lyrics = lyrics
		ruby_lyrics_view.build()
		$HSlider.max_value = 0.0
		$LyricsCount.text = "<%d/%d>" % [source_text_index + 1,source_texts.size()]
		return
	source_text_index = 0
	lyrics = LyricsContainer.new(source_texts[0])
	ruby_lyrics_view.lyrics = lyrics
	ruby_lyrics_view.build()
	var max_time := lyrics.get_end_time()
	$HSlider.max_value = max_time if max_time >= 0 else 0.0
	$LyricsCount.text = "<%d/%d>" % [source_text_index + 1,source_texts.size()]
	



func _on_button_prev_pressed():
	if source_texts.size() <= 1:
		return
	source_text_index -= 1
	if source_text_index < 0:
		source_text_index = source_texts.size() - 1
	lyrics = LyricsContainer.new(source_texts[source_text_index])
	ruby_lyrics_view.lyrics = lyrics
	ruby_lyrics_view.build()
	var max_time := lyrics.get_end_time()
	$HSlider.max_value = max_time if max_time >= 0 else 0.0
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
	ruby_lyrics_view.build()
	var max_time := lyrics.get_end_time()
	$HSlider.max_value = max_time if max_time >= 0 else 0.0
	$LyricsCount/ButtonNext.release_focus()
	$LyricsCount.text = "<%d/%d>" % [source_text_index + 1,source_texts.size()]

