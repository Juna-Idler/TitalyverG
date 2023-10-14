extends VBoxContainer

class_name FontSelector


signal font_changed(font : Font)

signal font_switched(system : bool)

signal file_font_changed(font_path : String)
signal system_font_changed(font_names : PackedStringArray)


@export var font_file_path : String :
	set(v) :
		font_file_path = v
		if %ButtonFontFile:
			%ButtonFontFile.text = font_file_path.get_file()

@export var system_font_name : String :
	set(v) :
		system_font_name = v
		if %ButtonSysFont:
			%ButtonSysFont.text = system_font_name
		
@export var is_system : bool :
	set(v) :
		is_system = v
		if is_node_ready():
			%CheckBoxSysFont.set_pressed_no_signal(is_system)
			%CheckBoxFontFile.set_pressed_no_signal(not is_system)

# Called when the node enters the scene tree for the first time.
func _ready():
	for f in OS.get_system_fonts():
		%ButtonSysFont.add_item(f)
	%ButtonSysFont.text = system_font_name
	
	if font_file_path.is_absolute_path():
		%ButtonFontFile.text = font_file_path.get_file()

	%CheckBoxSysFont.set_pressed_no_signal(is_system)
	%CheckBoxFontFile.set_pressed_no_signal(not is_system)


func _on_check_box_font_file_toggled(button_pressed):
	if button_pressed:
		font_switched.emit(false)
		if font_file_path.is_absolute_path():
			font_changed.emit(load(font_file_path))

func _on_check_box_sys_font_toggled(button_pressed):
	if button_pressed:
		font_switched.emit(true)
		var system_font = SystemFont.new()
		system_font.font_names = [%ButtonSysFont.text]
		font_changed.emit(system_font)


func _on_button_sys_font_item_selected(index : int):
	var font_names : PackedStringArray = [%ButtonSysFont.get_item_text(index)]
	system_font_changed.emit(font_names)
	if %CheckBoxSysFont.button_pressed:
		var system_font = SystemFont.new()
		system_font.font_names = font_names
		font_changed.emit(system_font)


func _on_button_font_file_pressed():
	if font_file_path.is_absolute_path():
		%FileDialog.root_subfolder = font_file_path.get_base_dir()
	%FileDialog.popup_centered(Vector2i(600,400))

func _on_file_dialog_file_selected(path : String):
	font_file_path = path
	file_font_changed.emit(path)
	if %CheckBoxFontFile.button_pressed:
		var font := load(path)
		font_changed.emit(font)
	%ButtonFontFile.text = path.get_file()

