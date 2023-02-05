
class_name LyricsFinders

const COMMAND_IF_NOT_EMPTY_END_FIND := "if not empty : End Find"
const DEFAULT_LYRICS_FILE_FINDER := "Default lyrics file finder"

class Plugin:
	var finder : ILyricsFinder
	var file_path : String
	
	func _init(f,fp):
		finder = f
		file_path = fp
		
	static func create(file_path_ : String) -> Plugin:
		if file_path_ == COMMAND_IF_NOT_EMPTY_END_FIND:
			return Plugin.new(null,file_path_)
		elif file_path_ == DEFAULT_LYRICS_FILE_FINDER:
			return Plugin.new(LyricsFileFinder.new(),file_path_)
			
		var plugin_script := load(file_path_) as GDScript
		if not plugin_script:
			return null
		var finder = plugin_script.new()
		if not finder is ILyricsFinder:
			return null
		return Plugin.new(finder,file_path_)


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


func find(title : String,artists : PackedStringArray,album : String,
		file_path : String,meta : Dictionary) -> PackedStringArray:
	var result : PackedStringArray = []
	for p in plugins:
		var plugin := p as Plugin
		match plugin.file_path:
			COMMAND_IF_NOT_EMPTY_END_FIND:
				if not result.is_empty():
					return result
				else:
					continue
		
		result.append_array(plugin.finder._find(title,artists,album,file_path,meta))
		
	return result
