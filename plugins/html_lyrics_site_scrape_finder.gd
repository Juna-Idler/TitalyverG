
extends ILyricsFinder

var MyHttpRequest : GDScript
var http # : MyHttpRequest

func _initialize(script_path : String):
	MyHttpRequest = load(script_path.get_base_dir() + "/http_request.gd")
	http = MyHttpRequest.new()
	
func _get_name() -> String:
	return "http_lyrics_site_finder"



func _find(title : String,artists : PackedStringArray,_album : String,
		_file_path : String,_meta : Dictionary) -> PackedStringArray:
	
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
#	var param2 : Dictionary = {
#		"host" : "www.uta-net.com",
#		"param_format" : "/search/?Aselect=2&Keyword={title}&Bselect=4",
#
#		"list_block_regex" :"<table summary=\"曲一覧1\">.*?<tbody>(.+?)</tbody>",
#		"list_item_regex" :"<tr>(.+?)</tr>",
#		"item_url_regex" :  "<a href=\"(.+?)\">",
#		"item_title_regex" :  "<a href=\".+?\">(.+?)</a>",
#		"item_artist_regex" :  "<a href=\".+?\">.+?</a>.+?<a href=\".+?\">(.+?)</a>",
#
#		"lyrics_block_regex" :   "<div id=\"kashi_area\" itemprop=\"text\">(.+?)</div>",
#		"lyrics_replacers" : [
#			["(^\\s+|\\r\\n|\\n|\\r|\\s+$)",""], 
#			[ "<br[^>]*>","\n"],
#			["<[^>]*>",""],
#		]
#	}

	
	var lists := get_list(param,title," ".join(artists))
	if lists.is_empty():
		title = title.uri_encode()
		var artist = " ".join(artists).uri_encode()
		var url = param["param_format"].replace("{title}",title).replace("{artist}",artist)
		OS.shell_open(param["host"] + url)
		return []
	var lyricss : PackedStringArray = []
	for l in lists:
		var list  := l as ListData
		var lyrics := get_lyrics(list.url,param)
		if not lyrics.is_empty():
			var header : String = (
				param["host"] + list.url + "\n" +
				"Title:" + list.title + "\n" +
				"Artist:" + list.artist + "\n\n"
			)
			lyricss.append(header + lyrics)
			OS.shell_open(param["host"] + list.url)
	return lyricss





class ListData:
	var url : String
	var title : String
	var artist : String
	
	func _init(u,t,a):
		url = u
		title = t
		artist = a


const POLLING_WAIT_TIME_MS = 500



func get_list(site_param : Dictionary,title : String,artist : String) -> Array:

	title = title.uri_encode()
	artist = artist.uri_encode()
	var url_param = site_param["param_format"].replace("{title}",title).replace("{artist}",artist)

	if not http.connect_to_host(site_param["host"]):
		return []
		
	var response = http.get_response(url_param)
	if response.is_empty():
		return []
		

	var block_regex := RegEx.create_from_string(site_param["list_block_regex"])
	var item_regex := RegEx.create_from_string(site_param["list_item_regex"])
	var url_regex := RegEx.create_from_string(site_param["item_url_regex"])
	var title_regex := RegEx.create_from_string(site_param["item_title_regex"])
	var artist_regex := RegEx.create_from_string(site_param["item_artist_regex"])
		
	var lists := []
	var m := block_regex.search(response)
	if not m:
		return []
	var items := item_regex.search_all(m.get_string(1))
	for i in items:
		var item = (i as RegExMatch).get_string(1)
		m = url_regex.search(item)
		if not m:
			continue
		var item_url := m.get_string(1)
		m = title_regex.search(item)
		if not m:
			continue
		var item_title := m.get_string(1)
		m = artist_regex.search(item)
		if not m:
			continue
		var item_artist := m.get_string(1)
		lists.append(ListData.new(item_url,item_title,item_artist))
	return lists



func get_lyrics(url : String,param : Dictionary) -> String:
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

