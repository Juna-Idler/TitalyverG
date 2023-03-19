extends ILyricsLoader


var scene : Node
var line_edit : LineEdit
var button : Button
var browser : Button
var http : HTTPRequest

var site_param : Dictionary = {
	"host" : "https://utaten.com",
	"param_format" : "/search?sort=popular_sort%3Aasc&artist_name={artist}&title={title}&beginning=&body=&lyricist=&composer=&sub_title=&tag=&form_open=1&show_artists=1",
	
	"list_block_regex" : """<th class="searchResult__head">タイトル \\/ 歌手<\\/th>\\s.*<th>歌い出し<\\/th>\\s*<\\/tr>([\\s\\S]+?)<\\/table>""",
	"list_item_regex" : "<tr>([\\s\\S]+?)</tr>",
	"item_url_regex" : "<a href=\"(.+?)\">",
	"item_title_regex" : "<a href=\"/lyric/[^>]*>\\s*(.+?)\\s*</a>",
	"item_artist_regex" : "<a href=\"/artist/[^>]*>\\s*(.+?)\\s*</a>",
	
	"lyrics_block_regex" :  """<div class="hiragana" >([\\s\\S]+?)<\\/div>""",
	"lyrics_replacers" : [
		[
			"(^\\s+|\\r\\n|\\n|\\r|\\s+$)",
			""
		],
		[
			"(?<!@ruby_end=》)$",
			"\n\n@ruby_parent=｜\n@ruby_begin=《\n@ruby_end=》"
		],
		[
			"<span class=\"ruby\"><span class=\"rb\">",
			"｜"
		],
		[
			"</span><span class=\"rt\">",
			"《"
		],
		[
			"</span></span>",
			"》"
		],
		[
			"<br[^>]*>",
			"\n"
		],
		[
			"<[^>]*>",
			""
		]
	]
}

var block_regex : RegEx

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if scene:
			if is_instance_valid(scene):
				scene.free()

func _initialize(script_path : String):
	var Scene : PackedScene = load(script_path.get_base_dir() + "/html_lyrics_site_scrape_loader.tscn")
	scene = Scene.instantiate()
	line_edit = scene.get_node("LineEdit")
	button = scene.get_node("Button")
	browser = scene.get_node("ButtonBrowser")
	http = scene.get_node("HTTPRequest")
	
	button.pressed.connect(_on_button_pressed)
	browser.pressed.connect(_on_button_brower_pressed)
	http.set_tls_options(TLSOptions.client())
	
	block_regex = RegEx.create_from_string(site_param["lyrics_block_regex"])


func _get_name() -> String:
	return "http_lyrics_site_loader"


func _open(_title : String, _artists : PackedStringArray, _album : String,
		_file_path : String,_meta : Dictionary) -> Control:
	line_edit.text = ""
	return scene

func _close():
	http.cancel_request()
	pass


func _on_button_pressed():
	var url : String = line_edit.text
	if not url.begins_with(site_param["host"]):
		return
	get_lyrics(url)


func get_lyrics(url : String):
	var headers := PackedStringArray([])
	http.request_completed.connect(_on_http_request_completed,CONNECT_ONE_SHOT)
	if http.request(url,headers,HTTPClient.METHOD_GET) != OK:
		http.request_completed.disconnect(_on_http_request_completed)

func _on_http_request_completed(result : int,response_code : int,
		_headers : PackedStringArray,body : PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		loaded.emit([""],"result error code=%s" % response_code)
		return
	var response := body.get_string_from_utf8()
	if response.is_empty():
		loaded.emit([""],"response no body")
		return

	var m := block_regex.search(response)
	if not m:
		loaded.emit([""],"no match")
		return
	var lyrics := m.get_string(1)
	for r in site_param["lyrics_replacers"]:
		var replace_regex = RegEx.create_from_string(r[0])
		lyrics = replace_regex.sub(lyrics,r[1],true)
	loaded.emit([line_edit.text + "\n\n" + lyrics],"")


func _on_button_brower_pressed():
	OS.shell_open(line_edit.text)




