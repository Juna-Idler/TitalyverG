extends Control

class_name KaraokeWipeView

const WipeLine := preload("res://lyrics_viewer/karaoke_wipe_viewer/view/wipe_line.tscn")
var lyrics : LyricsContainer
var font : Font

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_font(font_ : Font):
	font = font_
	for c in $VBoxContainer.get_children():
		c.font = font

func set_lyrics(lyrics_ : LyricsContainer) -> bool:
	lyrics = lyrics_
	for i in range(lyrics.lines.size() - 1):
		var wl : WipeViewerLine = WipeLine.instantiate()
		wl.size = Vector2(size.x,0)
		wl.size_flags_horizontal = Control.SIZE_SHRINK_END
		$VBoxContainer.add_child(wl)
		wl.font = font
		wl.set_lyrics(lyrics.lines[i],lyrics.lines[i+1].get_end_time())
	var wl : WipeViewerLine = WipeLine.instantiate()
	wl.size = Vector2(size.x,0)
	wl.size_flags_horizontal = Control.SIZE_SHRINK_END
	$VBoxContainer.add_child(wl)
	wl.font = font
	wl.set_lyrics(lyrics.lines[-1],(99*60+59) + 0.99)
	
	
	return true

func set_time(time : float):
	for c in $VBoxContainer.get_children():
		c.set_time(time)

