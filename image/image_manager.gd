
extends Control

class_name ImageManager

const BUILTIN_NO_IMAGE_PROCESSOR := "[Built-in] No Image Processor"
const BUILTIN_DEFAULT_IMAGE_PROCESSOR := "[Built-in] Default Image Processor"
const BUILTIN_BLUR_IMAGE_PROCESSOR := "[Built-in] Blur Image Processor"

const BUILTINS : Dictionary = {
	BUILTIN_NO_IMAGE_PROCESSOR:NoImageProcessor,
	BUILTIN_DEFAULT_IMAGE_PROCESSOR:preload("res://image/builtin_processor/default_image_processor.gd"),
	BUILTIN_BLUR_IMAGE_PROCESSOR:preload("res://image/builtin_processor/blur_processor.gd"),
}

class Plugin:
	var processor : I_ImageProcessor
	var file_path : String
	
	func _init(p,fp):
		processor = p
		file_path = fp
		
	static func create(file_path_ : String) -> Plugin:
		if BUILTINS.has(file_path_):
			var p : I_ImageProcessor = BUILTINS.get(file_path_).new()
			p._initialize("")
			return Plugin.new(p,file_path_)
		
		if not FileAccess.file_exists(file_path_):
			return null
		var plugin_script := load(file_path_)
		if not plugin_script is GDScript:
			return null
		var processor_ = plugin_script.new()
		if not processor_ is I_ImageProcessor:
			return null
		if not (processor_ as I_ImageProcessor)._initialize(file_path_):
			return null
		return Plugin.new(processor_,file_path_)


var plugins : Array[Plugin] = [] # of Plugin

var _processor : I_ImageProcessor

var finders : ImageFinders = ImageFinders.new()


var _current_images : Array[Image]
var _bg_color : Color


func _ready():
	
	pass

func get_processor() -> I_ImageProcessor:
	return _processor

func set_bg_color(color : Color):
	_bg_color = color
	if _processor:
		_processor._set_bg_color(color)


func change_processor(index : int) -> bool:
	if not (0 <= index and index < plugins.size()):
		return false
	var plugin : Plugin = plugins[index]
	if _processor == plugin.processor:
		return false

	if _processor:
		_processor._set_images([])
		remove_child(get_child(0))
	
	_processor = plugin.processor
	add_child(_processor._get_canvas())
	
	_processor._set_bg_color(_bg_color)
	_processor._set_images(_current_images)
	return true

func set_processor(p_name : String) -> bool:
	for p in plugins:
		var plugin := p as Plugin
		if p_name == plugin.processor._get_name():
			_processor = plugin.processor
			_processor._set_bg_color(_bg_color)
			_processor._set_images(_current_images)
			add_child(_processor._get_canvas())
			return true
	
	if not plugins.is_empty():
		_processor = plugins[0].processor
		_processor._set_bg_color(_bg_color)
		_processor._set_images(_current_images)
		add_child(_processor._get_canvas())
	return false

func find_async(title : String,artists : PackedStringArray,album : String,
			file_path : String,meta : Dictionary):
	var images = await finders.find_async(title,artists,album,file_path,meta,self)
	if images != null:
		_current_images = images
		_processor._set_images(_current_images)


func serialize_processors() -> PackedStringArray:
	var result := PackedStringArray()
	for p in plugins:
		var file_path := (p as Plugin).file_path
		if not BUILTINS.has(file_path):
			result.append(file_path)
	return result

func deserialize_processors(strings : PackedStringArray):
	plugins.clear()
	for b in BUILTINS:
		var p : I_ImageProcessor = BUILTINS[b].new()
		p._initialize("")
		plugins.append(Plugin.new(p,b))
	for s in strings:
		var p = Plugin.create(s)
		if p:
			plugins.append(p)


class NoImageProcessor extends I_ImageProcessor:
	
	var color_rect : ColorRect
	
	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
			if is_instance_valid(color_rect):
				color_rect.free()

	func _initialize(_script_path : String):
		color_rect = ColorRect.new()
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		
	func _get_name() -> String:
		return BUILTIN_NO_IMAGE_PROCESSOR

	func _get_canvas() -> Control:
		return color_rect

	func _get_settings(_config : ConfigFile) -> Control:
		return null

	func _set_images(_images : Array[Image]):
		return

	func _set_bg_color(color : Color):
		color_rect.color = color

