extends Control

class_name LyricsViewerManager

@export var settings_window : SettingsWindow

const VIEWERS : Dictionary = {
	"RubyLyricsViewer":preload("res://lyrics_viewer/ruby_lyrics_view/ruby_lyrics_viewer.gd"),
	"KaraokeWipeViewer":preload("res://lyrics_viewer/karaoke_wipe_viewer/karaoke_wipe_viewer.gd"),
}

var _viewer : I_LyricsViewer

var _viewer_name : String

func set_time(time : float):
	if _viewer:
		_viewer._set_time(time)

func set_user_offset(offset : float):
	if _viewer:
		_viewer._set_user_offset(offset)

func set_lyrics(lyrics : LyricsContainer) -> bool:
	if _viewer:
		return _viewer._set_lyrics(lyrics)
	return false
	
func set_song_duration(duration : float) -> void:
	if _viewer:
		_viewer._set_song_duration(duration)
		
func get_view_size() -> float:
	if _viewer:
		return _viewer._get_view_size()
	return 0

func get_current_viewer() -> I_LyricsViewer:
	return _viewer
	
func get_current_viewer_name() -> String:
	return _viewer_name

func change_viewer(viewer_name : String,config : ConfigFile) -> bool:
	if not VIEWERS.has(viewer_name):
		return false
	
	if _viewer:
		_viewer._terminalize()
	_viewer = VIEWERS[viewer_name].new()
	var result := _viewer._initialize(self,settings_window.get_viewer_parent(),config)
	if result:
		_viewer_name = viewer_name
		return true
	_viewer_name = ""
	_viewer = null
	return false
