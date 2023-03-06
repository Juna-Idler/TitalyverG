
class_name LyricsLoaders



class Plugin:
	var loader : ILyricsLoader
	var file_path : String
	
	func _init(l,fp):
		loader = l
		file_path = fp
		loader._initialize(file_path)
		
	static func create(file_path_ : String) -> Plugin:
			
		if not FileAccess.file_exists(file_path_):
			return null
		var plugin_scene = load(file_path_)
		if not plugin_scene is PackedScene:
			return null
		var loader_ = plugin_scene.instantiate()
		if not loader_ is ILyricsLoader:
			return null
		return Plugin.new(loader_,file_path_)


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



