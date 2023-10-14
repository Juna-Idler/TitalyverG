extends I_LyricsViewer

const KaraokeWipeView := preload("res://lyrics_viewer/karaoke_wipe_viewer/view/karaoke_wipe_view.tscn")

var view : KaraokeWipeView = null
var settings : Control = null

func _set_lyrics(_lyrics : LyricsContainer) -> bool:
	return false

func _set_time(_time : float) -> void:
	return


func _set_song_duration(_duration : float) -> void:
	return

func _set_user_offset(_offset : float) -> void:
	return

func _get_view_size() -> float:
	return 0

func _set_view_visible(visible : bool):
	view.visible = visible

func _initialize(_view_parent : Control,_settings_parent : Control,_config : ConfigFile) -> bool:
	view = KaraokeWipeView.instantiate()
	_view_parent.add_child(view)
	return false

func _terminalize() -> void:
	if view:
		view.get_parent().remove_child(view)
		view.queue_free()
		view = null
	if settings:
		settings.get_parent().remove_child(settings)
		settings.queue_free()
		settings = null
	return
