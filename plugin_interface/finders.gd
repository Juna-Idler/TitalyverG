
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
		if not (finder_ as ILyricsFinder)._initialize(file_path_):
			return null
		return Plugin.new(finder_,file_path_)


var plugins : Array[Plugin] = [] # of Plugin


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



class Iterator:
	var finders : LyricsFinders
	var parent_node : Node
	var index : int
	var iterator_result : PackedStringArray
	
	func _init(f : LyricsFinders,node : Node):
		finders = f
		parent_node = node
		index = -1 if finders.plugins.is_empty() else 0
		iterator_result = []
	
	func is_end() -> bool:
		return index < 0
	
	func find_async(title : String,artists : PackedStringArray,album : String,
			file_path : String,meta : Dictionary) -> PackedStringArray:
		var plugin : Plugin = finders.plugins[index]
		
		if plugin.file_path == COMMAND_IF_NOT_EMPTY_END_FIND:
			if iterator_result.is_empty():
				index += 1
			else:
				index = -1
			return PackedStringArray()
		
		var node := plugin.finder._find(title,artists,album,file_path,meta)
		if node:
			parent_node.add_child(node)
			await plugin.finder.finished
			parent_node.remove_child(node)
		var result := plugin.finder._get_result()
		iterator_result.append_array(result)
		index += 1
		if index >= finders.plugins.size():
			index = -1
		return result


func get_iterator(parent_node : Node) -> Iterator:
	return Iterator.new(self,parent_node)


class IfNotEmptyEndFind extends  ILyricsFinder:
	func _get_name() -> String:
		return COMMAND_IF_NOT_EMPTY_END_FIND


class DefaultFileFinder extends ILyricsFinder:
	var result := PackedStringArray()
	func _get_result() -> PackedStringArray:
		return result
	
	func _get_name() -> String:
		return DEFAULT_LYRICS_FILE_FINDER + "(filename + .kra;.lrc:.txt)"

	func _find(_title : String,_artists : PackedStringArray,_album : String,
			file_path : String,_meta : Dictionary) -> Node:
		result = PackedStringArray()
		if file_path.begins_with("file://"):
			var scheme = RegEx.create_from_string("file://+")
			var m := scheme.search(file_path)
			file_path = file_path.substr(m.get_end())
		if not file_path.is_absolute_path():
			return null
		var base_name := file_path.get_basename()

		var kra_path = base_name + ".kra"
		if FileAccess.file_exists(kra_path):
			var file = FileAccess.open(kra_path,FileAccess.READ)
			if file:
				result.append(file.get_as_text())
		var lrc_path = base_name + ".lrc"
		if FileAccess.file_exists(lrc_path):
			var file = FileAccess.open(lrc_path,FileAccess.READ)
			if file:
				result.append(file.get_as_text())
		var txt_path = base_name + ".txt"
		if FileAccess.file_exists(txt_path):
			var file = FileAccess.open(txt_path,FileAccess.READ)
			if file:
				result.append(file.get_as_text())
		return null

class DefaultNotFoundFinder extends ILyricsFinder:
	var result := PackedStringArray()
	func _get_result() -> PackedStringArray:
		return result

	func _get_name() -> String:
		return DEFAULT_NOT_FOUND_FINDER

	func _find(title : String,artists : PackedStringArray,album : String,
			file_path : String,meta : Dictionary) -> Node:
		var info := ("title:%s" % title + "\nartists:%s" % ",".join(artists) +
				"\nalbum:%s" % album + "\nfile_path:%s" % file_path)
		if meta.is_empty():
			result = [info]
		else:
			result = [info,JSON.stringify(meta," ",false)]
		return null
