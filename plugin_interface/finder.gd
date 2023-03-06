
class_name ILyricsFinder

func _initialize(_script_dir_path : String):
	pass

func _get_name() -> String:
	return ""

func _find(title : String,artists : PackedStringArray,album : String,
		file_path : String,_meta : Dictionary) -> PackedStringArray:
			
	var no_lyrics = title + "\n" + ",".join(artists) + "\n" + album + "\n" + file_path;
	return PackedStringArray([no_lyrics]);

