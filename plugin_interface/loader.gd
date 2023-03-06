
extends Control
class_name ILyricsLoader

signal loaded(lyrics : PackedStringArray,msg : String)


func _initialize(_script_path : String):
	pass
	
func _get_name() -> String:
	return ""


func _open(_title : String, _artists : PackedStringArray, _album : String,
		_file_path : String,_meta : Dictionary) -> bool:
	return false

func _close():
	pass
