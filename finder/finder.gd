
class_name ILyricsFinder

func _find(title : String,artists : PackedStringArray,album : String,
		file_path : String,param : String) -> PackedStringArray:

	var no_lyrics = title + "\n" + ",".join(artists) + "\n" + album + "\n" + file_path + "\n" + param;
	return PackedStringArray([no_lyrics]);

