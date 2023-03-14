extends Node

class_name SpotifyAuth

signal got_token(token : PKCETokenResponse)
signal failed(err : String)

class PKCETokenResponse:
	var access_token : String
	var token_type : String
	var scope : String
	var expires_in : int
	var refresh_token : String

	var crated_at : float
	
	func _init(json : Dictionary,time : float = Time.get_unix_time_from_system()):
		access_token = json["access_token"]
		token_type = json["token_type"]
		scope = json["scope"]
		expires_in = json["expires_in"]
		refresh_token = json["refresh_token"]
		crated_at = time
	
	func is_expired() -> bool:
		return crated_at + expires_in <= Time.get_unix_time_from_system()

	func serialize() -> String:
		var json : Dictionary = {
			"access_token" : access_token,
			"token_type" : token_type,
			"scope" : scope,
			"expires_in" : expires_in,
			"refresh_token" : refresh_token,
			"crated_at" : crated_at,
		}
		return JSON.stringify(json)
	
	static func deserialize(json_text : String) -> PKCETokenResponse:
		var json : Dictionary = JSON.parse_string(json_text)
		return PKCETokenResponse.new(json,json["crated_at"])


@export var port_number : int = 5173
@export var client_id : String
@export var scope : PackedStringArray = [
	"user-read-currently-playing",
]

@onready var http : HTTPRequest = $"../HTTPRequest"


var verifier : String
var server : TCPServer = TCPServer.new()

var token : PKCETokenResponse = null

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if server.is_listening():
		_wait_code()


func cancel():
	if server.is_listening():
		server.stop()
	http.cancel_request()

func get_token() -> PKCETokenResponse:
	return token

func authenticate(token_ : PKCETokenResponse = null) -> bool:
	if token_:
		if token_.is_expired():
			return request_refresh_access_token(token_.refresh_token)
		token = token_
		got_token.emit(token)
		return true
	
	token = null
	if client_id.is_empty():
		return false
	verifier = _generate_verifier(128);
	var challenge = _generate_challenge(verifier);

	server.listen(port_number)

	var params : PackedStringArray = [
		"client_id=" + client_id,
		"response_type=" + "code",
		"redirect_uri=" + "http://localhost:%s/callback" % port_number,
		"scope=" + " ".join(scope),
		"code_challenge_method=" + "S256",
		"code_challenge=" + challenge,
	]
	OS.shell_open("https://accounts.spotify.com/authorize?" + "&".join(params))
	print("spotify auth:show dialog on browser")
	return true

func _wait_code():
	if server.is_connection_available():
		print("spotify auth:server connected")
		var peer := server.take_connection()
		peer.poll()
		var _status := peer.get_status()
		var size := peer.get_available_bytes()
		var data := peer.get_data(size)
		if size == 0:
			return # retry next frame
		peer.put_data("HTTP/1.1 200 OK".to_utf8_buffer())

		server.stop()
		
		var _err : int = data[0]
		var bytes := PackedByteArray(data[1])
		var http_head := bytes.get_string_from_utf8()
		
		var end_regex := RegEx.create_from_string("[ &]")
		
		var code_offset := http_head.find("code=")
		if code_offset > 0:
			code_offset += 5
			var end := end_regex.search(http_head,code_offset + 5)
			if end:
				var code := http_head.substr(code_offset,end.get_start() - code_offset)
				print("spotify auth:code received")
				_request_token(code)
				return
			failed.emit("code receive error: ")
			return
		var error_offset := http_head.find("error=")
		if error_offset > 0:
			error_offset += 6
			var end := end_regex.search(http_head,error_offset + 5)
			if end:
				var error := http_head.substr(error_offset,end.get_start() - error_offset)
				failed.emit("code receive error: " + error)
				return
		failed.emit("code receive error: ")


func _request_token(code: String) -> bool:
	var params : PackedStringArray = [
		"client_id=" + client_id,
		"grant_type=" + "authorization_code",
		"code=" + code,
		"redirect_uri=" + "http://localhost:%s/callback" % port_number,
		"code_verifier=" + verifier,
	]
	var headers : PackedStringArray = [
		"Content-Type:application/x-www-form-urlencoded"
	]
	http.request_completed.connect(_on_request_completed)
	var err = http.request("https://accounts.spotify.com/api/token",
			headers,HTTPClient.METHOD_POST,"&".join(params))
	if err != OK:
		http.request_completed.disconnect(_on_request_completed)
		failed.emit("error")
		return false
	print("spotify auth:post request token")
	return true

func _on_request_completed(_result : int,response_code : int,
		_headers : PackedStringArray,body :  PackedByteArray):
	http.request_completed.disconnect(_on_request_completed)
	
	if response_code != 200:
		failed.emit("error")
		return

	var json : Dictionary = JSON.parse_string(body.get_string_from_utf8())
	if json.has("access_token"):
		token = PKCETokenResponse.new(json)
		got_token.emit(token)
	else:
		failed.emit("error")
	print("spotify auth:response received")
	

const _POSSIBLE := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

func _generate_verifier(length : int) -> String:
	var text := ""
	
	for i in length:
		text += _POSSIBLE[randi() % _POSSIBLE.length()]
	return text

func _generate_challenge(v : String) -> String:
	return Marshalls.raw_to_base64(v.sha256_buffer()).replace("+","-").replace("/",'_').replace("=",'')



func request_refresh_access_token(refresh_token : String) -> bool:
	token = null
	var params : PackedStringArray = [
		"client_id=" + client_id,
		"grant_type=" + "refresh_token",
		"refresh_token=" + refresh_token,
	]
	var headers : PackedStringArray = [
		"Content-Type:application/x-www-form-urlencoded"
	]
	http.request_completed.connect(_on_request_refresh_completed)
	var err = http.request("https://accounts.spotify.com/api/token",
			headers,HTTPClient.METHOD_POST,"&".join(params))
	if err != OK:
		http.request_completed.disconnect(_on_request_refresh_completed)
		failed.emit("error refresh")
		return false
	print("spotify auth:post request refresh token")
	return true

func _on_request_refresh_completed(_result : int,response_code : int,
		_headers : PackedStringArray,body :  PackedByteArray):
	http.request_completed.disconnect(_on_request_refresh_completed)
	
	if response_code != 200:
		failed.emit("error refresh")
		return

	var json : Dictionary = JSON.parse_string(body.get_string_from_utf8())
	if json.has("access_token"):
		token = PKCETokenResponse.new(json)
		got_token.emit(token)
	else:
		failed.emit("refresh error")
	print("spotify auth: refresh response received")
	
