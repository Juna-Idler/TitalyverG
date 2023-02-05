extends Window

@export var ruby_lyrics_view : RubyLyricsView

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_about_to_popup():
	pass # Replace with function body.

func _on_close_requested():
	hide()
	pass # Replace with function body.


func _on_files_dropped(files):
	if $TabContainer.get_current_tab_control() == $TabContainer/Finder:
		$TabContainer/Finder.on_files_dropped(files)


