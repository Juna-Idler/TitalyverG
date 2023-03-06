
extends ILyricsFinder

func _initialize(_script_path : String):
	pass
	
func _get_name() -> String:
	return "Lyrics directory finder"

const FROM := ["\"","<",">","|",":","*","?","\\","/"]
const TO := ["”","＜","＞","｜","：","＊","？","￥","／"]

func filename_replace(text : String) -> String:
	for i in FROM.size():
		text = text.replace(FROM[i],TO[i])
	return text

func _find(title : String,artists : PackedStringArray,album : String,
		_file_path : String,_meta : Dictionary) -> PackedStringArray:

	var path := (OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/Lyrics/" +
			filename_replace(",".join(artists)) + "/" + filename_replace(album + "-" + title))
			
	var r = PackedStringArray()
	var kra_path = path.get_basename() + ".kra"
	if FileAccess.file_exists(kra_path):
		var file = FileAccess.open(kra_path,FileAccess.READ)
		if file:
			r.append(file.get_as_text())
	var lrc_path = path.get_basename() + ".lrc"
	if FileAccess.file_exists(lrc_path):
		var file = FileAccess.open(lrc_path,FileAccess.READ)
		if file:
			r.append(file.get_as_text())	
	var txt_path = path.get_basename() + ".txt"
	if FileAccess.file_exists(txt_path):
		var file = FileAccess.open(txt_path,FileAccess.READ)
		if file:
			r.append(file.get_as_text())	
	return r;
