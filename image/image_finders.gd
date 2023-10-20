
class_name ImageFinders

const COMMAND_IF_NOT_EMPTY_END_FIND := "[Command] ==== if not empty : End Find ===="
const COMMAND_END_FIND := "[Command] ==== End Find ===="
const BUILTIN_FILE_PATH_FINDER := "[Built-in] file path finder"
const BUILTIN_SPOTIFY_IMAGE_FINDER := "[Built-in] spotify image finder"


class Plugin:
	var finder : I_ImageFinder
	var file_path : String
	
	func _init(f,fp):
		finder = f
		file_path = fp
		
	static func create(file_path_ : String) -> Plugin:
		if file_path_ == COMMAND_IF_NOT_EMPTY_END_FIND:
			return Plugin.new(IfNotEmptyEndFind.new(),file_path_)
		if file_path_ == COMMAND_END_FIND:
			return Plugin.new(EndFind.new(),file_path_)
		if file_path_ == BUILTIN_FILE_PATH_FINDER:
			return Plugin.new(FilePathFinder.new(),file_path_)
		if file_path_ == BUILTIN_SPOTIFY_IMAGE_FINDER:
			return Plugin.new(SoptifyImageFinder.new(),file_path_)

		if not FileAccess.file_exists(file_path_):
			return null
		var plugin_script := load(file_path_)
		if not plugin_script is GDScript:
			return null
		var finder_ = plugin_script.new()
		if not finder_ is I_ImageFinder:
			return null
		if not (finder_ as I_ImageFinder)._initialize(file_path_):
			return null
		return Plugin.new(finder_,file_path_)

class FindingData:
	var title : String
	var artists : PackedStringArray
	var album : String
	var file_path : String
	
	func _init(t : String,ar : PackedStringArray,al : String,path : String):
		title = t
		artists = ar.duplicate()
		album = al
		file_path = path

var plugins : Array[Plugin] = [] # of Plugin

var finding_data : FindingData


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

func find_async(title : String,artists : PackedStringArray,album : String,
			file_path : String,meta : Dictionary,parent_node : Node) -> Variant:# Array[Image]:
	finding_data = FindingData.new(title,artists,album,file_path)

	var result : Array[Image] = []
	var index : int = 0
	while index < plugins.size():
		var plugin : Plugin = plugins[index]

		if plugin.file_path == COMMAND_END_FIND:
			break

		if plugin.file_path == COMMAND_IF_NOT_EMPTY_END_FIND:
			if result.is_empty():
				index += 1
				continue
			else:
				break
		var node := plugin.finder._find(title,artists,album,file_path,meta)
		if node:
			parent_node.add_child(node)
			await plugin.finder.finished
			if (file_path != finding_data.file_path or title != finding_data.title
					or artists != finding_data.artists or album != finding_data.album):
				return null
			parent_node.remove_child(node)
		result.append_array(plugin.finder._get_result())
		index += 1
	return result
		


class IfNotEmptyEndFind extends  I_ImageFinder:
	func _get_name() -> String:
		return COMMAND_IF_NOT_EMPTY_END_FIND

class EndFind extends  I_ImageFinder:
	func _get_name() -> String:
		return COMMAND_END_FIND


class FilePathFinder extends  I_ImageFinder:
	
	const EXTENTIONS : PackedStringArray = [".png",".jpg",".jpeg",".bmp",".webp"]
	
	var result : Array[Image]
	
	func _get_name() -> String:
		return BUILTIN_FILE_PATH_FINDER

	func _find(_title : String,_artists : PackedStringArray,_album : String,
			file_path : String,_meta : Dictionary) -> Node:
		result = []

		if file_path.begins_with("file://"):
			var scheme = RegEx.create_from_string("file://+")
			var m := scheme.search(file_path)
			file_path = file_path.substr(m.get_end())
		
		if not file_path.is_absolute_path():
			return null
		
		var base_name := file_path.get_basename()
		for e in EXTENTIONS:
			var path = base_name + e
			if FileAccess.file_exists(path):
				var img := Image.load_from_file(path)
				if img:
					result.append(img)
		
		if result.is_empty():
			var dir_path := file_path.get_base_dir()
			if not DirAccess.dir_exists_absolute(dir_path):
				return null
			var dir := DirAccess.open(dir_path)
			var files := dir.get_files()
			for f in files:
				var ext := "." + f.get_extension().to_lower()
				if EXTENTIONS.has(ext):
					var path := dir.get_current_dir() + "/" + f
					var img := Image.load_from_file(path)
					if img:
						result.append(img)
		return null

	func _get_result() -> Array[Image]: # of Image
		return result


class SoptifyImageFinder extends  I_ImageFinder:
	
	var result_images : Array[Image]
	var http : HTTPRequest
	
	func _init():
		http = HTTPRequest.new()
		http.set_tls_options(TLSOptions.client())
	
	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
			if is_instance_valid(http):
				http.free()

	func _get_name() -> String:
		return BUILTIN_SPOTIFY_IMAGE_FINDER

	func _find(_title : String,_artists : PackedStringArray,_album : String,
			_file_path : String,meta : Dictionary) -> Node:
		result_images = []
		
		if "item" in meta:
			var item = meta["item"]
			if item is Dictionary and "album" in item:
				var album = item["album"]
				if album is Dictionary and "images" in album:
					var images = album["images"]
					if images is Array and not images.is_empty():
						var image = images[0]
						if image is Dictionary and "url" in image:
							var url : String = image["url"]
							http.tree_entered.connect(start_finding.bind(url),CONNECT_ONE_SHOT)
							return http
		return null

	func start_finding(url : String):
		var headers := PackedStringArray([])
		http.request_completed.connect(get_response,CONNECT_ONE_SHOT)
		if http.request(url,headers,HTTPClient.METHOD_GET) != OK:
			http.request_completed.disconnect(get_response)
			finished.emit()
		return

	func get_response(result : int,response_code : int,
			headers : PackedStringArray,body : PackedByteArray):
		if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
			finished.emit()
			return

		var regex := RegEx.create_from_string("image\\/(\\w+)")
		for h in headers:
			if h.begins_with("Content-Type:"):
				var m := regex.search(h,13)
				if m:
					var image := Image.new()
					var err : Error
					var type := m.get_string(1)
					match type:
						"jpeg":
							err = image.load_jpg_from_buffer(body)
						"png":
							err = image.load_png_from_buffer(body)
						"webp":
							err = image.load_webp_from_buffer(body)
						_:
							err = FAILED
					if err == OK:
						result_images.append(image)
						finished.emit()
						return
		finished.emit()
		return

	func _get_result() -> Array[Image]: # of Image
		return result_images
