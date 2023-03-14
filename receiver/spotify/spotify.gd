extends Node

class_name Spotify


signal finished_login(success : bool)

signal received_response(json : Dictionary)

signal changed_token(token : SpotifyAuth.PKCETokenResponse)


@export var accept_language := "ja"


var access_token : SpotifyAuth.PKCETokenResponse

var requesting : bool = false

var retry : Callable

# Called when the node enters the scene tree for the first time.
func _ready():
	$HTTPRequest.set_tls_options(TLSOptions.client())
	pass # Replace with function body.



func login(token : SpotifyAuth.PKCETokenResponse = null):
	retry = Callable()
	$Auth.process_mode = Node.PROCESS_MODE_ALWAYS
	$Auth.authenticate(token)


func get_currently_playing_track():
	if access_token == null:
		return
	if requesting:
		return
	requesting = true
	var headers := PackedStringArray([
		"Authorization: Bearer " + access_token.access_token,
		"Content-Type:application/json",
		"Accept-Language:" + accept_language,
	])
	$HTTPRequest.request_completed.connect(_on_request_complited_get_currently_playing_track)
	
	$HTTPRequest.request("https://api.spotify.com/v1/me/player/currently-playing",
			headers,HTTPClient.METHOD_GET)
	

func _on_request_complited_get_currently_playing_track(
		_result : int,response_code : int,
		_headers : PackedStringArray,body : PackedByteArray):
	$HTTPRequest.request_completed.disconnect(_on_request_complited_get_currently_playing_track)
	requesting = false

	match response_code:
		200:
			received_response.emit(JSON.parse_string(body.get_string_from_utf8()))
		204: # REFERENCE書いてないけど返してきた　多分 Playback not available or active
 # https://developer.spotify.com/documentation/web-api/reference/#/operations/get-the-users-currently-playing-track
 # https://developer.spotify.com/documentation/web-api/reference/#/operations/get-information-about-the-users-current-playback
			received_response.emit({})
		401: #need refresh
			retry = get_currently_playing_track
			$Auth.request_refresh_access_token(access_token.refresh_token)
		403:
			received_response.emit(JSON.parse_string(body.get_string_from_utf8()))
		429:
			received_response.emit(JSON.parse_string(body.get_string_from_utf8()))


func _on_auth_got_token(token : SpotifyAuth.PKCETokenResponse):
	if access_token != token:
		changed_token.emit(token)
	access_token = token
	if retry.is_valid():
		retry.call()
	else:
		finished_login.emit(true)
		$Auth.process_mode = Node.PROCESS_MODE_DISABLED

func _on_auth_failed(_err : String):
	if access_token != null:
		access_token = null
		changed_token.emit(null)
	finished_login.emit(false)
	$Auth.process_mode = Node.PROCESS_MODE_DISABLED
