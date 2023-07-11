extends I_ImageProcessor


var canvas : Control
var texture_rect : TextureRect
var color_rect : ColorRect

var SIPCanvas : PackedScene
var SIPSettings : PackedScene

var settings : Control

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(texture_rect):
			canvas.free()

func _initialize(script_path : String) -> bool:
	SIPCanvas = load(script_path.get_base_dir() + "/shader_processor_canvas.tscn")
	SIPSettings  = load(script_path.get_base_dir() + "/shader_processor_settings.tscn")
	
	canvas = SIPCanvas.instantiate()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	texture_rect = canvas.get_node("TextureRect")
	color_rect = canvas.get_node("ColorRect")
	return true

func _get_name() -> String:
	return "Shader Image Processor"

func _set_images(images : Array):
	if images.is_empty():
		texture_rect.texture = null
		return
	var texture := ImageTexture.create_from_image(images[0])
	texture_rect.texture = texture

func _set_bg_color(color : Color):
	color_rect.color = color

func _get_canvas() -> Control:
	return canvas

func _get_settings(config : ConfigFile) -> Control:
	settings = SIPSettings.instantiate()
	settings.tree_exited.connect(func():settings.queue_free())
	var size_rate : SpinBox = settings.get_node("%SpinBoxSizeRate")
	var val = config.get_value("ShaderImageProcessor","size_rate",100)
	size_rate.value = val
	set_texture_size(val)
	size_rate.value_changed.connect(func(v):
			set_texture_size(v)
			config.set_value("ShaderImageProcessor","size_rate",v)
			)
	
	var opacity : SpinBox = settings.get_node("%SpinBoxOpacity")
	val = config.get_value("ShaderImageProcessor","opacity",100)
	opacity.value = val
	set_texture_opacity(val)
	opacity.value_changed.connect(func(v):
			set_texture_opacity(v)
			config.set_value("ShaderImageProcessor","opacity",v)
			)

	var dialog : FileDialog = settings.get_node("FileDialog")
	var shader_button : Button = settings.get_node("%ButtonShaderFile")
	shader_button.pressed.connect(func():
			dialog.popup_centered(Vector2i(600,400))
			)
	var shader_path : String = config.get_value("ShaderImageProcessor","shader","")
	if not shader_path.is_empty():
		texture_rect.material.shader = load(shader_path)
		shader_button.text = shader_path.get_file()

	dialog.file_selected.connect(func(path : String):
			var shader : Shader = load(path)
			if shader:
				texture_rect.material.shader = shader
				config.set_value("ShaderImageProcessor","shader",path)
				shader_button.text = path.get_file()
			)
	return settings


func set_texture_size(v : float):
	var rate : float = (100 - v) / 200
	texture_rect.anchor_left = rate
	texture_rect.anchor_top = rate
	texture_rect.anchor_right = 1 - rate
	texture_rect.anchor_bottom = 1 - rate

func set_texture_opacity(rate : float):
	texture_rect.modulate.a = rate / 100

