
extends ILyricsFinder

class_name LyricsFileFinder

func _find(_title : String,_artists : PackedStringArray,_album : String,
		file_path : String,_param : String) -> PackedStringArray:
	if not file_path.is_absolute_path():
		return PackedStringArray()

	var r = PackedStringArray()
	var kra_path = file_path.get_basename() + ".kra"
	if FileAccess.file_exists(kra_path):
		var file = FileAccess.open(kra_path,FileAccess.READ)
		if file:
			r.append(file.get_as_text())
	var lrc_path = file_path.get_basename() + ".lrc"
	if FileAccess.file_exists(lrc_path):
		var file = FileAccess.open(lrc_path,FileAccess.READ)
		if file:
			r.append(file.get_as_text())	
	var txt_path = file_path.get_basename() + ".txt"
	if FileAccess.file_exists(txt_path):
		var file = FileAccess.open(txt_path,FileAccess.READ)
		if file:
			r.append(file.get_as_text())	
	return r;
