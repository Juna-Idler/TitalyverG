
class_name LyricsFinders

const COMMAND_IF_NOT_EMPTY_END_FIND := "[Command] ==== if not empty : End Find ===="
const DEFAULT_LYRICS_FILE_FINDER := "[Built-in] lyrics file finder"
const DEFAULT_NOT_FOUND_FINDER := "[Built-in] not found finder"

class Plugin:
	var finder : ILyricsFinder
	var file_path : String
	
	func _init(f,fp):
		finder = f
		file_path = fp
		finder._initialize(file_path)
		
	static func create(file_path_ : String) -> Plugin:
		if file_path_ == COMMAND_IF_NOT_EMPTY_END_FIND:
			return Plugin.new(IfNotEmptyEndFind.new(),file_path_)
		elif file_path_ == DEFAULT_LYRICS_FILE_FINDER:
			return Plugin.new(DefaultFileFinder.new(),file_path_)
		elif file_path_ == DEFAULT_NOT_FOUND_FINDER:
			return Plugin.new(DefaultNotFoundFinder.new(),file_path_)
		
		if not FileAccess.file_exists(file_path_):
			return null
		var plugin_script := load(file_path_)
		if not plugin_script is GDScript:
			return null
		var finder_ = plugin_script.new()
		if not finder_ is ILyricsFinder:
			return null
		return Plugin.new(finder_,file_path_)


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


func find_all(title : String,artists : PackedStringArray,album : String,
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


class Iterator:
	var finders : LyricsFinders
	var index : int
	var iterator_result : PackedStringArray
	
	func _init(f):
		finders = f
		index = -1 if finders.plugins.is_empty() else 0
		iterator_result = []
	
	func is_end() -> bool:
		return index < 0
	
	func find(title : String,artists : PackedStringArray,album : String,
			file_path : String,meta : Dictionary) -> PackedStringArray:
		var result : PackedStringArray = finders.plugins[index].finder._find(title,artists,album,file_path,meta)
		iterator_result.append_array(result)
		
		index += 1
		while index < finders.plugins.size():
			if finders.plugins[index].file_path == COMMAND_IF_NOT_EMPTY_END_FIND:
				if not iterator_result.is_empty():
					index = -1
					return result
				else:
					index += 1
					continue
			else:
				return result
		index = -1
		return result


func get_iterator() -> Iterator:
	return Iterator.new(self)


class IfNotEmptyEndFind extends  ILyricsFinder:
	func _get_name() -> String:
		return COMMAND_IF_NOT_EMPTY_END_FIND
	func _find(_title : String,_artists : PackedStringArray,_album : String,
			_file_path : String,_meta : Dictionary) -> PackedStringArray:
		return []
		
class DefaultFileFinder extends ILyricsFinder:
	func _get_name() -> String:
		return DEFAULT_LYRICS_FILE_FINDER + "(filename + .kra;.lrc:.txt)"

	func _find(_title : String,_artists : PackedStringArray,_album : String,
			file_path : String,_meta : Dictionary) -> PackedStringArray:
		if not file_path.is_absolute_path():
			return PackedStringArray()
			
		if file_path.begins_with("file://"):
			var scheme = RegEx.create_from_string("file://+")
			var m := scheme.search(file_path)
			file_path = file_path.substr(m.get_end())

		var r = PackedStringArray()
		var kra_path = file_path.get_basename() + ".kra"
		if FileAccess.file_exists(kra_path):
			var file = FileAccess.open(kra_path,FileAccess.READ)
			if file:
				r.append(file.get_as_text())
		var lrc_path = file_path.get_basename() + ".lrc"
		if FileAccess.file_exists(lrc_path):
			var file = FileAccess.open(lrc_path,FileAccess.READ)
			if file:
				r.append(file.get_as_text())	
		var txt_path = file_path.get_basename() + ".txt"
		if FileAccess.file_exists(txt_path):
			var file = FileAccess.open(txt_path,FileAccess.READ)
			if file:
				r.append(file.get_as_text())	
		return r;

class DefaultNotFoundFinder extends ILyricsFinder:
	func _get_name() -> String:
		return DEFAULT_NOT_FOUND_FINDER

	func _find(title : String,artists : PackedStringArray,album : String,
			file_path : String,meta : Dictionary) -> PackedStringArray:
		var info := ("title:%s" % title + "\nartists:%s" % ",".join(artists) +
				"\nalbum:%s" % album + "\nfile_path:%s" % file_path)
		if meta.is_empty():
			return [info]
			
		var meta_info : String = ""
		for key in meta:
			meta_info += str(key) + ":" + str(meta[key]) + "\n"
		return [info,meta_info]
