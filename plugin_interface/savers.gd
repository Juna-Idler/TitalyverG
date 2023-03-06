
class_name LyricsSavers

const DEBUG_NOEFFECT_SAVER := "[Debug] No Effect"

const BUILTIN_LYRICS_FILE_SAVER := "[Built-in] lyrics file saver"
const BUILTIN_LYRICS_FILE_SAVER_OVERWRITE := "[Built-in] lyrics file saver [Overwrite]"
const BUILTIN_LYRICS_TEXT_SHELL_OPENER := "[Built-in] lyrics text shell opener"

class Plugin:
	var saver : ILyricsSaver
	var file_path : String
	
	func _init(s,fp):
		saver = s
		file_path = fp
		saver._initialize(file_path)
		
	static func create(file_path_ : String) -> Plugin:
		if file_path_ == DEBUG_NOEFFECT_SAVER:
			return Plugin.new(DebugNoEffectSaver.new(),file_path_)
		if file_path_ == BUILTIN_LYRICS_FILE_SAVER:
			return Plugin.new(DefaultFileSaver.new(),file_path_)
		if file_path_ == BUILTIN_LYRICS_FILE_SAVER_OVERWRITE:
			return Plugin.new(DefaultFileSaverOverwrite.new(),file_path_)
		if file_path_ == BUILTIN_LYRICS_TEXT_SHELL_OPENER:
			return Plugin.new(DefaultLyricsShellOpener.new(),file_path_)
			
		if not FileAccess.file_exists(file_path_):
			return null
		var plugin_script = load(file_path_)
		if not plugin_script is GDScript:
			return null
		var saver_ = plugin_script.new()
		if not saver_ is ILyricsSaver:
			return null
		return Plugin.new(saver_,file_path_)


var plugins : Array = [] # of Plugin


func _init():
	pass

func serialize() -> PackedStringArray:
	var result := PackedStringArray()
	for p in plugins:
		result.append((p as Plugin).file_path)
	return result

func deserialize(strings : PackedStringArray):
	plugins.clear()
	for s in strings:
		var p = Plugin.create(s)
		if p:
			plugins.append(p)


class DebugNoEffectSaver extends  ILyricsSaver:
	func _get_name() -> String:
		return DEBUG_NOEFFECT_SAVER
	func _save(_title : String,_artists : PackedStringArray,_album : String,
			_file_path : String,_meta : Dictionary,
			_lyrics : PackedStringArray,_index : int) -> String:
		return "no effect save"


class DefaultFileSaver extends ILyricsSaver:
	func _get_name() -> String:
		return BUILTIN_LYRICS_FILE_SAVER + "(filename + .kra;.lrc:.txt)"

	func _save(_title : String,_artists : PackedStringArray,_album : String,
			file_path : String,_meta : Dictionary,
			lyrics : PackedStringArray,index : int) -> String:
		
		if not file_path.is_absolute_path():
			return "failed: not file path \"%s\"" % file_path
		if file_path.begins_with("file://"):
			var scheme = RegEx.create_from_string("file://+")
			var m := scheme.search(file_path)
			file_path = file_path.substr(m.get_end())
		
		var text := lyrics[index]
		var lc := LyricsContainer.new(text)
		var ext : String
		match lc.sync_mode:
			LyricsContainer.SyncMode.KARAOKE:
				ext = ".kra"
			LyricsContainer.SyncMode.LINE:
				ext = ".lrc"
			LyricsContainer.SyncMode.UNSYNC:
				ext = ".txt"
			_:
				return "failed: lyrics sync mode unknown"
		
		var path = file_path.get_basename() + ext
		if FileAccess.file_exists(path):
			return "failed: file already exists"
		var file = FileAccess.open(path,FileAccess.WRITE)
		if file:
			file.store_string(text)
		return "succeeded"

class DefaultFileSaverOverwrite extends ILyricsSaver:
	func _get_name() -> String:
		return BUILTIN_LYRICS_FILE_SAVER_OVERWRITE + "(filename + .kra;.lrc:.txt)"

	func _save(_title : String,_artists : PackedStringArray,_album : String,
			file_path : String,_meta : Dictionary,
			lyrics : PackedStringArray,index : int) -> String:
		
		if not file_path.is_absolute_path():
			return "failed: not file path \"%s\"" % file_path
		if file_path.begins_with("file://"):
			var scheme = RegEx.create_from_string("file://+")
			var m := scheme.search(file_path)
			file_path = file_path.substr(m.get_end())
		
		var text := lyrics[index]
		var lc := LyricsContainer.new(text)
		var ext : String
		match lc.sync_mode:
			LyricsContainer.SyncMode.KARAOKE:
				ext = ".kra"
			LyricsContainer.SyncMode.LINE:
				ext = ".lrc"
			LyricsContainer.SyncMode.UNSYNC:
				ext = ".txt"
			_:
				return "failed: lyrics sync mode unknown"
		
		var path = file_path.get_basename() + ext
		var file = FileAccess.open(path,FileAccess.WRITE)
		if file:
			file.store_string(text)
		return "succeeded"


class DefaultLyricsShellOpener extends ILyricsSaver:
	func _get_name() -> String:
		return BUILTIN_LYRICS_TEXT_SHELL_OPENER

	func _save(_title : String,_artists : PackedStringArray,_album : String,
			_file_path : String,_meta : Dictionary,
			lyrics : PackedStringArray,index : int) -> String:
		
		var text := lyrics[index]
		var file = FileAccess.open("user://temporary_lyrics.txt", FileAccess.WRITE)
		file.store_string(text)
		file = null
		OS.shell_open(ProjectSettings.globalize_path("user://temporary_lyrics.txt"))
		return ""
