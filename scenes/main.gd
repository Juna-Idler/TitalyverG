extends Control


@export_multiline var input : String :
	set(v):
		input = v
		lyrics = LyricsContainer.new(v)
		if ruby_lyrics_view:
			ruby_lyrics_view.lyrics = lyrics
			ruby_lyrics_view.build()

var searcher := LyricsFileSearcher.new()
@onready var ruby_lyrics_view : RubyLyricsView = $ScrollContainer/RubyLyricsView


var lyrics : LyricsContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().transparent_bg = true
#	get_window().files_dropped.connect(on_files_dropped)

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
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	ruby_lyrics_view.display_time += delta
	pass


func _on_button_pressed():
	get_tree().quit()



func _on_window_ui_right_clicked(position_):
	var popup = $PopupMenu
	popup.popup(Rect2(position_,Vector2.ZERO))


func _on_window_ui_wheel_moved(delta):
	$ScrollContainer.scroll_vertical -= delta * 30
	pass # Replace with function body.

func _on_window_ui_scroll_pad_dragging(delta):
	$ScrollContainer.scroll_vertical -= delta * ruby_lyrics_view.size.y / $WindowUI.size.y
