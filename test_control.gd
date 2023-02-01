extends Control

@onready var ruby_lyrics_view : RubyLyricsView = $RubyLyricsView

var searcher := LyricsFileSearcher.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	var file_path = "D:/Music/高本めぐみ/02 MELODIC TALK.flac"
	
	var texts = searcher.search("",[""],"",file_path,"")
	var lyrics := LyricsContainer.new(texts[0])

	ruby_lyrics_view.lyrics = lyrics
	ruby_lyrics_view.build()

	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
