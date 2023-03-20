extends I_Receiver

#signal received(data : PlaybackData)

const CREDENTIALS_FILE_PATH := "user://credentials.json"

@onready var spotify : Spotify = $Spotify

@onready var timer = $Timer

@export var polling_sec : float = 30
@export var ad_polling_sec : float = 5


const Controler := preload("res://receiver/spotify/controler.tscn")
const Settings := preload("res://receiver/spotify/settings.tscn")

var controler : Control
var settings : Control
var config : ConfigFile

func _ready():
	timer.timeout.connect(spotify.get_currently_playing_track)
	
	var token : SpotifyAuth.PKCETokenResponse = null
	if FileAccess.file_exists(CREDENTIALS_FILE_PATH):
		var file = FileAccess.open(CREDENTIALS_FILE_PATH,FileAccess.READ)
		if file:
			var json = file.get_as_text()
			token = SpotifyAuth.PKCETokenResponse.deserialize(json)
	$Spotify.login(token)

	controler = Controler.instantiate()
	controler.get_node("%Button").pressed.connect(_on_controler_button_pressed)
	controler.timer = timer
	
	settings = Settings.instantiate()
	settings.get_node("%LineEditAcceptLanguage")\
			.text_changed.connect(_on_settings_line_edit_accept_language_text_changed)
	settings.get_node("%SpinBoxPollingSec")\
			.value_changed.connect(_on_settings_spin_box_polling_sec)
	settings.get_node("%SpinBoxAdPollingSec")\
			.value_changed.connect(_on_settings_spin_box_ad_polling_sec)


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
				set_controler_text(json)
				
				var remain := duration - progress
				if remain > polling_sec:
					remain = polling_sec
				timer.start(remain)
				return
			"episode":
				pass
			"ad":
				var data := PlaybackData.new(false,
						PlaybackData.PlaybackEvent.SEEK_STOP,
						0,tod,"","ad",["Spotify"],"",0,json)
				received.emit(data)
				set_controler_text(json)
				timer.start(ad_polling_sec)
				return
			"unknown":
				pass
		var data := PlaybackData.new(false,
				PlaybackData.PlaybackEvent.SEEK_STOP,
				0,tod,"",json["currently_playing_type"],["Spotify"],"",0,json)
		received.emit(data)
		set_controler_text(json)
	timer.start(polling_sec)



func _get_controler() -> Control:
	return controler

func set_controler_text(json : Dictionary):
	controler.get_node("%TextEdit").text = JSON.stringify(json,"  ",false)
	pass

func _on_controler_button_pressed():
	spotify.get_currently_playing_track()
	timer.stop()


func _get_settings(config_ : ConfigFile) -> Control:
	config = config_
	
	spotify.accept_language = config.get_value("Spotify","accept_language","ja")
	settings.get_node("%LineEditAcceptLanguage").text = spotify.accept_language
	polling_sec = config.get_value("Spotify","polling",30)
	settings.get_node("%SpinBoxPollingSec").value = polling_sec
	ad_polling_sec = config.get_value("Spotify","ad_polling",5)
	settings.get_node("%SpinBoxAdPollingSec").value = ad_polling_sec
	
	return settings

func _on_settings_line_edit_accept_language_text_changed(new_text: String):
	spotify.accept_language = new_text
	config.set_value("Spotify","accept_language",new_text)

func _on_settings_spin_box_polling_sec(value: float):
	polling_sec = value
	config.set_value("Spotify","polling",value)
	
func _on_settings_spin_box_ad_polling_sec(value: float):
	ad_polling_sec = value
	config.set_value("Spotify","ad_polling",value)
