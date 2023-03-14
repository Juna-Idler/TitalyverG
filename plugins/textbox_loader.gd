extends ILyricsLoader

var scene : Control
var text_edit : TextEdit
var button : Button

func _initialize(script_path : String):
	var Scene : PackedScene = load(script_path.get_base_dir() + "/textbox_loader.tscn")
	scene = Scene.instantiate()
	text_edit = scene.get_node("TextEdit")
	button = scene.get_node("Button")
	button.pressed.connect(_on_button_pressed)
	pass
	
func _get_name() -> String:
	return "Textbox Loader"


func _open(_title : String, _artists : PackedStringArray, _album : String,
		_file_path : String,_meta : Dictionary) -> Control:
	return scene

func _close():
	text_edit.text = ""


func _on_button_pressed():
	loaded.emit([text_edit.text],"")
	text_edit.text = ""

