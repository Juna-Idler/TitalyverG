extends Control

var settings : Settings
var viewer_manager : LyricsViewerManager

@onready var option_button = %OptionButton

func initialize(settings_ : Settings,viewer : LyricsViewerManager):
	settings = settings_
	viewer_manager = viewer
	
	for i in LyricsViewerManager.VIEWERS.keys().size():
		var key : String = LyricsViewerManager.VIEWERS.keys()[i]
		option_button.add_item(key)
		if key == viewer_manager.get_current_sync_viewer_name():
			option_button.select(i)
			


func _on_button_pressed():
	%OptionButton.selected
	pass # Replace with function body.
