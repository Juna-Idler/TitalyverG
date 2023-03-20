
extends Control

class_name ImageManager

const BUILTIN_NO_IMAGE_PROCESSOR := "[Built-in] no image processor"
const BUILTIN_DEFAULT_IMAGE_PROCESSOR := "[Built-in] default image processor"

class Plugin:
	var processor : I_ImageProcessor
	var file_path : String
	
	func _init(p,fp):
		processor = p
		file_path = fp
		
	static func create(file_path_ : String) -> Plugin:
		if file_path_ == BUILTIN_NO_IMAGE_PROCESSOR:
			return Plugin.new(NoImageProcessor.new(),file_path_)
		elif file_path_ == BUILTIN_DEFAULT_IMAGE_PROCESSOR:
			return Plugin.new(DefaultImageProcessor.new(),file_path_)
		
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


var plugins : Array = [] # of Plugin

var _processor : I_ImageProcessor

var finders : ImageFinders = ImageFinders.new()


var _current_images : Array
var _bg_color : Color


func _ready():
	var def := DefaultImageProcessor.new()
	def._initialize("")
	change_processor(def)

func get_proseccor() -> I_ImageProcessor:
	return _processor

func set_bg_color(color : Color):
	_processor._set_bg_color(color)

func set_image(images : Array):
	_processor._set_images(images)

func change_processor(new_processor : I_ImageProcessor) -> bool:
	if _processor:
		_processor._set_images([])
		remove_child(get_child(0))
	
	_processor = new_processor
	add_child(_processor._get_canvas())
	
	_processor._set_bg_color(_bg_color)
	_processor._set_images(_current_images)
	return true


func find_async(title : String,artists : PackedStringArray,album : String,
			file_path : String,meta : Dictionary):
	var images := await finders.find_async(title,artists,album,file_path,meta,self)
	_processor._set_images(images)


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
		return "NoImageProcessor"

	func _get_canvas() -> Control:
		return color_rect

	func _get_settings(_config : ConfigFile) -> Control:
		return null

	func _set_images(_images : Array):
		return

	func _set_bg_color(color : Color):
		color_rect.color = color


class DefaultImageProcessor extends I_ImageProcessor:
	
	var texture_rect : TextureRect
	var color_rect : ColorRect
	
	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
			if is_instance_valid(texture_rect):
#				if not texture_rect.is_inside_tree():
				texture_rect.free()

	func _initialize(_script_path : String):
		texture_rect = TextureRect.new()
		texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		color_rect = ColorRect.new()
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		texture_rect.add_child(color_rect)
		
	func _get_name() -> String:
		return "DefaultImageProcessor"

	func _get_canvas() -> Control:
		return texture_rect

	func _get_settings(_config : ConfigFile) -> Control:
		return null

	func _set_images(images : Array):
		if images.is_empty():
			texture_rect.texture = null
			return
		var texture := ImageTexture.create_from_image(images[0])
		texture_rect.texture = texture

	func _set_bg_color(color : Color):
		color_rect.color = color
