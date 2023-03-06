extends ILyricsLoader



func _initialize(_script_dir_path : String):
	pass
	
func _get_name() -> String:
	return "Textbox Loader"


func _open(_title : String, _artists : PackedStringArray, _album : String,
		_file_path : String,_meta : Dictionary) -> bool:
	return true

func _close():
	$TextEdit.text = ""


func _on_button_pressed():
	loaded.emit([$TextEdit.text],"")
	$TextEdit.text = ""

