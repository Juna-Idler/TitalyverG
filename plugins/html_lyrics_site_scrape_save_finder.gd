extends ILyricsFinder


var finder : ILyricsFinder


func _initialize(script_path : String):
	finder = load(script_path.get_base_dir() + "/html_lyrics_site_scrape_finder.gd").new()
	finder._initialize(script_path)

func _get_name() -> String:
	return "html_lyrics_site_scrape_save_finder"


const FROM := ["\"","<",">","|",":","*","?","\\","/"]
const TO := ["”","＜","＞","｜","：","＊","？","￥","／"]

func filename_replace(text : String) -> String:
	for i in FROM.size():
		text = text.replace(FROM[i],TO[i])
	return text


func _find(title : String,artists : PackedStringArray,album : String,
		file_path : String,meta : Dictionary) -> PackedStringArray:
	var r := finder._find(title,artists,album,file_path,meta)
	
	if r.is_empty():
		return r
	
	
	var path := (OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/Lyrics/" +
			filename_replace(",".join(artists)) + "/" + filename_replace(album + "-" + title))
	
	if not path.is_absolute_path():
		return r
	if path.begins_with("file://"):
		var scheme = RegEx.create_from_string("file://+")
		var m := scheme.search(path)
		path = path.substr(m.get_end())
	
	var lc := LyricsContainer.new(r[0])
	var ext : String
	match lc.sync_mode:
		LyricsContainer.SyncMode.KARAOKE:
			ext = ".kra"
		LyricsContainer.SyncMode.LINE:
			ext = ".lrc"
		LyricsContainer.SyncMode.UNSYNC:
			ext = ".txt"
		_:
			return r
	
	path += ext
	if FileAccess.file_exists(path):
		return r
	
	var dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	
	var file = FileAccess.open(path,FileAccess.WRITE)
	if file:
		file.store_string(r[0])
	return r
