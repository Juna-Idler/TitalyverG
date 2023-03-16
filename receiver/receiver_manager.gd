
extends Node

class_name ReceiverManager

signal received(data : PlaybackData)


const RECEIVERS : Dictionary = {
	"WebSocket":preload("res://receiver/websocket_receiver.tscn"),
	"Spotify":preload("res://receiver/spotify_receiver.tscn"),
}

var _receiver : I_Receiver

var _receiver_name : String

func get_current_receiver_name() -> String:
	return _receiver_name

func change_receiver(receiver_name : String) -> bool:
	if not RECEIVERS.has(receiver_name):
		return false
	
	if _receiver:
		remove_child(_receiver)
		_receiver.queue_free()
	
	_receiver = RECEIVERS[receiver_name].instantiate()
	add_child(_receiver)
	_receiver.received.connect(_on_receiver_received)
	_receiver_name = receiver_name
	return true

func _on_receiver_received(data : PlaybackData):
	received.emit(data)

