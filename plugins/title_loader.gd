extends ILyricsLoader

var scene : Control
var text_edit : TextEdit
var button : Button

func _initialize(script_path : String):
	var Scene : PackedScene = load(script_path.get_base_dir() + "/title_loader.tscn")
	scene = Scene.instantiate()
	text_edit = scene.get_node("TextEdit")
	button = scene.get_node("Button")
	button.pressed.connect(_on_button_pressed)
	pass
	
func _get_name() -> String:
	return "Title Loader"

const FROM := ["\"","<",">","|",":","*","?","\\","/"]
const TO := ["”","＜","＞","｜","：","＊","？","￥","／"]

func filename_replace(text : String) -> String:
	for i in FROM.size():
		text = text.replace(FROM[i],TO[i])
	return text

func _open(title : String, artists : PackedStringArray, album : String,
		_file_path : String,_meta : Dictionary) -> Control:
	var path := (OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/Lyrics/" +
			filename_replace(",".join(artists)) + "/" + filename_replace(album + "-" + title))
	var txt_path = path.get_basename() + ".txt"
	if FileAccess.file_exists(txt_path):
		var file = FileAccess.open(txt_path,FileAccess.READ)
		if file:
			text_edit.text = file.get_as_text()
	return scene

func _close():
	text_edit.text = ""


func _on_button_pressed():
	loaded.emit([text_edit.text],"")
	text_edit.text = ""

