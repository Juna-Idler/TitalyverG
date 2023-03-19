extends ILyricsFinder


var finder : ILyricsFinder


var result := PackedStringArray()

func _get_result() -> PackedStringArray:
	return result

func _initialize(script_path : String) -> bool:
	finder = load(script_path.get_base_dir() + "/html_lyrics_site_scrape_finder.gd").new()
	finder._initialize(script_path)
	return true


func _get_name() -> String:
	return "html_lyrics_site_scrape_save_finder"


const FROM := ["\"","<",">","|",":","*","?","\\","/"]
const TO := ["”","＜","＞","｜","：","＊","？","￥","／"]

func filename_replace(text : String) -> String:
	for i in FROM.size():
		text = text.replace(FROM[i],TO[i])
	return text

var _title : String
var _artists : PackedStringArray
var _album : String
var _file_path : String
var _meta : Dictionary

func _find(title : String,artists : PackedStringArray,album : String,
		file_path : String,meta : Dictionary) -> Node:
	result = PackedStringArray()
	finder.finished.connect(save,CONNECT_ONE_SHOT)
	var n := finder._find(title,artists,album,file_path,meta)
	if n == null:
		finder.finished.disconnect(save)
		return null
	_title = title
	_artists = artists
	_album = album
	_file_path = file_path
	_meta = meta
	return n

func save():
	result = finder._get_result()
	if result.is_empty():
		finished.emit()
		return
		
	var path := (OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/Lyrics/" +
			filename_replace(",".join(_artists)) + "/" + filename_replace(_album + "-" + _title))
	
	if not path.is_absolute_path():
		finished.emit()
		return
	if path.begins_with("file://"):
		var scheme = RegEx.create_from_string("file://+")
		var m := scheme.search(path)
		path = path.substr(m.get_end())
		
	var lc := LyricsContainer.new(result[0])
	var ext : String
	match lc.sync_mode:
		LyricsContainer.SyncMode.KARAOKE:
			ext = ".kra"
		LyricsContainer.SyncMode.LINE:
			ext = ".lrc"
		LyricsContainer.SyncMode.UNSYNC:
			ext = ".txt"
		_:
			finished.emit()
			return 
	
	path += ext
	if FileAccess.file_exists(path):
		finished.emit()
		return
	
	var dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	
	var file = FileAccess.open(path,FileAccess.WRITE)
	if file:
		file.store_string(result[0])
	finished.emit()
	return
