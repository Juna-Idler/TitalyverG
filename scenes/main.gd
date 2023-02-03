extends Control


@export_multiline var input : String :
	set(v):
		input = v
		source_text = input
		lyrics = LyricsContainer.new(v)
		if ruby_lyrics_view:
			ruby_lyrics_view.lyrics = lyrics
			ruby_lyrics_view.build()

var searcher := LyricsFileSearcher.new()
@onready var ruby_lyrics_view : RubyLyricsView = $RubyLyricsView


var source_text : String
var lyrics : LyricsContainer


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
	$HSlider.value = ruby_lyrics_view.display_time
	pass


func _on_button_pressed():
	get_tree().quit()


func on_files_dropped(files : PackedStringArray):
	var file_path = files[0]
	var texts = searcher.search("",[""],"",file_path,"")
	if texts.is_empty() and source_text != texts[0]:
		source_text = texts[0]
		lyrics = LyricsContainer.new(source_text)
		ruby_lyrics_view.lyrics = lyrics
		ruby_lyrics_view.build()
		
		var max_time := lyrics.get_end_time()
		$HSlider.max_value = max_time if max_time >= 0 else 0.0


func _on_window_ui_right_clicked(position_):
	var popup = $PopupMenu
	var pos := Vector2(DisplayServer.window_get_position())
	popup.popup(Rect2(pos + position_,Vector2.ZERO))


func _on_window_ui_wheel_moved(delta):
	ruby_lyrics_view.display_y_offset += delta * 30

func _on_window_ui_scroll_pad_dragging(delta):
	ruby_lyrics_view.display_y_offset += delta * ruby_lyrics_view.layout_height / ruby_lyrics_view.size.y


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
	var texts = searcher.search(data.title,data.artists,data.album,data.file_path,"")
	if texts.is_empty():
		source_text = data.title + "\n" + ",".join(data.artists) + "\n" + data.album
		lyrics = LyricsContainer.new(source_text)
		ruby_lyrics_view.lyrics = lyrics
		ruby_lyrics_view.build()
		$HSlider.max_value = 0.0
		return
	if source_text != texts[0]:
		source_text = texts[0]
		lyrics = LyricsContainer.new(source_text)
		ruby_lyrics_view.lyrics = lyrics
		ruby_lyrics_view.build()
		var max_time := lyrics.get_end_time()
		$HSlider.max_value = max_time if max_time >= 0 else 0.0
	

