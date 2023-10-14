extends Control

class_name KaraokeWipeView

const WipeLine := preload("res://lyrics_viewer/karaoke_wipe_viewer/view/wipe_line.tscn")
var lyrics : LyricsContainer
var font : Font

@onready var control = $Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func set_font(font_ : Font):
	font = font_
	for c in control.get_children():
		c.font = font

func set_lyrics(lyrics_ : LyricsContainer) -> bool:
	lyrics = lyrics_
	var y := 0.0
	for i in range(lyrics.lines.size() - 1):
		var wl : WipeViewerLine = WipeLine.instantiate()
		wl.size = Vector2(size.x,0)
		wl.position = Vector2(0,y)
		control.add_child(wl)
		wl.font = font
		wl.set_lyrics(lyrics.lines[i],lyrics.lines[i+1].get_start_time())
		y += wl.size.y
	var wl : WipeViewerLine = WipeLine.instantiate()
	wl.size = Vector2(size.x,0)
	wl.position = Vector2(0,y)
	control.add_child(wl)
	wl.font = font
	wl.set_lyrics(lyrics.lines[-1],(99*60+59) + 0.99)
	control.custom_minimum_size.y = y + wl.size.y
	
	
	return true

func set_time(time : float):
	for c in control.get_children():
		c.set_time(time)


func _on_resized():
	if control:
		var y := size.y / 2
		for c in control.get_children():
			c.custom_minimum_size = Vector2()
			c.size.x = size.x
			c.layout_lyrics()
			c.position.y = y
			y += c.size.y
			c.set_time(0)
		control.custom_minimum_size.y = y + size.y / 2
	pass # Replace with function body.
