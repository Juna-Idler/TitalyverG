
class_name PlaybackData


enum PlaybackEvent
{
	PLAY_FLAG = 1,
	STOP_FLAG = 2,
	SEEK_FLAG = 4,

	NULL = 0,
	PLAY = 1,
	STOP = 2,

	SEEK = 4,
	SEEK_PLAY = 5,
	SEEK_STOP = 6,
}

var playback_only : bool

var playback_event : PlaybackEvent
var seek_time : float # イベントが発生した時の再生位置
var time_of_day : int # イベントが発生した24時間周期のミリ秒単位の時刻


var file_path : String # おそらく音楽ファイルの多分フルパス
var title : String
var artists : PackedStringArray
var album : String
var duration : float

var meta_data : Dictionary

func _init(po,pe,st,tod,fp = "",t = "",ar = [""],al = "",d = 0.0,md = {}):
	playback_only = po
	playback_event = pe
	seek_time = st
	time_of_day = tod
	file_path = fp
	title = t
	artists = ar
	album = al
	duration = d
	meta_data = md
	
func same_song(other : PlaybackData) -> bool:
	return (file_path == other.file_path and title == other.title and
			artists == other.artists and album == other.album and duration == other.duration)


func serialize() -> String:
	var dic := {
		"event":playback_event,
		"seek":seek_time,
		"time":time_of_day,
		"path":file_path,
		"title":title,
		"artists":artists,
		"album":album,
		"duration":duration,
		"meta":meta_data,
	}
	return JSON.stringify(dic)

static func deserialize(json : String) -> PlaybackData:
	var dic : Dictionary = JSON.parse_string(json)
	if dic.has("path"):
		return PlaybackData.new(false,dic["event"],dic["seek"],dic["time"],
				dic["path"],dic["title"],dic["artists"],dic["album"],dic["duration"],dic["meta"])
	else:
		return PlaybackData.new(true,dic["event"],dic["seek"],dic["time"])
		
