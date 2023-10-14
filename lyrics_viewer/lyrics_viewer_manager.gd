extends Control

class_name LyricsViewerManager

@export var settings_window : SettingsWindow

const VIEWERS : Dictionary = {
	"RubyLyricsViewer":preload("res://lyrics_viewer/ruby_lyrics_view/ruby_lyrics_viewer.gd"),
	"KaraokeWipeViewer":preload("res://lyrics_viewer/karaoke_wipe_viewer/karaoke_wipe_viewer.gd"),
}

const UnsyncWiewer := preload("res://lyrics_viewer/unsync_viewer/unsync_viewer.gd")

var unsync_viewer := UnsyncWiewer.new()
var sync_mode : LyricsContainer.SyncMode

var sync_viewer : I_LyricsViewer
var sync_viewer_name : String

var _viewer : I_LyricsViewer


func set_time(time : float):
	if _viewer:
		_viewer._set_time(time)

func set_user_offset(offset : float):
	if _viewer:
		_viewer._set_user_offset(offset)

func set_lyrics(lyrics : LyricsContainer) -> bool:
	sync_mode = lyrics.sync_mode
	var unsync : bool = sync_mode == LyricsContainer.SyncMode.UNSYNC
	unsync_viewer._set_view_visible(unsync)
	if sync_viewer:
		sync_viewer._set_view_visible(not unsync)
	if unsync:
		_viewer = unsync_viewer
	else:
		_viewer = sync_viewer
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
	


func get_current_sync_viewer() -> I_LyricsViewer:
	return sync_viewer
	
func get_current_sync_viewer_name() -> String:
	return sync_viewer_name

func change_sync_viewer(viewer_name : String,config : ConfigFile) -> bool:
	if not VIEWERS.has(viewer_name):
		return false
	
	if _viewer == sync_viewer:
		_viewer = null
	if sync_viewer:
		sync_viewer._terminalize()
	sync_viewer = VIEWERS[viewer_name].new()
	var result := sync_viewer._initialize(self,settings_window.get_viewer_parent(),config)
	if result:
		sync_viewer_name = viewer_name
		return true
	sync_viewer_name = ""
	sync_viewer = null
	return false

func initialize_unsync_viewer(config : ConfigFile):
	unsync_viewer._initialize(self,settings_window.get_unsync_viewer_parent(),config)

