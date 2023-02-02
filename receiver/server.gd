extends Node

signal received(data : PlaybackData)

@export var port_number = 14738

var server := TCPServer.new()
var socket : WebSocketPeer

# Called when the node enters the scene tree for the first time.
func _ready():

	server.listen(port_number,"127.0.0.1")
	pass # Replace with function body.

func _exit_tree():
	if socket:
		socket.close()
		socket = null
	server.stop()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if socket:
		socket.poll()
		var state := socket.get_ready_state()
		match state:
			WebSocketPeer.STATE_OPEN:
				var count = socket.get_available_packet_count()
				while count > 0:
					var packet = socket.get_packet()
					received.emit(PlaybackData.deserialize(packet.get_string_from_utf8()))
					count = socket.get_available_packet_count()
			WebSocketPeer.STATE_CLOSING:
				pass
			WebSocketPeer.STATE_CLOSED:
				socket = null
				server.listen(port_number,"127.0.0.1")
			WebSocketPeer.STATE_CONNECTING:
				pass
		return
	if server.is_connection_available():
		var peer = server.take_connection()
		socket = WebSocketPeer.new()
		var _err = socket.accept_stream(peer)
# WebSocket接続を確立させたら止めてもいいらしい（そもそも二つ以上は困る）
		server.stop()
	
