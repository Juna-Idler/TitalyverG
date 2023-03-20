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
	
	"lyrics_title_regex": [
		"""<h2 class="newLyricTitle__main">\\s*(\\S+.*?)\\s*<span class="newLyricTitle_afterTxt">""",
		"""<span class="newLyricTitle__subTitle">\\s*(\\S+.*?)\\s*</span>""",
		],
	"lyrics_artist_regex" : """<dt class="newLyricWork__name">\\s*<h3>\\s*<a[^>]+>\\s*(\\S+.*?)\\s*</a>""",
	
	"lyrics_lyricist_regex" : """<dt class="newLyricWork__title">作詞</dt>\\s*<dd[^>]+>\\s*<a[^>]+>\\s*(\\S+.*?)\\s*</a>""",
	"lyrics_composer_regex" : """<dt class="newLyricWork__title">作曲</dt>\\s*<dd[^>]+>\\s*<a[^>]+>\\s*(\\S+.*?)\\s*</a>""",
	"lyrics_arranger_regex" : """<dt class="newLyricWork__title">編曲</dt>\\s*<dd[^>]+>\\s*<a[^>]+>\\s*(\\S+.*?)\\s*</a>""",
	
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
			"<[^ ][^<>]*>",
			""
		]
	]
}

var title_regexes : Array
var artist_regex : RegEx
var lyricist_regex : RegEx
var composer_regex : RegEx
var arranger_regex : RegEx

var block_regex : RegEx

var url : String

var NCR : GDScript

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if scene:
			if is_instance_valid(scene):
				scene.free()

func _initialize(script_path : String):
	NCR = load(script_path.get_base_dir() + "/named_character_references.gd")
	
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
	
	title_regexes = []
	for r in site_param["lyrics_title_regex"]:
		title_regexes.append(RegEx.create_from_string(r))
	artist_regex = RegEx.create_from_string(site_param["lyrics_artist_regex"])
	lyricist_regex = RegEx.create_from_string(site_param["lyrics_lyricist_regex"])
	composer_regex = RegEx.create_from_string(site_param["lyrics_composer_regex"])
	arranger_regex = RegEx.create_from_string(site_param["lyrics_arranger_regex"])


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
	url = line_edit.text
	if not url.begins_with(site_param["host"]):
		return
	get_lyrics()


func get_lyrics():
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
	
	var titles : PackedStringArray = []
	for r in title_regexes:
		var m := (r as RegEx).search(response)
		if m:
			var t := m.get_string(1)
			if not t.is_empty():
				titles.append(t)
	var title : String = NCR.decode_ncr("\n".join(titles))
	var artist : String
	var m := artist_regex.search(response)
	if m:
		artist = NCR.decode_ncr(m.get_string(1))
	var lyricist : String
	m = lyricist_regex.search(response)
	if m:
		lyricist = NCR.decode_ncr(m.get_string(1))
	var composer : String
	m = composer_regex.search(response)
	if m:
		composer = NCR.decode_ncr(m.get_string(1))
	var arranger : String
	m = arranger_regex.search(response)
	if m:
		arranger = NCR.decode_ncr(m.get_string(1))

	m = block_regex.search(response)
	if not m:
		loaded.emit([""],"no match")
		return
	var lyrics := m.get_string(1)
	for r in site_param["lyrics_replacers"]:
		var replace_regex = RegEx.create_from_string(r[0])
		lyrics = replace_regex.sub(lyrics,r[1],true)
		
	var output : PackedStringArray = [url,title,artist]
	if not lyricist.is_empty():
		output.append("作詞:" + lyricist)
	if not composer.is_empty():
		output.append("作曲:" + composer)
	if not arranger.is_empty():
		output.append("編曲:" + arranger)

	lyrics = NCR.decode_ncr(lyrics)


	loaded.emit(["\n".join(output) + "\n\n" + lyrics],"")


func _on_button_brower_pressed():
	OS.shell_open(line_edit.text)




