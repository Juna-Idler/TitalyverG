extends ILyricsLoader


var scene
var line_edit : LineEdit
var button : Button
var browser : Button

var MyHttpRequest : GDScript
var http # : MyHttpRequest

var param : Dictionary = {
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
		

func _initialize(script_path : String):
	MyHttpRequest = load(script_path.get_base_dir() + "/http_request.gd")
	http = MyHttpRequest.new()
	var Scene : PackedScene = load(script_path.get_base_dir() + "/html_lyrics_site_scrape_loader.tscn")
	scene = Scene.instantiate()
	line_edit = scene.get_node("LineEdit")
	button = scene.get_node("Button")
	browser = scene.get_node("ButtonBrowser")
	button.pressed.connect(_on_button_pressed)
	browser.pressed.connect(_on_button_brower_pressed)
	

func _get_name() -> String:
	return "http_lyrics_site_loader"


func _open(_title : String, _artists : PackedStringArray, _album : String,
		_file_path : String,_meta : Dictionary) -> Control:
	return scene

func _close():
	pass


func _on_button_pressed():
	var url : String = line_edit.text
	if not url.begins_with(param["host"]):
		return
	url = url.substr(param["host"].length())
	var lyrics := get_lyrics(url)
	if not lyrics.is_empty():
		var header : String = param["host"] + url + "\n\n"
		loaded.emit([header + lyrics],"")


func get_lyrics(url : String) -> String:
	if not http.connect_to_host(param["host"]):
		return ""
	
	var response = http.get_response(url)
	if response.is_empty():
		return ""
	
	var block_regex := RegEx.create_from_string(param["lyrics_block_regex"])
	var m := block_regex.search(response)
	if not m:
		return ""
	var lyrics := m.get_string(1)
	for r in param["lyrics_replacers"]:
		var replace_regex = RegEx.create_from_string(r[0])
		lyrics = replace_regex.sub(lyrics,r[1],true)
	return lyrics


func _on_button_brower_pressed():
	OS.shell_open(line_edit.text)




