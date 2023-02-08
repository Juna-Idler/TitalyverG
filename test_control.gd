extends Control


@export_multiline var input : String


const Http = preload("res://http_request.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	var http = Http.new()
	if http.connect_to_host("https://utaten.com"):
#		var res = http.get_response("/")
#		var res = http.get_response("/search?sort=popular_sort:asc&artist_name=鈴木このみ&title=AVENGE WORLD (Album Ver.)&beginning=&body=&lyricist=&composer=&sub_title=&tag=&form_open=1&show_artists=1")
		var res = http.get_response("/search?sort=popular_sort%3Aasc&artist_name=%E9%88%B4%E6%9C%A8%E3%81%93%E3%81%AE%E3%81%BF&title=AVENGE%20WORLD%20%28Album%20Ver.%29&beginning=&body=&lyricist=&composer=&sub_title=&tag=&form_open=1&show_artists=1")
		print(res)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
