
class_name LyricsSavers

const DEFAULT_LYRICS_FILE_SAVER := "Default lyrics file saver"

class Plugin:
	var saver : ILyricsSaver
	var file_path : String
	
	func _init(s,fp):
		saver = s
		file_path = fp
		
	static func create(file_path_ : String) -> Plugin:
		if file_path_ == DEFAULT_LYRICS_FILE_SAVER:
			return Plugin.new(DefaultFileSaver.new(),file_path_)
			
		var plugin_script := load(file_path_) as GDScript
		if not plugin_script:
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



class DefaultFileSaver extends ILyricsSaver:
	func _get_name() -> String:
		return DEFAULT_LYRICS_FILE_SAVER + "(filename + .kra;.lrc:.txt)"

	func _save(_title : String,_artists : PackedStringArray,_album : String,
			file_path : String,_meta : Dictionary,
			lyrics : PackedStringArray,index : int):
		
		if not file_path.is_absolute_path():
			return
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
				return
		
		var path = file_path.get_basename() + ext
		if FileAccess.file_exists(path):
			return
		var file = FileAccess.open(path,FileAccess.WRITE)
		if file:
			file.store_string(text)
	
