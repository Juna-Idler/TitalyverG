extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,false)
	
#	$WipeLine.font = load("res://fonts/ShipporiAntique-Medium.otf")
	var lyrics := LyricsContainer.new("""@ruby_set=[｜][《][》]
[00:00.00]毎度のことながら｜禁則処理《きんそくしょり》と｜振り仮名《ルビ》を無視すればめっちゃ楽なんだけどね。まあやらない選択肢はないけど。[00:10.00]""")
#	$WipeLine.set_lyrics(lyrics.lines[0],-1)
#	$WipeLine.set_time(0)
	
	$karaoke_wipe_view.font = load("res://fonts/ShipporiAntique-Medium.otf")
	$karaoke_wipe_view.set_lyrics(lyrics)
	$karaoke_wipe_view.set_time(0)
	pass # Replace with function body.

var time_ : float = 0
var pause : bool = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not pause:
		time_ += delta
		if time_ > 10.0:
			time_ = 0
		$karaoke_wipe_view.set_time(time_)


func _on_button_pressed():
	pause = not pause
	if not pause:
		time_ = 0
		$karaoke_wipe_view.set_time(time_)
