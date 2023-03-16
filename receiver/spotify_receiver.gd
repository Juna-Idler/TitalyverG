extends I_Receiver

#signal received(data : PlaybackData)

const CREDENTIALS_FILE_PATH := "user://credentials.json"

@onready var spotify : Spotify = $Spotify

const POLLING_SEC := 30

func _ready():
	var token : SpotifyAuth.PKCETokenResponse = null
	if FileAccess.file_exists(CREDENTIALS_FILE_PATH):
		var file = FileAccess.open(CREDENTIALS_FILE_PATH,FileAccess.READ)
		if file:
			var json = file.get_as_text()
			token = SpotifyAuth.PKCETokenResponse.deserialize(json)
	$Spotify.login(token)



func _on_spotify_changed_token(token : SpotifyAuth.PKCETokenResponse):
	if not token:
		DirAccess.remove_absolute(CREDENTIALS_FILE_PATH)
		return
	var dir = CREDENTIALS_FILE_PATH.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)

	var file = FileAccess.open(CREDENTIALS_FILE_PATH,FileAccess.WRITE)
	if file:
		file.store_string(token.serialize())
		


func _on_spotify_finished_login(success):
	if success:
		spotify.get_currently_playing_track()
	pass # Replace with function body.


var last_timestamp : int

func _on_spotify_received_response(json : Dictionary):

	if not json.is_empty():
		
 # timestampが「最後に操作をした時間」を表すみたい？
		var timestamp := int(json["timestamp"])
		var seeked = timestamp != last_timestamp
		last_timestamp = timestamp
#		var tod := int(json["timestamp"]) % (24*60*60*1000)
		var tod := int(Time.get_unix_time_from_system() * 1000) % (24*60*60*1000)
		
		match json["currently_playing_type"]:
			"track":
				var title : String = json["item"]["name"]
				var artists : PackedStringArray = json["item"]["artists"].map(func(v) : return v["name"])
				var album : String = json["item"]["album"]["name"]
				
				var is_playing : bool = json["is_playing"]
				var progress : float = json["progress_ms"] / 1000.0
				
				var duration : float = json["item"]["duration_ms"] / 1000.0
				var event := (
						(PlaybackData.PlaybackEvent.SEEK_FLAG if seeked else PlaybackData.PlaybackEvent.NULL) |
						(PlaybackData.PlaybackEvent.PLAY_FLAG if is_playing else PlaybackData.PlaybackEvent.STOP_FLAG)
				) as PlaybackData.PlaybackEvent
				var data := PlaybackData.new(false,
						event,
						progress,tod,"",title,artists,album,duration,json)
				received.emit(data)
				
				var remain := duration - progress
				if remain > POLLING_SEC:
					remain = POLLING_SEC
				get_tree().create_timer(remain)\
						.timeout.connect(spotify.get_currently_playing_track)
				return
			"episode":
				pass
			"ad":
				var data := PlaybackData.new(false,
						PlaybackData.PlaybackEvent.SEEK_STOP,
						0,tod,"","ad",["Spotify"],"",0,json)
				received.emit(data)
				get_tree().create_timer(5)\
						.timeout.connect(spotify.get_currently_playing_track)
				return
			"unknown":
				pass
		var data := PlaybackData.new(false,
				PlaybackData.PlaybackEvent.SEEK_STOP,
				0,tod,"",json["currently_playing_type"],["Spotify"],"",0,json)
		received.emit(data)
	get_tree().create_timer(POLLING_SEC)\
			.timeout.connect(spotify.get_currently_playing_track)

