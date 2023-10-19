
extends ILyricsFinder

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


var http : HTTPRequest

var finder_result := PackedStringArray()

var NCR : GDScript

func _get_result() -> PackedStringArray:
	return finder_result

func _initialize(script_path : String) -> bool:
	NCR = load(script_path.get_base_dir() + "/named_character_references.gd")
	http = HTTPRequest.new()
	http.set_tls_options(TLSOptions.client())
	return true

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if http:
			if is_instance_valid(http):
				http.free()

func _get_name() -> String:
	return "http_lyrics_site_finder"

func _find(title : String,artists : PackedStringArray,_album : String,
		_file_path : String,_meta : Dictionary) -> Node:
	finder_result = PackedStringArray()
	
	if title.is_empty() or artists.is_empty():
		return null

	if title == "ad" and artists.size() == 1 and artists.has("Spotify"):
		return null

	search_title = title.uri_encode()
	search_artist = artists[0].uri_encode()
	lyrics_block_regex = RegEx.create_from_string(site_param["lyrics_block_regex"])
	lyrics_title_regexes = []
	for r in site_param["lyrics_title_regex"]:
		lyrics_title_regexes.append(RegEx.create_from_string(r))
	lyrics_artist_regex = RegEx.create_from_string(site_param["lyrics_artist_regex"])
	lyrics_lyricist_regex = RegEx.create_from_string(site_param["lyrics_lyricist_regex"])
	lyrics_composer_regex = RegEx.create_from_string(site_param["lyrics_composer_regex"])
	lyrics_arranger_regex = RegEx.create_from_string(site_param["lyrics_arranger_regex"])	
	
	http.tree_entered.connect(start_finding,CONNECT_ONE_SHOT)
	return http


var lyrics_block_regex : RegEx
var search_title : String
var search_artist : String

var lyrics_title_regexes : Array[RegEx]
var lyrics_artist_regex : RegEx
var lyrics_lyricist_regex : RegEx
var lyrics_composer_regex : RegEx
var lyrics_arranger_regex : RegEx


class ListData:
	var url : String
	var title : String
	var artist : String
	
	func _init(u,t,a):
		url = u
		title = t
		artist = a

var list : Array[ListData] # of ListData
var index : int = 0



func start_finding():
	var url_param = site_param["param_format"].replace("{title}",search_title).replace("{artist}",search_artist)
	var headers := PackedStringArray([])

	http.request_completed.connect(get_list_response,CONNECT_ONE_SHOT)
	if http.request(site_param["host"] + url_param,headers,HTTPClient.METHOD_GET) != OK:
		http.request_completed.disconnect(get_list_response)
		finished.emit()
	return

func get_list_response(result : int,response_code : int,
		_headers : PackedStringArray,body : PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		finished.emit()
		return
	var block_regex := RegEx.create_from_string(site_param["list_block_regex"])
	var item_regex := RegEx.create_from_string(site_param["list_item_regex"])
	var url_regex := RegEx.create_from_string(site_param["item_url_regex"])
	var title_regex := RegEx.create_from_string(site_param["item_title_regex"])
	var artist_regex := RegEx.create_from_string(site_param["item_artist_regex"])
	var response := body.get_string_from_utf8()
	list = []
	var m := block_regex.search(response)
	if  m:
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
			list.append(ListData.new(item_url,item_title,item_artist))
	
	if list.is_empty():
		var url = site_param["param_format"].replace("{title}",search_title).replace("{artist}",search_artist)
		OS.shell_open(site_param["host"] + url)
		finished.emit()
		return
	index = 0
	get_lyrics()
	

func get_lyrics():
	if index >= list.size():
		finished.emit()
		return
		
	var headers := PackedStringArray([])
	http.request_completed.connect(get_lyrics_response)
	if http.request(site_param["host"] + list[index].url,headers,HTTPClient.METHOD_GET) != OK:
		http.request_completed.disconnect(get_lyrics_response)
		index += 1
		get_lyrics()


func get_lyrics_response(result : int,response_code : int,
		_headers : PackedStringArray,body : PackedByteArray):
	http.request_completed.disconnect(get_lyrics_response)
	var url : String = site_param["host"] + list[index].url

	index += 1
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		get_lyrics()
		return

	var response := body.get_string_from_utf8()
	if response.is_empty():
		get_lyrics()
		return
	
	var titles : PackedStringArray = []
	for r in lyrics_title_regexes:
		var m := (r as RegEx).search(response)
		if m:
			var t := m.get_string(1)
			if not t.is_empty():
				titles.append(t)
	var title : String = NCR.decode_ncr("\n".join(titles))
	var artist : String
	var m := lyrics_artist_regex.search(response)
	if m:
		artist = NCR.decode_ncr(m.get_string(1))
	var lyricist : String
	m = lyrics_lyricist_regex.search(response)
	if m:
		lyricist = NCR.decode_ncr(m.get_string(1))
	var composer : String
	m = lyrics_composer_regex.search(response)
	if m:
		composer = NCR.decode_ncr(m.get_string(1))
	var arranger : String
	m = lyrics_arranger_regex.search(response)
	if m:
		arranger = NCR.decode_ncr(m.get_string(1))

	m = lyrics_block_regex.search(response)
	if m:
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
		finder_result.append("\n".join(output) + "\n\n" + lyrics)

	OS.shell_open(url)
	get_lyrics()



