extends I_ImageProcessor

class_name DefaultImageProcessor
	
var canvas : Control
var texture_rect : TextureRect
var color_rect : ColorRect

const DIPSettings = preload("res://image/default_image_processor_settings.tscn")

var settings : Control

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(texture_rect):
			canvas.free()

func _initialize(_script_path : String):
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	texture_rect = TextureRect.new()
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	canvas.add_child(texture_rect)
	canvas.add_child(color_rect)
	
func _get_name() -> String:
	return ImageManager.BUILTIN_DEFAULT_IMAGE_PROCESSOR

func _get_canvas() -> Control:
	return canvas

func _get_settings(config : ConfigFile) -> Control:
	settings = DIPSettings.instantiate()
	settings.tree_exited.connect(func():settings.queue_free())
	var size_rate : SpinBox = settings.get_node("%SpinBoxSizeRate")
	size_rate.value_changed.connect(func(v):
			set_texture_size(v)
			config.set_value("DefaultImageProcessor","size_rate",v)
			)
	set_texture_size(config.get_value("DefaultImageProcessor","size_rate",100))
	
	var opacity : SpinBox = settings.get_node("%SpinBoxOpacity")
	opacity.value_changed.connect(func(v):
			set_texture_opacity(v)
			config.set_value("DefaultImageProcessor","opacity",v)
			)
	set_texture_opacity(config.get_value("DefaultImageProcessor","opacity",100))
	
	return settings

func set_texture_size(v : float):
	var rate : float = (100 - v) / 200
	texture_rect.anchor_left = rate
	texture_rect.anchor_top = rate
	texture_rect.anchor_right = 1 - rate
	texture_rect.anchor_bottom = 1 - rate

func set_texture_opacity(rate : float):
	texture_rect.modulate.a = rate / 100

func _set_images(images : Array):
	if images.is_empty():
		texture_rect.texture = null
		return
	var texture := ImageTexture.create_from_image(images[0])
	texture_rect.texture = texture

func _set_bg_color(color : Color):
	color_rect.color = color

