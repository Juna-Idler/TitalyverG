
class_name ILyricsSaver

func _get_name() -> String:
	return ""

#"return String" is result message
#display popup
#if "" returned, it is ignored
func _save(_title : String,_artists : PackedStringArray,_album : String,
		_file_path : String,_meta : Dictionary,
		_lyrics : PackedStringArray,_index : int) -> String:
	return ""
