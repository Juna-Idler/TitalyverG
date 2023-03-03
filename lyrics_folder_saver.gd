extends ILyricsSaver

func _get_name() -> String:
	return "Lyrics folder saver" + "{document}/Lyrics/{artists}/{album}-{title}.{ext}"

func _save(title : String,artists : PackedStringArray,album : String,
		_file_path : String,_meta : Dictionary,
		lyrics : PackedStringArray,index : int) -> String:
	if title.is_empty() or artists.is_empty() or album.is_empty():
		var msg := "failed:"
		msg += " title" if title.is_empty() else ""
		msg += " artists" if artists.is_empty() else ""
		msg += " album" if album.is_empty() else ""
		return msg + " is empty"
		
	var text := lyrics[index]
	var lc := LyricsContainer.new(text)
	var ext : String
	match lc.sync_mode:
		LyricsContainer.SyncMode.KARAOKE:
			ext = ".kra"
		LyricsContainer.SyncMode.LINE:
			ext = ".lrc"
		LyricsContainer.SyncMode.UNSYNC:
			ext = ".txt"
		_:
			return "failed: lyrics sync mode unknown"
	
	var path := (OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/Lyrics/" +
			",".join(artists) + "/" + album + "-" + title + ext)
	var dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)

	var file = FileAccess.open(path,FileAccess.WRITE)
	if file:
		file.store_string(text)
		return "succeeded: save as \"%s\"" % path
	else:
		return "failed: file not open \"%s\"" % path
	
