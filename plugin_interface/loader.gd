
class_name ILyricsLoader

signal loaded(lyrics : PackedStringArray)

func _get_name() -> String:
	return ""


func _load(control : Control, title : String, artists : PackedStringArray, album : String,
		file_path : String,_meta : Dictionary) -> bool:
	
	var no_lyrics = title + "\n" + ",".join(artists) + "\n" + album + "\n" + file_path
	return false
